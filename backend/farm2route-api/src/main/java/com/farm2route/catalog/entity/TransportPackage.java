package com.farm2route.catalog.entity;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.common.enums.PackageType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "packages")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransportPackage {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "agency_id", nullable = false)
    private AgencyProfile agency;

    @Column(nullable = false, length = 150)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "package_type", nullable = false, length = 50)
    private PackageType packageType;

    @Column(name = "base_price", precision = 10, scale = 2, nullable = false)
    private BigDecimal basePrice;

    @Column(name = "price_per_km", precision = 10, scale = 2, nullable = false)
    private BigDecimal pricePerKm;

    @Column(name = "price_per_kg", precision = 10, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal pricePerKg = BigDecimal.ZERO;

    @Column(name = "max_weight_kg", precision = 10, scale = 2, nullable = false)
    private BigDecimal maxWeightKg;

    @Column(name = "route_origin", length = 100)
    private String routeOrigin;

    @Column(name = "route_destination", length = 100)
    private String routeDestination;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "schedule_days")
    @Builder.Default
    private List<String> scheduleDays = new ArrayList<>();

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private boolean isActive = true;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
