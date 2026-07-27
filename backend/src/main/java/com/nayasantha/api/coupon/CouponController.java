package com.nayasantha.api.coupon;

import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.coupon.CouponDtos.CouponDto;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Public-facing coupon catalogue for the offers screen. */
@RestController
@RequestMapping("/api/v1/coupons")
public class CouponController {

    private final CouponService coupons;

    public CouponController(CouponService coupons) {
        this.coupons = coupons;
    }

    @GetMapping
    public ApiResponse<List<CouponDto>> list() {
        return ApiResponse.of(coupons.listActive());
    }
}
