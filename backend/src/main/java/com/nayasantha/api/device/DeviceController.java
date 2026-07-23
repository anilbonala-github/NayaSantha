package com.nayasantha.api.device;

import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.security.CurrentUser;
import jakarta.validation.constraints.NotBlank;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/** Device-token registration for push (Vol2 §3.2). The app calls this after login. */
@RestController
@RequestMapping("/api/v1/devices")
public class DeviceController {

    private final UserDeviceRepository devices;

    public DeviceController(UserDeviceRepository devices) {
        this.devices = devices;
    }

    public record RegisterDeviceRequest(@NotBlank String fcmToken, String platform, String appVersion) {}

    private static final java.util.Set<String> PLATFORMS = java.util.Set.of("ANDROID", "IOS", "WEB");

    /** Register or refresh a device token (idempotent per user+token). */
    @PostMapping
    @Transactional
    public ApiResponse<Map<String, String>> register(@RequestBody RegisterDeviceRequest body) {
        UUID userId = CurrentUser.id();
        UserDevice device = devices.findByUserIdAndFcmToken(userId, body.fcmToken())
                .orElseGet(UserDevice::new);
        device.setUserId(userId);
        device.setFcmToken(body.fcmToken());
        String platform = body.platform() == null ? null : body.platform().toUpperCase();
        device.setPlatform(PLATFORMS.contains(platform) ? platform : null);
        device.setAppVersion(body.appVersion());
        device.setLastActiveAt(Instant.now());
        devices.save(device);
        return ApiResponse.of(Map.of("status", "registered"));
    }

    /** Unregister a token (call on logout). */
    @DeleteMapping
    @Transactional
    public ApiResponse<Map<String, String>> unregister(@RequestParam String fcmToken) {
        devices.deleteByUserIdAndFcmToken(CurrentUser.id(), fcmToken);
        return ApiResponse.of(Map.of("status", "removed"));
    }
}
