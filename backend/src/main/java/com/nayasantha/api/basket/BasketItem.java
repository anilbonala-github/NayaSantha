package com.nayasantha.api.basket;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "basket_items")
@Getter
@Setter
public class BasketItem extends BaseEntity {

    @Column(name = "basket_id", nullable = false)
    private UUID basketId;

    @Column(name = "product_id", nullable = false)
    private UUID productId;

    @Column(nullable = false)
    private int quantity;

    /** Price snapshot at add time; refreshed on quantity edits. */
    @Column(name = "unit_selling_price", nullable = false)
    private BigDecimal unitSellingPrice;

    @Column(name = "unit_max_price", nullable = false)
    private BigDecimal unitMaxPrice;

    @Column(name = "price_version", nullable = false)
    private long priceVersion = 0;
}
