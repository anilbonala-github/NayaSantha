package com.nayasantha.api.notification;

import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.notification.NotificationDtos.NotificationDto;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Creates and reads in-app notifications (Vol2A §13). */
@Service
public class NotificationService {

    // Notification type constants (kept simple; the client maps these to icons).
    public static final String ORDER_CONFIRMED = "ORDER_CONFIRMED";
    public static final String MARKET_UPDATE = "MARKET_UPDATE";
    public static final String PRICE_EXCEPTION = "PRICE_EXCEPTION";
    public static final String PAYMENT_COMPLETE = "PAYMENT_COMPLETE";
    public static final String CUTOFF_REMINDER = "CUTOFF_REMINDER";
    public static final String OUT_FOR_DELIVERY = "OUT_FOR_DELIVERY";
    public static final String DELIVERED = "DELIVERED";

    private final NotificationRepository repo;

    public NotificationService(NotificationRepository repo) {
        this.repo = repo;
    }

    /** Fire-and-forget create used by the order/settlement lifecycle. */
    @Transactional
    public void create(UUID userId, String type, String title, String body, UUID orderId) {
        Notification n = new Notification();
        n.setUserId(userId);
        n.setType(type);
        n.setTitle(title);
        n.setBody(body);
        n.setOrderId(orderId);
        n.setCreatedAt(Instant.now());
        repo.save(n);
    }

    @Transactional(readOnly = true)
    public List<NotificationDto> list(UUID userId, int page, int size) {
        Page<Notification> p = repo.findByUserIdOrderByCreatedAtDesc(
                userId, PageRequest.of(page, Math.min(size, 50)));
        return p.getContent().stream().map(NotificationDto::from).toList();
    }

    @Transactional(readOnly = true)
    public long unreadCount(UUID userId) {
        return repo.countByUserIdAndReadAtIsNull(userId);
    }

    @Transactional
    public NotificationDto markRead(UUID userId, UUID id) {
        Notification n = repo.findByIdAndUserId(id, userId)
                .orElseThrow(() -> ApiException.notFound("Notification"));
        if (n.getReadAt() == null) {
            n.setReadAt(Instant.now());
            repo.save(n);
        }
        return NotificationDto.from(n);
    }

    @Transactional
    public long markAllRead(UUID userId) {
        return repo.markAllRead(userId, Instant.now());
    }
}
