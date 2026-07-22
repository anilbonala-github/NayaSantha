package com.nayasantha.api.notification;

import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.notification.NotificationDtos.*;
import com.nayasantha.api.security.CurrentUser;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/** In-app notifications for the signed-in customer (Vol2 §6, Vol2A §13). */
@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    private final NotificationService notifications;

    public NotificationController(NotificationService notifications) {
        this.notifications = notifications;
    }

    @GetMapping
    public ApiResponse<List<NotificationDto>> list(@RequestParam(defaultValue = "0") int page,
                                                   @RequestParam(defaultValue = "30") int size) {
        return ApiResponse.of(notifications.list(CurrentUser.id(), page, size));
    }

    @GetMapping("/unread-count")
    public ApiResponse<UnreadCountDto> unreadCount() {
        return ApiResponse.of(new UnreadCountDto(notifications.unreadCount(CurrentUser.id())));
    }

    @PatchMapping("/{id}/read")
    public ApiResponse<NotificationDto> markRead(@PathVariable UUID id) {
        return ApiResponse.of(notifications.markRead(CurrentUser.id(), id));
    }

    @PostMapping("/read-all")
    public ApiResponse<Map<String, Long>> markAllRead() {
        return ApiResponse.of(Map.of("updated", notifications.markAllRead(CurrentUser.id())));
    }
}
