package com.farm2route.driver.entity;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.auth.entity.User;
import com.farm2route.common.enums.DriverAvailability;
import com.farm2route.common.enums.KycStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "driver_profiles")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DriverProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "agency_id", nullable = false)
    private AgencyProfile agency;

    @Column(name = "full_name")
    private String fullName;

    @Column(name = "driving_license_number", nullable = false, unique = true)
    private String drivingLicenseNumber;

    @Column(name = "license_expiry_date", nullable = false)
    private LocalDate licenseExpiryDate;

    @Column(name = "nic_number", nullable = false, unique = true)
    private String nicNumber;

    @Enumerated(EnumType.STRING)
    @Column(name = "kyc_status", nullable = false)
    @Builder.Default
    private KycStatus kycStatus = KycStatus.PENDING;

    @Column(name = "kyc_document_url")
    private String kycDocumentUrl;

    @Column(name = "kyc_rejection_reason")
    private String kycRejectionReason;

    @Enumerated(EnumType.STRING)
    @Column(name = "availability_status", nullable = false)
    @Builder.Default
    private DriverAvailability availabilityStatus = DriverAvailability.AVAILABLE;

    @Column(name = "rating_average", precision = 3, scale = 2)
    @Builder.Default
    private BigDecimal ratingAverage = BigDecimal.valueOf(5.00);

    @Column(name = "total_ratings_count")
    @Builder.Default
    private int totalRatingsCount = 0;

    @Column(name = "verified_at")
    private Instant verifiedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
