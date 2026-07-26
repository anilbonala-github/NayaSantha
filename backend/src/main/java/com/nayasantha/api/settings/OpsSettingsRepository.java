package com.nayasantha.api.settings;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface OpsSettingsRepository extends JpaRepository<OpsSettings, UUID> {
}
