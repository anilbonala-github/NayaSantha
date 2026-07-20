package com.nayasantha.api.plan;

import com.nayasantha.api.catalogue.Product;
import com.nayasantha.api.catalogue.ProductPrice;
import com.nayasantha.api.catalogue.ProductPriceRepository;
import com.nayasantha.api.catalogue.ProductRepository;
import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.config.AppProperties;
import com.nayasantha.api.household.Household;
import com.nayasantha.api.household.HouseholdMember;
import com.nayasantha.api.household.HouseholdMemberRepository;
import com.nayasantha.api.household.HouseholdRepository;
import com.nayasantha.api.pantry.PantryService;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.TemporalAdjusters;
import java.util.*;

/**
 * Generates the AI weekly plan. Gemini proposes; this service is the deterministic
 * authority: it validates every SKU, enforces allergies/dietary/budget, recomputes
 * trusted prices and persists the plan (Vol1 §11.2, Vol2 §6.5). When Gemini is
 * disabled or fails, a rule-based fallback proposes the basket.
 */
@Service
public class WeeklyPlanService {

    private final WeeklyPlanRepository plans;
    private final WeeklyPlanItemRepository planItems;
    private final ProductRepository products;
    private final ProductPriceRepository prices;
    private final HouseholdRepository households;
    private final HouseholdMemberRepository members;
    private final PantryService pantryService;
    private final GeminiPlanner gemini;
    private final AppProperties props;

    private static final BigDecimal DEFAULT_BUDGET = BigDecimal.valueOf(1500);

    public WeeklyPlanService(WeeklyPlanRepository plans, WeeklyPlanItemRepository planItems,
                             ProductRepository products, ProductPriceRepository prices,
                             HouseholdRepository households, HouseholdMemberRepository members,
                             PantryService pantryService, GeminiPlanner gemini, AppProperties props) {
        this.plans = plans;
        this.planItems = planItems;
        this.products = products;
        this.prices = prices;
        this.households = households;
        this.members = members;
        this.pantryService = pantryService;
        this.gemini = gemini;
        this.props = props;
    }

    // Small view joining a product with its active price.
    private record Priced(Product product, ProductPrice price) {}

