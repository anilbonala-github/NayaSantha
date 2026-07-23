package com.nayasantha.api.device;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

/** A registered device token for push delivery (Vol2 §3.2, table from V1). */
@Entity
@Table(name = "user_devices")
@Getter
@Setter
public class UserDevice extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "fcm_token")
    private String fcmToken;

    /** ANDROID | IOS | WEB (DB check constraint from V1). */
    private String platform;

    @Column(name = "app_version")
    private String appVersion;

    @Column(name = "last_active_at")
    private Instant lastActiveAt;
}
