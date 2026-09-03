package com.farm2route.booking.entity;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.auth.entity.User;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.farmer.entity.FarmerProfile;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "bookings")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Booking {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "booking_number", nullable = false, unique = true)
    private String bookingNumber;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "farmer_id", nullable = false)
    private FarmerProfile farmer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "agency_id", nullable = false)
    private AgencyProfile agency;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "driver_id")
    private DriverProfile driver;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "package_id")
    private com.farm2route.catalog.entity.TransportPackage transportPackage;

    @Column(name = "pickup_address", nullable = false)
    private String pickupAddress;

    @Column(name = "pickup_latitude", precision = 10, scale = 8, nullable = false)
    private BigDecimal pickupLatitude;

    @Column(name = "pickup_longitude", precision = 11, scale = 8, nullable = false)
    private BigDecimal pickupLongitude;

    @Column(name = "pickup_contact_name")
    private String pickupContactName;

    @Column(name = "pickup_contact_phone")
    private String pickupContactPhone;

    @Column(name = "delivery_address", nullable = false)
    private String deliveryAddress;

    @Column(name = "delivery_latitude", precision = 10, scale = 8, nullable = false)
    private BigDecimal deliveryLatitude;

    @Column(name = "delivery_longitude", precision = 11, scale = 8, nullable = false)
    private BigDecimal deliveryLongitude;

    @Column(name = "recipient_name", nullable = false)
    private String recipientName;

    @Column(name = "recipient_phone", nullable = false)
    private String recipientPhone;

    @Column(name = "cargo_type", nullable = false)
    private String cargoType;

    @Column(name = "cargo_weight_kg", precision = 10, scale = 2, nullable = false)
    private BigDecimal cargoWeightKg;

    @Column(name = "cargo_volume_cbm", precision = 10, scale = 2)
    private BigDecimal cargoVolumeCbm;

    @Column(name = "is_fragile", nullable = false)
    @Builder.Default
    private boolean isFragile = false;

    @Column(name = "requires_refrigeration", nullable = false)
    @Builder.Default
    private boolean requiresRefrigeration = false;

    @Column(name = "special_instructions")
    private String specialInstructions;

    @Column(name = "estimated_distance_km", precision = 10, scale = 2)
    private BigDecimal estimatedDistanceKm;

    @Column(name = "total_amount", precision = 10, scale = 2, nullable = false)
    private BigDecimal totalAmount;

    @Column(name = "commission_amount", precision = 10, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal commissionAmount = BigDecimal.ZERO;

    @Column(name = "agency_earnings", precision = 10, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal agencyEarnings = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private BookingStatus status = BookingStatus.PENDING;

    @Column(name = "scheduled_pickup_at", nullable = false)
    private Instant scheduledPickupAt;

    @Column(name = "actual_pickup_at")
    private Instant actualPickupAt;

    @Column(name = "actual_delivery_at")
    private Instant actualDeliveryAt;

    @Column(name = "cancellation_reason")
    private String cancellationReason;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cancelled_by")
    private User cancelledBy;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
