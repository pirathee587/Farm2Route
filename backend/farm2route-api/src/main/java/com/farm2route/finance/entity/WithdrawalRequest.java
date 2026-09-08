package com.farm2route.finance.entity;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.bank.entity.BankDetails;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "withdrawal_requests")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class WithdrawalRequest {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "agency_id", nullable = false)
    private AgencyProfile agency;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "bank_detail_id", nullable = false)
    private BankDetails bankDetails;
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal amount;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30)
    @Builder.Default
    private WithdrawalRequestStatus status = WithdrawalRequestStatus.PENDING;
    @Column(name = "admin_notes", columnDefinition = "TEXT")
    private String adminNotes;
    @Column(name = "processed_by_admin_id")
    private UUID processedByAdminId;
    @Column(name = "processed_at")
    private Instant processedAt;
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
