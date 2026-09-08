package com.farm2route.pod.entity;

import com.farm2route.booking.entity.Booking;
import com.farm2route.common.enums.PodConfirmationStatus;
import com.farm2route.driver.entity.DriverProfile;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "pod_records", indexes = {
        @Index(name = "idx_pod_booking", columnList = "booking_id"),
        @Index(name = "idx_pod_driver", columnList = "driver_id")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PodRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "booking_id", nullable = false, unique = true)
    private Booking booking;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "driver_id", nullable = false)
    private DriverProfile driver;

    @Column(name = "recipient_name", nullable = false, length = 150)
    private String recipientName;

    @Column(name = "recipient_phone", nullable = false, length = 30)
    private String recipientPhone;

    @Column(name = "recipient_signature_url", nullable = false, length = 500)
    private String recipientSignatureUrl;

    @Column(name = "delivery_photo_url", nullable = false, length = 500)
    private String deliveryPhotoUrl;

    @Column(name = "delivery_latitude", precision = 10, scale = 8, nullable = false)
    private BigDecimal deliveryLatitude;

    @Column(name = "delivery_longitude", precision = 11, scale = 8, nullable = false)
    private BigDecimal deliveryLongitude;

    @Column(name = "delivery_timestamp", nullable = false)
    @Builder.Default
    private Instant deliveryTimestamp = Instant.now();

    @Enumerated(EnumType.STRING)
    @Column(name = "farmer_confirmation_status", nullable = false, length = 30)
    @Builder.Default
    private PodConfirmationStatus farmerConfirmationStatus = PodConfirmationStatus.PENDING;

    @Column(name = "farmer_confirmed_at")
    private Instant farmerConfirmedAt;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
}
