package com.nayasantha.api.catalogue;

import org.springframework.data.domain.Page;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.function.Function;

/** Catalogue DTOs (Vol2 §6.3). Products always carry their current price + effective date. */
public final class CatalogueDtos {

    private CatalogueDtos() {}

    public record CategoryDto(UUID id, String name, String slug, String emoji, int sortOrder) {
        static CategoryDto from(Category c) {
            return new CategoryDto(c.getId(), c.getName(), c.getSlug(), c.getEmoji(), c.getSortOrder());
        }
    }

    public record ProductDto(
            UUID id, String sku, String name, UUID categoryId, String unit, String description,
            String emoji, String imageUrl, String origin, String farmer,
            BigDecimal rating, int ratingCount, List<String> badges,
            boolean inStock,
            BigDecimal mrp, BigDecimal sellingPrice, BigDecimal maxPrice,
            Instant priceEffectiveFrom, Long priceVersion) {

        static ProductDto from(Product p, ProductPrice price) {
            List<String> badgeList = (p.getBadges() == null || p.getBadges().isBlank())
                    ? List.of()
                    : Arrays.stream(p.getBadges().split(",")).map(String::trim).toList();
            return new ProductDto(
                    p.getId(), p.getSku(), p.getName(), p.getCategoryId(), p.getUnit(), p.getDescription(),
                    p.getEmoji(), p.getImageUrl(), p.getOrigin(), p.getFarmer(),
                    p.getRating(), p.getRatingCount(), badgeList,
                    price != null,
                    price == null ? null : price.getMrp(),
                    price == null ? null : price.getSellingPrice(),
                    price == null ? null : price.getMaxPrice(),
                    price == null ? null : price.getEffectiveFrom(),
                    price == null ? null : price.getVersion());
        }
    }

    /** Paginated list envelope (Vol2 §5: all list APIs paginate). */
    public record PageDto<T>(List<T> items, int page, int size, long totalElements, int totalPages) {
        static <E, T> PageDto<T> from(Page<E> page, Function<E, T> mapper) {
            return new PageDto<>(page.getContent().stream().map(mapper).toList(),
                    page.getNumber(), page.getSize(), page.getTotalElements(), page.getTotalPages());
        }
    }
}
