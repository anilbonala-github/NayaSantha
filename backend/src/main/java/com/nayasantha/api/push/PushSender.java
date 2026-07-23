package com.nayasantha.api.push;

import java.util.UUID;

/**
 * Push-delivery seam (Vol2A §13, Vol1 FCM). Mirrors in-app notifications to the
 * user's registered devices. The default {@link LogPushSender} just logs; a real
 * {@code FcmPushSender} (Firebase) drops in as {@code @Primary} gated by config,
 * with no other code changes.
 */
public interface PushSender {
    /** Send a push to every registered device of {@code userId}. Best-effort. */
    void sendToUser(UUID userId, String title, String body);
}
