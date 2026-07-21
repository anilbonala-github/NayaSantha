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
            out.add(new PurchaseLineDto(productId, a.name, a.unit, a.quantity,
                    forecast, capturedRate.get(productId), a.estimated));
        });
        out.sort(Comparator.comparing(PurchaseLineDto::name, String.CASE_INSENSITIVE_ORDER));
        return out;
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

    /** Mutable per-product accumulator for the consolidated buy list. */
    private static final class Agg {
        final String name;
        final String unit;
        int quantity = 0;
        BigDecimal estimated = BigDecimal.ZERO;
        Agg(String name, String unit) { this.name = name; this.unit = unit; }
    }
}
