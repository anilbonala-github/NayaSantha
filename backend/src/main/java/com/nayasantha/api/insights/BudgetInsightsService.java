package com.nayasantha.api.insights;

import com.nayasantha.api.catalogue.Category;
import com.nayasantha.api.catalogue.CategoryRepository;
import com.nayasantha.api.catalogue.Product;
import com.nayasantha.api.catalogue.ProductRepository;
import com.nayasantha.api.household.Household;
import com.nayasantha.api.household.HouseholdRepository;
import com.nayasantha.api.insights.InsightsDtos.*;
import com.nayasantha.api.order.Order;
import com.nayasantha.api.order.OrderItem;
import com.nayasantha.api.order.OrderService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.*;

/** Spend analytics from the customer's order history (budget insights). */
@Service
public class BudgetInsightsService {

    private static final DateTimeFormatter DAY =
            DateTimeFormatter.ofPattern("dd/MM").withZone(ZoneId.of("Asia/Kolkata"));

    private final OrderService orders;
    private final HouseholdRepository households;
    private final ProductRepository products;
    private final CategoryRepository categories;

    public BudgetInsightsService(OrderService orders, HouseholdRepository households,
                                 ProductRepository products, CategoryRepository categories) {
        this.orders = orders;
        this.households = households;
        this.products = products;
        this.categories = categories;
    }

    @Transactional(readOnly = true)
    public BudgetInsightsDto forUser(UUID userId) {
        BigDecimal budget = households.findByOwnerUserId(userId)
                .map(Household::getWeeklyBudget).orElse(BigDecimal.ZERO);

        List<Order> all = orders.ordersOfUser(userId);                     // newest first
        List<Order> settled = all.stream().filter(o -> o.getFinalTotal() != null).toList();
        int n = settled.size();

        BigDecimal total = settled.stream().map(Order::getFinalTotal).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal avg = n == 0 ? BigDecimal.ZERO : total.divide(BigDecimal.valueOf(n), 2, RoundingMode.HALF_UP);
        BigDecimal last = settled.isEmpty() ? BigDecimal.ZERO : settled.get(0).getFinalTotal();
        BigDecimal saved = settled.stream()
                .map(o -> o.getEstimatedTotal().subtract(o.getFinalTotal()).max(BigDecimal.ZERO))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        long withinBudget = budget.signum() > 0
                ? settled.stream().filter(o -> o.getFinalTotal().compareTo(budget) <= 0).count() : 0;
        double withinRate = (budget.signum() > 0 && n > 0) ? (double) withinBudget / n : 0;

        // Recent trend: up to 8 most-recent settled orders, oldest -> newest.
        List<Order> recent = new ArrayList<>(settled.subList(0, Math.min(8, n)));
        Collections.reverse(recent);
        List<PointDto> recentSpend = recent.stream()
                .map(o -> new PointDto(DAY.format(o.getCreatedAt()), o.getFinalTotal())).toList();

        // Category breakdown across settled orders' items.
        Map<UUID, String> categoryName = new HashMap<>();
        for (Category c : categories.findAll()) categoryName.put(c.getId(), c.getName());
        Map<UUID, UUID> productCategory = new HashMap<>();
        for (Product p : products.findAll()) productCategory.put(p.getId(), p.getCategoryId());

        Map<String, BigDecimal> byCategory = new HashMap<>();
        for (Order o : settled) {
            for (OrderItem it : orders.itemsOf(o.getId())) {
                BigDecimal amt = it.getFinalAmount() != null ? it.getFinalAmount() : it.getEstimatedAmount();
                if (amt == null || amt.signum() <= 0) continue;
                String cat = categoryName.getOrDefault(productCategory.get(it.getProductId()), "Other");
                byCategory.merge(cat, amt, BigDecimal::add);
            }
        }
        List<CategorySpendDto> categorySpend = byCategory.entrySet().stream()
                .map(e -> new CategorySpendDto(e.getKey(), e.getValue()))
                .sorted((a, b) -> b.amount().compareTo(a.amount()))
                .toList();

        return new BudgetInsightsDto(budget, n, avg, last, saved, withinRate, recentSpend, categorySpend);
    }
}
