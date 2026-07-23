package com.nayasantha.api.push;

import com.nayasantha.api.device.UserDeviceRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Default push sender: resolves the user's devices and logs what would be sent.
 * Keeps the notification pipeline fully working until Firebase is configured;
 * a real {@code FcmPushSender} replaces it via {@code @Primary}.
 */
@Component
public class LogPushSender implements PushSender {

    private static final Logger log = LoggerFactory.getLogger(LogPushSender.class);

    private final UserDeviceRepository devices;

    public LogPushSender(UserDeviceRepository devices) {
        this.devices = devices;
    }

    @Override
    public void sendToUser(UUID userId, String title, String body) {
        int n = devices.findByUserId(userId).size();
        log.info("[push:log] -> {} device(s) for user {} : \"{}\"", n, userId, title);
    }
}
