package com.nayasantha.api.catalogue;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ProductPriceRepository extends JpaRepository<ProductPrice, UUID> {

    Optional<ProductPrice> findFirstByProductIdAndActiveTrueOrderByEffectiveFromDesc(UUID productId);

    List<ProductPrice> findByProductIdInAndActiveTrue(List<UUID> productIds);
}
