package com.nayasantha.api.notification;

import java.time.Instant;
import java.util.UUID;

public final class NotificationDtos {

    private NotificationDtos() {}

    public record NotificationDto(UUID id, String type, String title, String body,
                                  UUID orderId, boolean read, Instant createdAt) {
        static NotificationDto from(Notification n) {
            return new NotificationDto(n.getId(), n.getType(), n.getTitle(), n.getBody(),
                    n.getOrderId(), n.getReadAt() != null, n.getCreatedAt());
        }
    }

    public record UnreadCountDto(long count) {}
}
