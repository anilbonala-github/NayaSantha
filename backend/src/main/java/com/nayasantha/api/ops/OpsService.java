package com.nayasantha.api.ops;

import com.nayasantha.api.order.Order;
import com.nayasantha.api.order.OrderDtos.OrderDto;
import com.nayasantha.api.order.OrderItem;
import com.nayasantha.api.order.OrderService;
import com.nayasantha.api.ops.OpsDtos.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.TemporalAdjusters;
import java.util.*;

/**
 * Vol3 operations portal: consolidate the week's locked orders into a single buy
 * list, capture the real Sunday market rates, then finalize every order against
 * those rates. Money math stays server-owned (Vol2A §20); ops only supplies rates.
 */
@Service
public class OpsService {

    /** Default procurement buffer % added to confirmed demand (Vol2A FR-007). */
    private static final int BUFFER_PERCENT = 5;

    private final OrderService orderService;
    private final MarketPriceRepository prices;

    public OpsService(OrderService orderService, MarketPriceRepository prices) {
        this.orderService = orderService;
        this.prices = prices;
    }

    /** Monday of the current (UTC) delivery week — the market_prices partition key. */
    static LocalDate currentWeekStart() {
        return LocalDate.now(ZoneOffset.UTC).with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
    }

    @Transactional(readOnly = true)
    public OpsSummaryDto summary() {
        LocalDate week = currentWeekStart();
        List<Order> locked = orderService.ordersByStatus(Order.Status.LOCKED);

        long households = locked.stream().map(Order::getUserId).distinct().count();
        BigDecimal totalEst = locked.stream().map(Order::getEstimatedTotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalMax = locked.stream().map(Order::getMaximumPayable)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Set<UUID> productIds = new HashSet<>();
        for (Order o : locked) {
            for (OrderItem i : orderService.itemsOf(o.getId())) productIds.add(i.getProductId());
        }
        long captured = prices.findByWeekStart(week).stream()
                .map(MarketPrice::getProductId).filter(productIds::contains).distinct().count();
        int distinct = productIds.size();
        return new OpsSummaryDto(week, locked.size(), households, totalEst, totalMax,
                distinct, (int) captured, distinct - (int) captured);
    }

    @Transactional(readOnly = true)
    public List<PurchaseLineDto> purchaseList() {
        LocalDate week = currentWeekStart();
        Map<UUID, BigDecimal> capturedRate = new HashMap<>();
        for (MarketPrice mp : prices.findByWeekStart(week)) capturedRate.put(mp.getProductId(), mp.getActualRate());

        Map<UUID, Agg> byProduct = new LinkedHashMap<>();
        for (Order o : orderService.ordersByStatus(Order.Status.LOCKED)) {
            for (OrderItem i : orderService.itemsOf(o.getId())) {
                Agg a = byProduct.computeIfAbsent(i.getProductId(),
                        k -> new Agg(i.getName(), i.getUnit()));
                a.quantity += i.getQuantity();
                a.estimated = a.estimated.add(i.getEstimatedAmount());
            }
        }

        List<PurchaseLineDto> out = new ArrayList<>(byProduct.size());
        byProduct.forEach((productId, a) -> {
            BigDecimal forecast = a.quantity == 0 ? BigDecimal.ZERO
                    : a.estimated.divide(BigDecimal.valueOf(a.quantity), 2, RoundingMode.HALF_UP);
            int buyQty = (int) Math.ceil(a.quantity * (1 + BUFFER_PERCENT / 100.0));
            BigDecimal maxRate = forecast.multiply(BigDecimal.valueOf(1.025)).setScale(2, RoundingMode.CEILING);
            out.add(new PurchaseLineDto(productId, a.name, a.unit, a.quantity,
                    BUFFER_PERCENT, buyQty, forecast, maxRate,
                    capturedRate.get(productId), a.estimated));
        });
        out.sort(Comparator.comparing(PurchaseLineDto::name, String.CASE_INSENSITIVE_ORDER));
        return out;
    }

    /** Order-cutoff console: status counts + the exceptions queue (Vol2A §7.1). */
    @Transactional(readOnly = true)
    public CutoffDto cutoff() {
        List<Order> awaiting = orderService.ordersByStatus(Order.Status.AWAITING_APPROVAL);
        List<CutoffExceptionDto> exceptions = new ArrayList<>();
        for (Order o : awaiting) {
            String ref = "NS-" + o.getId().toString().substring(0, 8);
            String detail = o.getFinalTotal() != null
                    ? String.format("Final ₹%s exceeds cap ₹%s", o.getFinalTotal(), o.getMaximumPayable())
                    : "Basket exceeds customer maximum";
            exceptions.add(new CutoffExceptionDto(ref, detail, "OVER_CAP"));
        }
        return new CutoffDto(
                currentWeekStart(),
                orderService.ordersByStatus(Order.Status.LOCKED).size(),
                orderService.ordersByStatus(Order.Status.CONFIRMED).size(),
                awaiting.size(),
                orderService.ordersByStatus(Order.Status.CANCELLED).size(),
                exceptions);
    }

    @Transactional
    public CaptureResultDto capturePrices(UUID adminId, CapturePricesRequest req) {
        LocalDate week = req.weekStart() != null ? req.weekStart() : currentWeekStart();
        int n = 0;
        for (PriceEntry e : req.prices()) {
            MarketPrice mp = prices.findByProductIdAndWeekStart(e.productId(), week)
                    .orElseGet(MarketPrice::new);
            mp.setProductId(e.productId());
            mp.setWeekStart(week);
            mp.setActualRate(e.actualRate());
            mp.setCapturedBy(adminId);
            mp.setCapturedAt(Instant.now());
            mp.setUpdatedAt(Instant.now());
            prices.save(mp);
            n++;
        }
        return new CaptureResultDto(week, n);
    }

    @Transactional
    public FinalizeResultDto finalizeWeek(LocalDate weekArg) {
        LocalDate week = weekArg != null ? weekArg : currentWeekStart();
        Map<UUID, BigDecimal> rates = new HashMap<>();
        for (MarketPrice mp : prices.findByWeekStart(week)) rates.put(mp.getProductId(), mp.getActualRate());

        List<Order> locked = orderService.ordersByStatus(Order.Status.LOCKED);
        int finalized = 0, awaiting = 0;
        BigDecimal total = BigDecimal.ZERO;
        for (Order o : locked) {
            OrderDto dto = orderService.settleWithCapturedRates(o.getId(), rates);
            if ("FINALIZED".equals(dto.status())) {
                finalized++;
                if (dto.finalTotal() != null) total = total.add(dto.finalTotal());
            } else if ("AWAITING_APPROVAL".equals(dto.status())) {
                awaiting++;
            }
        }
        return new FinalizeResultDto(week, locked.size(), finalized, awaiting, total);
    }

    // --- fulfillment: packing + delivery ----------------------------------------
    private static FulfillmentOrderDto fo(Order o) {
        return new FulfillmentOrderDto(o.getId(), "NS-" + o.getId().toString().substring(0, 8),
                o.getCommunity() == null ? "Unassigned" : o.getCommunity(),
                o.getDeliverySlot(), o.getFulfillmentStage().name(), o.getFinalTotal());
    }

    @Transactional(readOnly = true)
    public PackingDto packing() {
        List<Order> paid = orderService.ordersByStatus(Order.Status.PAID);
        int pending = 0, packing = 0, packed = 0;
        Map<String, List<Order>> byCommunity = new LinkedHashMap<>();
        for (Order o : paid) {
            switch (o.getFulfillmentStage()) {
                case PENDING -> pending++;
                case PACKING -> packing++;
                default -> packed++;   // PACKED / OUT_FOR_DELIVERY
            }
            byCommunity.computeIfAbsent(o.getCommunity() == null ? "Unassigned" : o.getCommunity(),
                    k -> new ArrayList<>()).add(o);
        }
        List<PackingWaveDto> waves = new ArrayList<>();
        byCommunity.forEach((community, os) -> {
            int packedCount = (int) os.stream()
                    .filter(o -> o.getFulfillmentStage() != Order.FulfillmentStage.PENDING
                            && o.getFulfillmentStage() != Order.FulfillmentStage.PACKING).count();
            waves.add(new PackingWaveDto(community, os.size(), packedCount,
                    os.stream().map(OpsService::fo).toList()));
        });
        waves.sort(Comparator.comparing(PackingWaveDto::community, String.CASE_INSENSITIVE_ORDER));
        return new PackingDto(paid.size(), pending, packing, packed, waves);
    }

    @Transactional(readOnly = true)
    public DeliveryDto delivery() {
        List<Order> paid = orderService.ordersByStatus(Order.Status.PAID);
        int ready = 0, out = 0;
        List<FulfillmentOrderDto> actionable = new ArrayList<>();
        for (Order o : paid) {
            if (o.getFulfillmentStage() == Order.FulfillmentStage.PACKED) { ready++; actionable.add(fo(o)); }
            else if (o.getFulfillmentStage() == Order.FulfillmentStage.OUT_FOR_DELIVERY) { out++; actionable.add(fo(o)); }
        }
        int delivered = orderService.ordersByStatus(Order.Status.DELIVERED).size();
        return new DeliveryDto(ready, out, delivered, actionable);
    }

    @Transactional
    public String pack(java.util.UUID orderId) {
        return orderService.packOrder(orderId).getFulfillmentStage().name();
    }

    @Transactional
    public String dispatch(java.util.UUID orderId) {
        return orderService.dispatchOrder(orderId).getFulfillmentStage().name();
    }

    @Transactional
    public String deliver(java.util.UUID orderId) {
        return orderService.deliverOrder(orderId).getFulfillmentStage().name();
    }

    /** Mutable per-product accumulator for the consolidated buy list. */
    private static final class Agg {
        final String name;
        final String unit;
        int quantity = 0;
        BigDecimal estimated = BigDecimal.ZERO;
        Agg(String name, String unit) { this.name = name; this.unit = unit; }
    }
}
