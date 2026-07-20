package com.nayasantha.api.basket;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Entity
@Table(name = "baskets")
@Getter
@Setter
public class Basket extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status = Status.ACTIVE;

    @Column(name = "weekly_plan_id")
    private UUID weeklyPlanId;

    public enum Status { ACTIVE, CHECKED_OUT, ABANDONED }
}
