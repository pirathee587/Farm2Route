package com.farm2route.farmer.entity;

import com.farm2route.farmer.enums.CropType;
import com.farm2route.farmer.enums.FarmerStatus;
import com.farm2route.farmer.enums.PreferredLanguage;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "farmers", indexes = {
        @Index(name = "idx_farmers_phone", columnList = "phone_number", unique = true),
        @Index(name = "idx_farmers_status", columnList = "status"),
        @Index(name = "idx_farmers_district", columnList = "district")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Farmer {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Column(name = "nic_number", unique = true)
    private String nicNumber;

    @Column(name = "phone_number", nullable = false, unique = true)
    private String phoneNumber;

    @Column(name = "email")
    private String email;

    @Column(name = "district", nullable = false)
    private String district;

    @Column(name = "gn_division")
    private String gnDivision;

    @Column(columnDefinition = "TEXT")
    private String address;

    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;

    @Column(name = "farm_size_acres", precision = 10, scale = 2)
    private BigDecimal farmSizeAcres;

    @ElementCollection(targetClass = CropType.class, fetch = FetchType.EAGER)
    @CollectionTable(name = "farmer_crops", joinColumns = @JoinColumn(name = "farmer_id"))
    @Enumerated(EnumType.STRING)
    @Column(name = "crop_type", nullable = false)
    @Builder.Default
    private Set<CropType> primaryCrops = new HashSet<>();

    @Enumerated(EnumType.STRING)
    @Column(name = "preferred_language", nullable = false)
    @Builder.Default
    private PreferredLanguage preferredLanguage = PreferredLanguage.TA;

    @Column(name = "bank_account_number")
    private String bankAccountNumber;

    @Column(name = "mobile_wallet_number")
    private String mobileWalletNumber;

    @Column(name = "phone_verified", nullable = false)
    @Builder.Default
    private boolean phoneVerified = false;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    @Builder.Default
    private FarmerStatus status = FarmerStatus.PENDING;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
