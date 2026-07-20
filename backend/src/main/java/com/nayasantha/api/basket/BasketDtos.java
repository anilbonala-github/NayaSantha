package com.nayasantha.api.basket;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/** Basket DTOs (Vol2 §6.6). Response carries recalculated estimate + guaranteed max. */
public final class BasketDtos {

    private BasketDtos() {}

    public record BasketItemDto(UUID id, UUID productId, String name, String emoji, String unit,
                                int quantity, BigDecimal unitSellingPrice, BigDecimal unitMaxPrice,
                                BigDecimal lineEstimate, BigDecimal lineMax, Long version) {}

    public record BasketDto(UUID id, String status, int itemCount,
                            BigDecimal estimatedTotal, BigDecimal maximumPayable,
                            List<BasketItemDto> items, Long version) {}

    public record AddItemRequest(@NotNull UUID productId, @Min(1) int quantity) {}

    public record UpdateItemRequest(@Min(0) int quantity, Long version) {}
}
