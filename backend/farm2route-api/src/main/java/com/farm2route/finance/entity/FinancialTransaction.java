package com.farm2route.finance.entity;

import com.farm2route.auth.entity.User;
import com.farm2route.booking.entity.Booking;
import com.farm2route.common.enums.PaymentMethod;
import com.farm2route.common.enums.TransactionStatus;
import com.farm2route.common.enums.TransactionType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "transactions")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class FinancialTransaction {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "transaction_reference", nullable = false, unique = true, length = 100)
    private String transactionReference;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "booking_id")
    private Booking booking;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "payer_user_id", nullable = false)
    private User payer;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "payee_user_id")
    private User payee;
    @Column(nullable = false, precision = 10, scale = 2) private BigDecimal amount;
    @Column(name = "commission_deducted", nullable = false, precision = 10, scale = 2) private BigDecimal commissionDeducted;
    @Column(name = "net_amount", nullable = false, precision = 10, scale = 2) private BigDecimal netAmount;
    @Enumerated(EnumType.STRING) @Column(name = "transaction_type", nullable = false, length = 50)
    private TransactionType transactionType;
    @Enumerated(EnumType.STRING) @Column(name = "payment_method", nullable = false, length = 50)
    private PaymentMethod paymentMethod;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30)
    private TransactionStatus status;
    @CreationTimestamp @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
}