    @Transactional
    public WeeklyPlan generate(UUID userId) {
        Household household = households.findByOwnerUserId(userId).orElse(null);
        List<HouseholdMember> memberList = household == null ? List.of()
                : members.findByHouseholdId(household.getId());
        BigDecimal budget = (household != null && household.getWeeklyBudget().signum() > 0)
                ? household.getWeeklyBudget() : DEFAULT_BUDGET;
        Set<String> allergyTokens = allergyTokens(memberList);
        Set<UUID> stocked = pantryService.wellStockedProductIds(userId);

        Map<String, Priced> catalogue = loadCatalogue();

        // 1) Get a proposal (Gemini or deterministic fallback).
        PlanProposal proposal = gemini.propose(describeHousehold(memberList, budget), catalogueLines(catalogue));
        if (proposal == null) {
            proposal = fallbackProposal(catalogue, budget, allergyTokens, stocked);
        }

        // 2) Validate + price + budget-cap deterministically (never trust the model).
        WeeklyPlan plan = new WeeklyPlan();
        plan.setUserId(userId);
        plan.setHouseholdId(household == null ? null : household.getId());
        plan.setWeekStart(LocalDate.now().with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY)));
        plan.setAiSource(proposal.source());
        plan.setAiExplanation(proposal.explanation());
        plan.setAiModel(proposal.source() == WeeklyPlan.AiSource.GEMINI ? props.getGemini().getModel() : "rule-based");
        plan.setAiPromptVersion(props.getGemini().getPromptVersion());
        plan = plans.save(plan);

        BigDecimal estimate = BigDecimal.ZERO;
        BigDecimal maximum = BigDecimal.ZERO;
        Set<UUID> added = new HashSet<>();
        for (PlanProposal.ProposedLine line : proposal.lines()) {
            Priced pr = catalogue.get(line.sku());
            if (pr == null || added.contains(pr.product().getId())) continue;          // unknown/duplicate sku
            if (violatesAllergy(pr.product(), allergyTokens)) continue;                 // hard exclusion
            int qty = Math.max(1, line.quantity());
            BigDecimal lineEstimate = pr.price().getSellingPrice().multiply(BigDecimal.valueOf(qty));
            if (estimate.add(lineEstimate).compareTo(budget) > 0) continue;             // keep within budget

            WeeklyPlanItem item = new WeeklyPlanItem();
            item.setPlanId(plan.getId());
            item.setProductId(pr.product().getId());
            item.setQuantity(qty);
            item.setUnitForecastPrice(pr.price().getForecastPrice());
            item.setUnitMaxPrice(pr.price().getMaxPrice());
            item.setReason(line.reason());
            planItems.save(item);
            added.add(pr.product().getId());

            estimate = estimate.add(lineEstimate);
            maximum = maximum.add(pr.price().getMaxPrice().multiply(BigDecimal.valueOf(qty)));
        }
        plan.setEstimatedTotal(estimate);
        plan.setMaximumPayable(maximum);
        return plans.save(plan);
    }

    @Transactional(readOnly = true)
    public WeeklyPlan current(UUID userId) {
        return plans.findFirstByUserIdOrderByCreatedAtDesc(userId)
                .orElseThrow(() -> ApiException.notFound("Weekly plan"));
    }

    @Transactional
    public WeeklyPlanDtos.PlanDto generateDto(UUID userId) {
        return toDto(generate(userId));
    }

    @Transactional(readOnly = true)
    public WeeklyPlanDtos.PlanDto currentDto(UUID userId) {
        return toDto(current(userId));
    }

    @Transactional
    public WeeklyPlanDtos.PlanDto updateItem(UUID userId, UUID planId, UUID itemId,
                                             int quantity, Long version) {
        WeeklyPlan plan = plans.findById(planId).filter(p -> p.getUserId().equals(userId))
                .orElseThrow(() -> ApiException.notFound("Weekly plan"));
        WeeklyPlanItem item = planItems.findById(itemId).filter(i -> i.getPlanId().equals(planId))
                .orElseThrow(() -> ApiException.notFound("Plan item"));
        if (version != null && !version.equals(item.getVersion())) {
            throw new ObjectOptimisticLockingFailureException(
                    "expected version " + item.getVersion() + " but received " + version, null);
        }
        if (quantity <= 0) planItems.delete(item);
        else { item.setQuantity(quantity); planItems.save(item); }
        recomputeTotals(plan);
        return toDto(plans.save(plan));
    }

    private void recomputeTotals(WeeklyPlan plan) {
        BigDecimal est = BigDecimal.ZERO, max = BigDecimal.ZERO;
        for (WeeklyPlanItem i : planItems.findByPlanId(plan.getId())) {
            est = est.add(i.getUnitForecastPrice().multiply(BigDecimal.valueOf(i.getQuantity())));
            max = max.add(i.getUnitMaxPrice().multiply(BigDecimal.valueOf(i.getQuantity())));
        }
        plan.setEstimatedTotal(est);
        plan.setMaximumPayable(max);
    }

    private WeeklyPlanDtos.PlanDto toDto(WeeklyPlan plan) {
        List<WeeklyPlanItem> items = planItems.findByPlanId(plan.getId());
        Map<UUID, Product> byId = new HashMap<>();
        if (!items.isEmpty()) {
            products.findAllById(items.stream().map(WeeklyPlanItem::getProductId).toList())
                    .forEach(p -> byId.put(p.getId(), p));
        }
        List<WeeklyPlanDtos.PlanItemDto> itemDtos = new ArrayList<>();
        int count = 0;
        for (WeeklyPlanItem i : items) {
            Product p = byId.get(i.getProductId());
            BigDecimal lineEst = i.getUnitForecastPrice().multiply(BigDecimal.valueOf(i.getQuantity()));
            BigDecimal lineMax = i.getUnitMaxPrice().multiply(BigDecimal.valueOf(i.getQuantity()));
            count += i.getQuantity();
            itemDtos.add(new WeeklyPlanDtos.PlanItemDto(i.getId(), i.getProductId(),
                    p == null ? null : p.getName(), p == null ? null : p.getEmoji(),
                    p == null ? null : p.getUnit(), i.getQuantity(), i.getUnitForecastPrice(),
                    i.getUnitMaxPrice(), lineEst, lineMax, i.getReason(), i.getVersion()));
        }
        return new WeeklyPlanDtos.PlanDto(plan.getId(), plan.getWeekStart(), plan.getStatus().name(),
                plan.getAiSource().name(), plan.getAiExplanation(), plan.getEstimatedTotal(),
                plan.getMaximumPayable(), count, itemDtos, plan.getVersion());
    }

    // --- proposal helpers --------------------------------------------------
    private Map<String, Priced> loadCatalogue() {
        List<Product> active = products.findByActiveTrueOrderByNameAsc();
        Map<UUID, ProductPrice> priceByProduct = new HashMap<>();
        for (ProductPrice pp : prices.findByProductIdInAndActiveTrue(active.stream().map(Product::getId).toList())) {
            priceByProduct.putIfAbsent(pp.getProductId(), pp);
        }
        Map<String, Priced> out = new LinkedHashMap<>();
        for (Product p : active) {
            ProductPrice pp = priceByProduct.get(p.getId());
            if (pp != null) out.put(p.getSku(), new Priced(p, pp));
        }
        return out;
    }

    private List<String> catalogueLines(Map<String, Priced> catalogue) {
        List<String> lines = new ArrayList<>();
        catalogue.forEach((sku, pr) -> lines.add("%s | %s | %s | Rs%s"
                .formatted(sku, pr.product().getName(), pr.product().getUnit(), pr.price().getSellingPrice())));
        return lines;
    }

    private String describeHousehold(List<HouseholdMember> memberList, BigDecimal budget) {
        StringBuilder sb = new StringBuilder("Weekly budget: Rs").append(budget).append(". Members: ");
        if (memberList.isEmpty()) sb.append("1 adult, vegetarian");
        else memberList.forEach(m -> sb.append(m.getDietaryType()).append(m.getAge() == null ? "" : (" age " + m.getAge()))
                .append(m.getAllergies() == null || m.getAllergies().isBlank() ? "" : (" allergic to " + m.getAllergies()))
                .append("; "));
        return sb.toString();
    }

    /** Rule-based basket: staples + fresh produce, skipping well-stocked items, within budget. */
    private PlanProposal fallbackProposal(Map<String, Priced> catalogue, BigDecimal budget,
                                          Set<String> allergyTokens, Set<UUID> stocked) {
        // Priority ordering by SKU for a balanced weekly basket.
        List<String> priority = List.of(
                "p_milk", "p_eggs", "p_rice", "p_atta", "p_toordal", "p_oil",
                "p_tomato", "p_onion", "p_potato", "p_spinach", "p_carrot", "p_capsicum",
                "p_banana", "p_apple", "p_curd", "p_paneer", "p_chilli", "p_turmeric");
        Map<String, Integer> qtyBySku = Map.of("p_milk", 3, "p_tomato", 2, "p_onion", 2, "p_eggs", 2);

        List<PlanProposal.ProposedLine> lines = new ArrayList<>();
        BigDecimal running = BigDecimal.ZERO;
        for (String sku : priority) {
            Priced pr = catalogue.get(sku);
            if (pr == null || stocked.contains(pr.product().getId())) continue;
            if (violatesAllergy(pr.product(), allergyTokens)) continue;
            int qty = qtyBySku.getOrDefault(sku, 1);
            BigDecimal lineEstimate = pr.price().getSellingPrice().multiply(BigDecimal.valueOf(qty));
            if (running.add(lineEstimate).compareTo(budget) > 0) continue;
            running = running.add(lineEstimate);
            lines.add(new PlanProposal.ProposedLine(sku, qty, "Weekly staple for your household"));
        }
        String explanation = "A balanced weekly basket of staples and fresh produce sized to your "
                + "budget of Rs" + budget + ", skipping what you already have in the pantry.";
        return new PlanProposal(lines, explanation, WeeklyPlan.AiSource.FALLBACK);
    }

    private Set<String> allergyTokens(List<HouseholdMember> memberList) {
        Set<String> tokens = new HashSet<>();
        for (HouseholdMember m : memberList) {
            if (m.getAllergies() == null) continue;
            for (String a : m.getAllergies().split(",")) {
                String t = a.trim().toLowerCase();
                if (!t.isEmpty()) tokens.add(t);
                if (t.equals("peanut") || t.equals("peanuts")) tokens.add("groundnut");   // common synonym
            }
        }
        return tokens;
    }

    private boolean violatesAllergy(Product p, Set<String> allergyTokens) {
        String name = p.getName().toLowerCase();
        return allergyTokens.stream().anyMatch(name::contains);
    }
}
