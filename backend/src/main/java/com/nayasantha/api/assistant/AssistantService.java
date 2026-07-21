package com.nayasantha.api.assistant;

import com.nayasantha.api.assistant.AssistantDtos.*;
import com.nayasantha.api.catalogue.Product;
import com.nayasantha.api.catalogue.ProductRepository;
import com.nayasantha.api.common.ApiException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/** AI assistant: persists conversations and answers via Gemini with sanitized
 *  NayaSantha context (Vol2 §10). Falls back to a canned reply if Gemini is off. */
@Service
public class AssistantService {

    private final AiConversationRepository conversations;
    private final AiMessageRepository messages;
    private final GeminiChatClient gemini;
    private final ProductRepository products;

    public AssistantService(AiConversationRepository conversations, AiMessageRepository messages,
                            GeminiChatClient gemini, ProductRepository products) {
        this.conversations = conversations;
        this.messages = messages;
        this.gemini = gemini;
        this.products = products;
    }

    @Transactional
    public SendResponse send(UUID userId, UUID conversationId, String message) {
        AiConversation convo = (conversationId == null) ? null
                : conversations.findById(conversationId)
                        .filter(c -> c.getUserId().equals(userId)).orElse(null);
        if (convo == null) {
            convo = new AiConversation();
            convo.setUserId(userId);
            convo.setTitle(message.length() > 60 ? message.substring(0, 60) : message);
            convo = conversations.save(convo);
        }

        List<AiMessage> history = messages.findByConversationIdOrderByCreatedAtAsc(convo.getId());

        AiMessage userMsg = new AiMessage();
        userMsg.setConversationId(convo.getId());
        userMsg.setRole(AiMessage.Role.USER);
        userMsg.setContent(message);
        messages.save(userMsg);

        String reply = gemini.chat(systemPrompt(), history, message);
        boolean aiPowered = reply != null;
        if (reply == null) {
            reply = "I can help you plan your week, find products, and understand your orders. "
                    + "Try asking me what to cook this week or what's in season.";
        }

        AiMessage botMsg = new AiMessage();
        botMsg.setConversationId(convo.getId());
        botMsg.setRole(AiMessage.Role.ASSISTANT);
        botMsg.setContent(reply);
        messages.save(botMsg);

        convo.setUpdatedAt(Instant.now());
        conversations.save(convo);
        return new SendResponse(convo.getId(), reply, aiPowered);
    }

    @Transactional(readOnly = true)
    public List<MessageDto> history(UUID userId, UUID conversationId) {
        AiConversation convo = conversations.findById(conversationId)
                .filter(c -> c.getUserId().equals(userId))
                .orElseThrow(() -> ApiException.notFound("Conversation"));
        return messages.findByConversationIdOrderByCreatedAtAsc(convo.getId()).stream()
                .map(MessageDto::from).toList();
    }

    private String systemPrompt() {
        String catalogue = products.findByActiveTrueOrderByNameAsc().stream()
                .map(Product::getName).collect(Collectors.joining(", "));
        return """
            You are the NayaSantha assistant. NayaSantha is an AI-powered weekly grocery
            market piloting in Hyderabad apartment communities. Customers plan a weekly
            basket, approve it before the Saturday 10 PM cutoff with an estimated total and
            a guaranteed maximum payable, and pay the actual Sunday market price (never above
            their maximum without consent). Help with weekly meal planning, choosing products,
            pantry management, orders and healthy budget-friendly eating for Indian households.
            Be concise (2-4 sentences), warm and practical. You cannot see live prices or place
            orders or payments; for those, guide the customer to the relevant screen in the app.
            Currently available products: %s.
            """.formatted(catalogue);
    }
}
