package com.nayasantha.api.settings;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

import java.math.BigDecimal;

public final class SettingsDtos {

    private SettingsDtos() {}

    public record SettingsDto(int bufferPercent, BigDecimal capPercent,
                              int varianceThresholdPercent, String deliverySlot,
                              BigDecimal deliveryFee, String priorityDeliverySlot) {
        static SettingsDto from(OpsSettings s) {
            return new SettingsDto(s.getBufferPercent(), s.getCapPercent(),
                    s.getVarianceThresholdPercent(), s.getDeliverySlot(),
                    s.getDeliveryFee(), s.getPriorityDeliverySlot());
        }
    }

    public record UpdateSettingsRequest(
            @Min(0) @Max(50) Integer bufferPercent,
            @DecimalMin("0.0") BigDecimal capPercent,
            @Min(0) @Max(100) Integer varianceThresholdPercent,
            String deliverySlot,
            @DecimalMin("0.0") BigDecimal deliveryFee,
            String priorityDeliverySlot) {}
}
