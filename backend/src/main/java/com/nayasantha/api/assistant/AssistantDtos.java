package com.nayasantha.api.assistant;

import jakarta.validation.constraints.NotBlank;

import java.time.Instant;
import java.util.UUID;

public final class AssistantDtos {

    private AssistantDtos() {}

    public record SendMessageRequest(UUID conversationId, @NotBlank String message) {}

    public record MessageDto(String role, String content, Instant createdAt) {
        static MessageDto from(AiMessage m) {
            return new MessageDto(m.getRole().name(), m.getContent(), m.getCreatedAt());
        }
    }

    public record SendResponse(UUID conversationId, String reply, boolean aiPowered) {}
}
