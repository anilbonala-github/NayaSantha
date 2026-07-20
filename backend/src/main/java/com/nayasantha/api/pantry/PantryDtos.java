package com.nayasantha.api.pantry;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public final class PantryDtos {

    private PantryDtos() {}

    /** Stock/expiry status are computed by the backend, not the client (Vol2 §6.4). */
    public record PantryItemDto(UUID id, UUID productId, String name, BigDecimal quantity,
                                String unit, BigDecimal lowStockThreshold,
                                LocalDate purchaseDate, LocalDate expiryDate, String source,
                                String stockStatus, String expiryStatus, Integer daysToExpiry,
                                Long version) {}

    public record UpsertPantryItemRequest(
            UUID productId,
            @NotBlank String name,
            @PositiveOrZero BigDecimal quantity,
            String unit,
            @PositiveOrZero BigDecimal lowStockThreshold,
            LocalDate purchaseDate,
            LocalDate expiryDate,
            Long version) {}
}
