package com.nayasantha.api.plan;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nayasantha.api.config.AppProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Calls Google Gemini to *propose* a weekly plan (Vol2 §10). Returns null when
 * disabled or on any error, so the service falls back deterministically. Gemini
 * output is never trusted directly — the service validates it.
 */
@Component
public class GeminiPlanner {

    private static final Logger log = LoggerFactory.getLogger(GeminiPlanner.class);
    private static final String BASE = "https://generativelanguage.googleapis.com/v1beta/models/";

    private final AppProperties props;
    private final ObjectMapper mapper;
    private final RestClient http = RestClient.create();

    public GeminiPlanner(AppProperties props, ObjectMapper mapper) {
        this.props = props;
        this.mapper = mapper;
    }

    public boolean isEnabled() { return props.getGemini().isEnabled(); }

    /** Diagnostic: makes a tiny call and reports the exact status/error (no key exposed). */
    public Map<String, Object> selfTest() {
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("enabled", isEnabled());
        out.put("model", props.getGemini().getModel());
        if (!isEnabled()) {
            out.put("ok", false);
            out.put("error", "GEMINI_API_KEY not set");
            return out;
        }
        try {
            Map<String, Object> body = Map.of("contents",
                    List.of(Map.of("parts", List.of(Map.of("text", "Reply with the single word: ok")))));
            String url = BASE + props.getGemini().getModel() + ":generateContent?key=" + props.getGemini().getApiKey();
            JsonNode res = http.post().uri(url).body(body).retrieve().body(JsonNode.class);
            out.put("ok", true);
            out.put("reply", res.path("candidates").path(0).path("content").path("parts").path(0)
                    .path("text").asText(""));
        } catch (RestClientResponseException e) {
            out.put("ok", false);
            out.put("status", e.getStatusCode().value());
            String b = e.getResponseBodyAsString();
            out.put("error", b.length() > 600 ? b.substring(0, 600) : b);
        } catch (Exception e) {
            out.put("ok", false);
            out.put("error", e.getClass().getSimpleName() + ": " + e.getMessage());
        }
        return out;
    }

    /** @param context sanitized household description; @param catalogue "sku | name | unit | Rs price" lines. */
    public PlanProposal propose(String context, List<String> catalogue) {
        if (!isEnabled()) return null;
        try {
            String prompt = buildPrompt(context, catalogue);
            Map<String, Object> body = Map.of(
                    "contents", List.of(Map.of("parts", List.of(Map.of("text", prompt)))),
                    "generationConfig", Map.of("responseMimeType", "application/json", "temperature", 0.4));

            String url = BASE + props.getGemini().getModel() + ":generateContent?key=" + props.getGemini().getApiKey();
            JsonNode res = http.post().uri(url).body(body).retrieve().body(JsonNode.class);

            String text = res.path("candidates").path(0).path("content").path("parts").path(0)
                    .path("text").asText("");
            JsonNode json = mapper.readTree(text);

            List<PlanProposal.ProposedLine> lines = new ArrayList<>();
            for (JsonNode n : json.path("lines")) {
                String sku = n.path("sku").asText(null);
                int qty = n.path("quantity").asInt(0);
                if (sku != null && qty > 0) {
                    lines.add(new PlanProposal.ProposedLine(sku, qty, n.path("reason").asText("")));
                }
            }
            if (lines.isEmpty()) return null;
            return new PlanProposal(lines, json.path("explanation").asText(""), WeeklyPlan.AiSource.GEMINI);
        } catch (Exception e) {
            log.warn("Gemini plan generation failed, using fallback: {}", e.getMessage());
            return null;
        }
    }

    private String buildPrompt(String context, List<String> catalogue) {
        return """
            You are the meal-planning assistant for NayaSantha, a weekly grocery service.
            Propose a one-week grocery basket for this household, staying within budget.
            Only choose products from the catalogue below (use the exact sku). Respect all
            dietary rules and allergies strictly. Prefer staples and fresh produce; keep
            quantities whole numbers.

            HOUSEHOLD:
            %s

            CATALOGUE (sku | name | unit | price):
            %s

            Return ONLY JSON:
            {"explanation":"one short paragraph","lines":[{"sku":"...","quantity":1,"reason":"short"}]}
            """.formatted(context, String.join("\n", catalogue));
    }
}
