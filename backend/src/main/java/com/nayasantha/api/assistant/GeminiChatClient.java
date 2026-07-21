package com.nayasantha.api.assistant;

import com.fasterxml.jackson.databind.JsonNode;
import com.nayasantha.api.config.AppProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** Multi-turn Gemini chat for the assistant (Vol2 §10). Returns null on error/disabled. */
@Component
public class GeminiChatClient {

    private static final Logger log = LoggerFactory.getLogger(GeminiChatClient.class);
    private static final String BASE = "https://generativelanguage.googleapis.com/v1beta/models/";

    private final AppProperties props;
    private final RestClient http = RestClient.create();

    public GeminiChatClient(AppProperties props) {
        this.props = props;
    }

    public boolean isEnabled() { return props.getGemini().isEnabled(); }

    /** @param history prior turns in order; @return the assistant reply, or null on failure. */
    public String chat(String systemPrompt, List<AiMessage> history, String userMessage) {
        if (!isEnabled()) return null;
        try {
            List<Map<String, Object>> contents = new ArrayList<>();
            for (AiMessage m : history) {
                contents.add(Map.of(
                        "role", m.getRole() == AiMessage.Role.ASSISTANT ? "model" : "user",
                        "parts", List.of(Map.of("text", m.getContent()))));
            }
            contents.add(Map.of("role", "user", "parts", List.of(Map.of("text", userMessage))));

            Map<String, Object> body = Map.of(
                    "system_instruction", Map.of("parts", List.of(Map.of("text", systemPrompt))),
                    "contents", contents,
                    "generationConfig", Map.of("temperature", 0.6, "maxOutputTokens", 500));

            String url = BASE + props.getGemini().getModel() + ":generateContent?key=" + props.getGemini().getApiKey();
            JsonNode res = http.post().uri(url).body(body).retrieve().body(JsonNode.class);
            String text = res.path("candidates").path(0).path("content").path("parts").path(0)
                    .path("text").asText("");
            return text.isBlank() ? null : text.trim();
        } catch (Exception e) {
            log.warn("Gemini chat failed: {}", e.getMessage());
            return null;
        }
    }
}
