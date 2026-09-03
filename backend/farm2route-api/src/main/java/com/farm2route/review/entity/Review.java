package com.farm2route.review.entity;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.auth.entity.User;
import com.farm2route.booking.entity.Booking;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.farmer.entity.FarmerProfile;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "reviews")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Review {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "booking_id", nullable = false, unique = true)
    private Booking booking;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "farmer_id", nullable = false)
    private FarmerProfile farmer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "agency_id", nullable = false)
    private AgencyProfile agency;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "driver_id")
    private DriverProfile driver;

    @Column(name = "agency_rating", nullable = false)
    private Integer agencyRating;

    @Column(name = "driver_rating")
    private Integer driverRating;

    @Column(name = "comment")
    private String comment;

    @Column(name = "agency_comment")
    private String agencyComment;

    @Column(name = "driver_comment")
    private String driverComment;

    @Column(name = "agency_response")
    private String agencyResponse;

    @Column(name = "agency_responded_at")
    private Instant agencyRespondedAt;

    @Column(name = "moderation_status", nullable = false, length = 30)
    @Builder.Default
    private String moderationStatus = "APPROVED";

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "moderated_by_admin_id")
    private User moderatedByAdmin;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
