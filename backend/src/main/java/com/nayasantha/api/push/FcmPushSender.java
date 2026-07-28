package com.nayasantha.api.push;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.*;
import com.nayasantha.api.device.UserDevice;
import com.nayasantha.api.device.UserDeviceRepository;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.UUID;

/**
 * Real Firebase Cloud Messaging sender. Activates (as {@code @Primary}, over
 * {@link LogPushSender}) only when {@code nayasantha.push.fcm.enabled=true} and a
 * service-account JSON is supplied via {@code FIREBASE_CREDENTIALS_JSON}. Best-effort:
 * failures are logged, never thrown, and stale tokens are pruned from the registry.
 */
@Component
@Primary
@ConditionalOnProperty(name = "nayasantha.push.fcm.enabled", havingValue = "true")
public class FcmPushSender implements PushSender {

    private static final Logger log = LoggerFactory.getLogger(FcmPushSender.class);
    private static final String APP_NAME = "nayasantha";

    private final UserDeviceRepository devices;

    @Value("${nayasantha.push.fcm.credentials-json:}")
    private String credentialsJson;

    private FirebaseMessaging messaging;

    public FcmPushSender(UserDeviceRepository devices) {
        this.devices = devices;
    }

    @PostConstruct
    void init() {
        if (credentialsJson == null || credentialsJson.isBlank()) {
            log.warn("[push:fcm] enabled but FIREBASE_CREDENTIALS_JSON is empty — pushes will be skipped");
            return;
        }
        try {
            GoogleCredentials creds = GoogleCredentials.fromStream(
                    new ByteArrayInputStream(credentialsJson.getBytes(StandardCharsets.UTF_8)));
            FirebaseOptions options = FirebaseOptions.builder().setCredentials(creds).build();
            FirebaseApp app = FirebaseApp.getApps().stream()
                    .filter(a -> APP_NAME.equals(a.getName())).findFirst()
                    .orElseGet(() -> FirebaseApp.initializeApp(options, APP_NAME));
            messaging = FirebaseMessaging.getInstance(app);
            log.info("[push:fcm] Firebase Cloud Messaging initialised");
        } catch (Exception e) {
            log.error("[push:fcm] failed to initialise Firebase — pushes will be skipped: {}", e.getMessage());
        }
    }

    @Override
    public void sendToUser(UUID userId, String title, String body) {
        if (messaging == null) return;
        List<UserDevice> userDevices = devices.findByUserId(userId).stream()
                .filter(d -> d.getFcmToken() != null && !d.getFcmToken().isBlank())
                .toList();
        if (userDevices.isEmpty()) return;

        List<String> tokens = userDevices.stream().map(UserDevice::getFcmToken).distinct().toList();
        try {
            MulticastMessage message = MulticastMessage.builder()
                    .addAllTokens(tokens)
                    .setNotification(Notification.builder().setTitle(title).setBody(body).build())
                    .build();
            BatchResponse resp = messaging.sendEachForMulticast(message);
            if (resp.getFailureCount() > 0) pruneStaleTokens(userId, tokens, resp);
            log.info("[push:fcm] user {} : {} sent, {} failed", userId, resp.getSuccessCount(), resp.getFailureCount());
        } catch (Exception e) {
            log.warn("[push:fcm] send failed for user {}: {}", userId, e.getMessage());
        }
    }

    /** Remove tokens Firebase reports as unregistered/invalid so we stop pushing to them. */
    private void pruneStaleTokens(UUID userId, List<String> tokens, BatchResponse resp) {
        List<SendResponse> responses = resp.getResponses();
        for (int i = 0; i < responses.size(); i++) {
            SendResponse r = responses.get(i);
            if (r.isSuccessful() || r.getException() == null) continue;
            MessagingErrorCode code = r.getException().getMessagingErrorCode();
            if (code == MessagingErrorCode.UNREGISTERED || code == MessagingErrorCode.INVALID_ARGUMENT) {
                try {
                    devices.deleteByUserIdAndFcmToken(userId, tokens.get(i));
                    log.info("[push:fcm] pruned stale token for user {}", userId);
                } catch (Exception ignore) {
                    // best-effort cleanup
                }
            }
        }
    }
}
