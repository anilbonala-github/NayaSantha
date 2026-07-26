package com.nayasantha.api.subscription;

import jakarta.validation.constraints.NotBlank;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

public final class SubscriptionDtos {

    private SubscriptionDtos() {}

    public record PlanDto(String code, String name, String badge,
                          BigDecimal pricePerMonth, List<String> perks) {
        static PlanDto from(SubscriptionPlan p) {
            List<String> perks = p.getPerks() == null || p.getPerks().isBlank()
                    ? List.of()
                    : Arrays.stream(p.getPerks().split("\n")).filter(s -> !s.isBlank()).toList();
            return new PlanDto(p.getCode(), p.getName(), p.getBadge(), p.getPricePerMonth(), perks);
        }
    }

    public record SubscriptionDto(UUID id, String planCode, String planName, String status,
                                  String billingCycle, Instant startedAt, Instant renewsAt) {}

    public record SubscribeRequest(@NotBlank String planCode) {}
}
