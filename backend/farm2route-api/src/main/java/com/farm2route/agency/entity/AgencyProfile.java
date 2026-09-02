package com.farm2route.agency.entity;

import com.farm2route.auth.entity.User;
import com.farm2route.common.enums.KycStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "agency_profiles")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AgencyProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "company_name", nullable = false)
    private String companyName;

    @Column(name = "business_registration_number", nullable = false, unique = true)
    private String businessRegistrationNumber;

    @Column(name = "tax_identification_number")
    private String taxIdentificationNumber;

    @Column(name = "office_address", nullable = false)
    private String officeAddress;

    @Column(nullable = false)
    private String district;

    @Column(name = "contact_person_name", nullable = false)
    private String contactPersonName;

    @Column(name = "contact_person_phone", nullable = false)
    private String contactPersonPhone;

    @Enumerated(EnumType.STRING)
    @Column(name = "kyc_status", nullable = false)
    @Builder.Default
    private KycStatus kycStatus = KycStatus.PENDING;

    @Column(name = "kyc_document_url")
    private String kycDocumentUrl;

    @Column(name = "kyc_rejection_reason")
    private String kycRejectionReason;

    @Column(name = "verified_at")
    private Instant verifiedAt;

    @Column(name = "commission_rate_percentage", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal commissionRatePercentage = BigDecimal.valueOf(10.00);

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
