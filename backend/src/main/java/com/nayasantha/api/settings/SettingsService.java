package com.nayasantha.api.settings;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

/**
 * Reads/writes the single ops-settings row and exposes typed accessors used by
 * the pricing/procurement services (buffer %, guaranteed-max factor, delivery slot).
 */
@Service
public class SettingsService {

    private final OpsSettingsRepository repo;

    public SettingsService(OpsSettingsRepository repo) {
        this.repo = repo;
    }

    @Transactional
    public OpsSettings current() {
        return repo.findAll().stream().findFirst().orElseGet(() -> repo.save(new OpsSettings()));
    }

    @Transactional
    public OpsSettings update(SettingsDtos.UpdateSettingsRequest req) {
        OpsSettings s = current();
        if (req.bufferPercent() != null) s.setBufferPercent(req.bufferPercent());
        if (req.capPercent() != null) s.setCapPercent(req.capPercent());
        if (req.varianceThresholdPercent() != null) s.setVarianceThresholdPercent(req.varianceThresholdPercent());
        if (req.deliverySlot() != null && !req.deliverySlot().isBlank()) s.setDeliverySlot(req.deliverySlot());
        return repo.save(s);
    }

    // --- typed accessors for other services --------------------------------------
    public int bufferPercent() {
        return current().getBufferPercent();
    }

    /** Guaranteed-max factor = 1 + capPercent/100 (e.g. 1.025). */
    public BigDecimal capFactor() {
        return BigDecimal.ONE.add(current().getCapPercent().movePointLeft(2));
    }

    public String deliverySlot() {
        return current().getDeliverySlot();
    }
}
