package com.nayasantha.api.device;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserDeviceRepository extends JpaRepository<UserDevice, UUID> {
    List<UserDevice> findByUserId(UUID userId);
    Optional<UserDevice> findByUserIdAndFcmToken(UUID userId, String fcmToken);
    void deleteByUserIdAndFcmToken(UUID userId, String fcmToken);
}
