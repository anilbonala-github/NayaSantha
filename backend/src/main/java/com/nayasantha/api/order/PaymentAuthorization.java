package com.nayasantha.api.order;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

/** UPI-Autopay-style mandate: authorize the maximum, capture only the final amount
 *  (Vol2A §14). Amounts only — never raw payment credentials. */
@Entity
@Table(name = "payment_authorizations")
@Getter
@Setter
public class PaymentAuthorization extends BaseEntity {

    @Column(name = "order_id", nullable = false)
    private UUID orderId;

    @Column(nullable = false)
    private String provider = "UPI_AUTOPAY";

    @Column(name = "authorized_amount", nullable = false)
    private BigDecimal authorizedAmount;

    @Column(name = "captured_amount")
    private BigDecimal capturedAmount;

    private String reference;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status = Status.AUTHORIZED;

    public enum Status { AUTHORIZED, CAPTURED, REFUNDED, FAILED }
}
