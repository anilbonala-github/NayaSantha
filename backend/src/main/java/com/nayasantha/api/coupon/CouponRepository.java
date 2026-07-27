package com.nayasantha.api.coupon;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CouponRepository extends JpaRepository<Coupon, UUID> {
    List<Coupon> findByActiveTrueOrderBySortOrderAsc();
    Optional<Coupon> findByCodeIgnoreCase(String code);
}
