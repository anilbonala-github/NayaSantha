package com.nayasantha.api.plan;

import java.util.List;

/**
 * A *proposed* plan from the AI (or fallback). This is untrusted input:
 * WeeklyPlanService validates every SKU, dietary/allergy rule, quantity and
 * budget, and recomputes prices before it becomes a real plan (Vol1 §11.2).
 */
public record PlanProposal(List<ProposedLine> lines, String explanation,
                           WeeklyPlan.AiSource source) {

    /** One recommended line as the model returned it — sku is not yet verified. */
    public record ProposedLine(String sku, int quantity, String reason) {}
}
