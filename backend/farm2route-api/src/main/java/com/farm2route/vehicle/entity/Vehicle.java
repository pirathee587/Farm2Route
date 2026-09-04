package com.farm2route.vehicle.entity;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.common.enums.VehicleType;
import com.farm2route.driver.entity.DriverProfile;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "vehicles")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Vehicle {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "agency_id", nullable = false)
    private AgencyProfile agency;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_driver_id")
    private DriverProfile assignedDriver;

    @Column(name = "vehicle_registration_number", nullable = false, unique = true)
    private String registrationNumber;

    @Column(name = "make_and_model", nullable = false)
    private String makeAndModel;

    @Column(name = "max_payload_weight_kg", nullable = false, precision = 10, scale = 2)
    private BigDecimal capacity;

    @Column(name = "max_cargo_volume_cbm", nullable = false, precision = 10, scale = 2)
    private BigDecimal cargoVolumeCbm;

    @Enumerated(EnumType.STRING)
    @Column(name = "vehicle_type", nullable = false)
    private VehicleType vehicleType;

    @Column(name = "is_refrigerated", nullable = false)
    @Builder.Default
    private boolean isRefrigerated = false;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    @Builder.Default
    private VehicleStatus status = VehicleStatus.AVAILABLE;

    @Column(name = "insurance_policy_number")
    private String insurancePolicyNumber;

    @Column(name = "make_and_model")
    private String makeAndModel;

    @Column(name = "insurance_expiry_date")
    private LocalDate insuranceExpiryDate;

    @Column(name = "revenue_license_number")
    private String revenueLicenseNumber;

    @Column(name = "revenue_license_expiry_date")
    private LocalDate revenueLicenseExpiryDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    @Builder.Default
    private VehicleStatus status = VehicleStatus.AVAILABLE;

    @Enumerated(EnumType.STRING)
    @Column(name = "kyc_status", nullable = false)
    @Builder.Default
    private KycStatus kycStatus = KycStatus.PENDING_APPROVAL;

    @Column(name = "rejection_reason")
    private String rejectionReason;

    @Column(name = "verified_at")
    private Instant verifiedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}