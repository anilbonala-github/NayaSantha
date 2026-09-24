package com.nayasantha.api.catalogue;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.Instant;

import java.util.List;
import java.util.UUID;

public interface ProductPriceRepository extends JpaRepository<ProductPrice, UUID> {

    @Query("select p from ProductPrice p where p.productId in :ids and p.zone = :zone "
            + "and p.active = true and p.effectiveFrom <= :at "
            + "and (p.effectiveTo is null or p.effectiveTo > :at) "
            + "order by p.effectiveFrom desc, p.createdAt desc, p.id desc")
    List<ProductPrice> findEffectivePrices(@Param("ids") List<UUID> ids,
            @Param("zone") String zone, @Param("at") Instant at);

    List<ProductPrice> findByProductIdInAndZoneAndActiveTrue(List<UUID> ids, String zone);
    boolean existsByProductId(java.util.UUID productId);
}
