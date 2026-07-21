package com.nayasantha.api.assistant;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

interface AiConversationRepository extends JpaRepository<AiConversation, UUID> {}

interface AiMessageRepository extends JpaRepository<AiMessage, UUID> {
    List<AiMessage> findByConversationIdOrderByCreatedAtAsc(UUID conversationId);
}
