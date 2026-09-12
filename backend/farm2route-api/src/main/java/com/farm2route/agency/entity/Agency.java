package com.farm2route.agency.entity;

import com.farm2route.agency.enums.AgencyStatus;
import com.farm2route.agency.enums.AgencyType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "agencies", indexes = {
        @Index(name = "idx_agencies_email", columnList = "email", unique = true),
        @Index(name = "idx_agencies_phone", columnList = "phone_number", unique = true),
        @Index(name = "idx_agencies_status", columnList = "status")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Agency {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "agency_name", nullable = false)
    private String agencyName;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(name = "phone_number", nullable = false, unique = true)
    private String phoneNumber;

    @Enumerated(EnumType.STRING)
    @Column(name = "agency_type", nullable = false)
    private AgencyType agencyType;

    @Column(name = "business_reg_number")
    private String businessRegNumber;

    @Column(name = "business_reg_expiry_date")
    private java.time.LocalDate businessRegExpiryDate;

    @Column(nullable = false)
    private String district;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String address;

    @Column(name = "contact_person_name")
    private String contactPersonName;

    @Column(name = "bank_account_number")
    private String bankAccountNumber;

    @Column(name = "bank_name")
    private String bankName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private AgencyStatus status = AgencyStatus.ACCOUNT_CREATED;

    @Column(name = "email_verified", nullable = false)
    @Builder.Default
    private boolean emailVerified = false;

    @Column(name = "phone_verified", nullable = false)
    @Builder.Default
    private boolean phoneVerified = false;

    @Column(name = "rejection_reason", columnDefinition = "TEXT")
    private String rejectionReason;

    @Column(name = "rejected_at")
    private Instant rejectedAt;

    @Column(name = "rejected_by")
    private UUID rejectedBy;

    @Column(name = "email_verification_token")
    private String emailVerificationToken;

    @Column(name = "email_verification_expires_at")
    private Instant emailVerificationExpiresAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
