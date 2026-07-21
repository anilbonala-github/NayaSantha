package com.nayasantha.api.assistant;

import com.nayasantha.api.assistant.AssistantDtos.*;
import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/** AI assistant chat (Vol2 §7, §10). Gemini answers with sanitized context. */
@RestController
@RequestMapping("/api/v1/ai")
public class AssistantController {

    private final AssistantService assistant;

    public AssistantController(AssistantService assistant) {
        this.assistant = assistant;
    }

    @PostMapping("/messages")
    public ApiResponse<SendResponse> send(@Valid @RequestBody SendMessageRequest body) {
        return ApiResponse.of(assistant.send(CurrentUser.id(), body.conversationId(), body.message()));
    }

    @GetMapping("/conversations/{id}/messages")
    public ApiResponse<List<MessageDto>> history(@PathVariable UUID id) {
        return ApiResponse.of(assistant.history(CurrentUser.id(), id));
    }
}
