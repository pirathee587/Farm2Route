package com.farm2route.notification.listener;

import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.common.enums.NotificationType;
import com.farm2route.common.event.*;
import com.farm2route.config.RabbitMQConfig;
import com.farm2route.farmer.repository.FarmerProfileRepository;
import com.farm2route.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.util.UUID;

/**
 * RabbitMQ consumer for the notification.queue.
 *
 * Routing keys consumed (bound in RabbitMQConfig):
 *   booking.created, booking.cancelled, incident.submitted, pod.confirmed, review.submitted, vehicle.kyc_updated, package.created
 *
 * Idempotency: each handler calls idempotentHelper.tryMarkProcessed(event.getEventId(), CONSUMER_NAME) FIRST.
 * If the event was already processed (duplicate delivery), it returns false and the
 * handler returns immediately without performing the side effect again.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class NotificationEventListener {

    public static final String CONSUMER_NAME = "notification-service";

    private final IdempotentConsumerHelper idempotentHelper;
    private final NotificationService notificationService;
    private final AgencyProfileRepository agencyProfileRepository;
    private final FarmerProfileRepository farmerProfileRepository;

    @Value("${app.admin.notification-user-ids:}")
    private String adminUserIdsConfig;

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleBookingCreated(@Payload BookingCreatedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId(), CONSUMER_NAME)) return;

        log.info("[NOTIFICATION] booking.created — bookingId={} bookingNumber={} farmerId={} agencyId={}",
                event.getBookingId(), event.getBookingNumber(), event.getFarmerId(), event.getAgencyId());

        UUID farmerUserId = resolveFarmerUserId(event.getFarmerId());
        if (farmerUserId != null) {
            notificationService.create(
                    farmerUserId,
                    NotificationType.BOOKING_UPDATE,
                    "Booking Confirmed",
                    "Your booking " + event.getBookingNumber() + " has been created.",
                    "BOOKING",
                    event.getBookingId()
            );
        }

        UUID agencyUserId = resolveAgencyUserId(event.getAgencyId());
        if (agencyUserId != null) {
            notificationService.create(
                    agencyUserId,
                    NotificationType.BOOKING_UPDATE,
                    "New Booking Received",
                    "New booking " + event.getBookingNumber() + " received.",
                    "BOOKING",
                    event.getBookingId()
            );
        }
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleBookingCancelled(@Payload BookingCancelledEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId(), CONSUMER_NAME)) return;

        log.info("[NOTIFICATION] booking.cancelled — bookingId={} bookingNumber={} reason='{}'",
                event.getBookingId(), event.getBookingNumber(), event.getCancellationReason());

        UUID farmerUserId = resolveFarmerUserId(event.getFarmerId());
        if (farmerUserId != null) {
            notificationService.create(
                    farmerUserId,
                    NotificationType.BOOKING_UPDATE,
                    "Booking Cancelled",
                    "Booking " + event.getBookingNumber() + " was cancelled.",
                    "BOOKING",
                    event.getBookingId()
            );
        }

        UUID agencyUserId = resolveAgencyUserId(event.getAgencyId());
        if (agencyUserId != null) {
            String reasonStr = StringUtils.hasText(event.getCancellationReason())
                    ? " Reason: " + event.getCancellationReason()
                    : "";
            notificationService.create(
                    agencyUserId,
                    NotificationType.BOOKING_UPDATE,
                    "Booking Cancelled",
                    "Booking " + event.getBookingNumber() + " was cancelled." + reasonStr,
                    "BOOKING",
                    event.getBookingId()
            );
        }
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleIncidentSubmitted(@Payload IncidentSubmittedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId(), CONSUMER_NAME)) return;

        log.info("[NOTIFICATION] incident.submitted — incidentId={} bookingId={} type={} title='{}'",
                event.getIncidentId(), event.getBookingId(), event.getIncidentType(), event.getTitle());

        // NOTE: Configurable admin distribution list used for MVP. In post-MVP, query all users with ADMIN role from UserRepository.
        if (StringUtils.hasText(adminUserIdsConfig)) {
            String[] ids = adminUserIdsConfig.split(",");
            for (String idStr : ids) {
                try {
                    UUID adminUserId = UUID.fromString(idStr.trim());
                    notificationService.create(
                            adminUserId,
                            NotificationType.INCIDENT_ALERT,
                            "New Incident Reported: " + event.getTitle(),
                            "Incident reported for booking " + event.getBookingId() + ": " + event.getTitle(),
                            "INCIDENT",
                            event.getIncidentId()
                    );
                } catch (IllegalArgumentException e) {
                    log.warn("Invalid admin notification user ID in config: '{}'", idStr);
                }
            }
        }
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handlePodConfirmed(@Payload PodConfirmedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId(), CONSUMER_NAME)) return;

        log.info("[NOTIFICATION] pod.confirmed — podId={} bookingId={} confirmedAt={}",
                event.getPodId(), event.getBookingId(), event.getConfirmedAt());

        UUID farmerUserId = resolveFarmerUserId(event.getFarmerId());
        if (farmerUserId != null) {
            notificationService.create(
                    farmerUserId,
                    NotificationType.POD_SUBMITTED,
                    "Delivery Confirmed",
                    "Proof of delivery confirmed for booking " + event.getBookingId(),
                    "BOOKING",
                    event.getBookingId()
            );
        }

        UUID agencyUserId = resolveAgencyUserId(event.getAgencyId());
        if (agencyUserId != null) {
            notificationService.create(
                    agencyUserId,
                    NotificationType.POD_SUBMITTED,
                    "POD Confirmed",
                    "Proof of delivery confirmed for booking " + event.getBookingId(),
                    "BOOKING",
                    event.getBookingId()
            );
        }
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleReviewSubmitted(@Payload ReviewSubmittedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId(), CONSUMER_NAME)) return;

        log.info("[NOTIFICATION] review.submitted — reviewId={} bookingId={} agencyId={} agencyRating={}",
                event.getReviewId(), event.getBookingId(), event.getAgencyId(), event.getAgencyRating());

        UUID agencyUserId = resolveAgencyUserId(event.getAgencyId());
        if (agencyUserId != null) {
            notificationService.create(
                    agencyUserId,
                    NotificationType.SYSTEM,
                    "New Review Submitted",
                    "A new review with rating " + event.getAgencyRating() + " stars was submitted for booking " + event.getBookingId(),
                    "BOOKING",
                    event.getBookingId()
            );
        }
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleVehicleKycUpdated(@Payload VehicleKycUpdatedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId(), CONSUMER_NAME)) return;

        log.info("[NOTIFICATION] vehicle.kyc_updated — vehicleId={} agencyId={} kycStatus={}",
                event.getVehicleId(), event.getAgencyId(), event.getKycStatus());

        UUID agencyUserId = resolveAgencyUserId(event.getAgencyId());
        if (agencyUserId != null) {
            notificationService.create(
                    agencyUserId,
                    NotificationType.KYC_STATUS,
                    "Vehicle KYC Updated",
                    "Vehicle KYC status updated to " + event.getKycStatus(),
                    "VEHICLE",
                    event.getVehicleId()
            );
        }
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handlePackageCreated(@Payload PackageCreatedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId(), CONSUMER_NAME)) return;

        log.info("[NOTIFICATION] package.created — packageId={} agencyId={} title='{}'",
                event.getPackageId(), event.getAgencyId(), event.getTitle());

        UUID agencyUserId = resolveAgencyUserId(event.getAgencyId());
        if (agencyUserId != null) {
            notificationService.create(
                    agencyUserId,
                    NotificationType.SYSTEM,
                    "Transport Package Created",
                    "Transport package '" + event.getTitle() + "' created successfully",
                    "PACKAGE",
                    event.getPackageId()
            );
        }
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleKycReviewed(@Payload KycReviewedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId(), CONSUMER_NAME)) return;

        log.info("[NOTIFICATION] kyc.reviewed — entityType={} entityId={} ownerUserId={} status={}",
                event.getEntityType(), event.getEntityId(), event.getOwnerUserId(), event.getStatus());

        if (event.getOwnerUserId() != null) {
            String reasonMsg = StringUtils.hasText(event.getRejectionReason())
                    ? ". Reason: " + event.getRejectionReason()
                    : "";
            notificationService.create(
                    event.getOwnerUserId(),
                    NotificationType.KYC_STATUS,
                    "KYC Status Updated",
                    "Your " + event.getEntityType().toLowerCase() + " KYC status has been updated to " + event.getStatus() + reasonMsg,
                    "KYC",
                    event.getEntityId()
            );
        }
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleTripArrived(@Payload TripArrivedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId(), CONSUMER_NAME)) return;

        log.info("[NOTIFICATION] trip.arrived — tripId={} bookingId={} farmerUserId={}",
                event.getTripId(), event.getBookingId(), event.getFarmerUserId());

        if (event.getFarmerUserId() != null) {
            notificationService.create(
                    event.getFarmerUserId(),
                    NotificationType.SYSTEM,
                    "Vehicle Arrived at Delivery",
                    "The transport vehicle for booking " + event.getBookingId() + " has arrived at the delivery location.",
                    "TRIP",
                    event.getTripId()
            );
        }
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleIncidentStatusChanged(@Payload IncidentStatusChangedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId(), CONSUMER_NAME)) return;

        log.info("[NOTIFICATION] incident.status_changed — incidentId={} oldStatus={} newStatus={}",
                event.getIncidentId(), event.getOldStatus(), event.getNewStatus());

        if (event.getReporterUserId() != null) {
            notificationService.create(
                    event.getReporterUserId(),
                    NotificationType.INCIDENT_ALERT,
                    "Incident Status Updated",
                    "Your reported incident status changed to " + event.getNewStatus(),
                    "INCIDENT",
                    event.getIncidentId()
            );
        }
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleIncidentEscalated(@Payload IncidentEscalatedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId(), CONSUMER_NAME)) return;

        log.info("[NOTIFICATION] incident.escalated — incidentId={} adminId={}",
                event.getIncidentId(), event.getAdminId());

        if (event.getReporterUserId() != null) {
            notificationService.create(
                    event.getReporterUserId(),
                    NotificationType.INCIDENT_ALERT,
                    "Incident Escalated for Priority Review",
                    "Your reported incident has been escalated for administrative review.",
                    "INCIDENT",
                    event.getIncidentId()
            );
        }
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleReviewModerated(@Payload ReviewModeratedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId(), CONSUMER_NAME)) return;

        log.info("[NOTIFICATION] review.moderated — reviewId={} action={} farmerUserId={}",
                event.getReviewId(), event.getAction(), event.getFarmerUserId());

        if ("HIDE".equalsIgnoreCase(event.getAction()) && event.getFarmerUserId() != null) {
            String reasonMsg = StringUtils.hasText(event.getReason())
                    ? " Reason: " + event.getReason()
                    : "";
            notificationService.create(
                    event.getFarmerUserId(),
                    NotificationType.SYSTEM,
                    "Review Hidden",
                    "Your review has been hidden by a moderator." + reasonMsg,
                    "REVIEW",
                    event.getReviewId()
            );
        }
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handlePodSubmitted(@Payload PodSubmittedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId(), CONSUMER_NAME)) return;

        log.info("[NOTIFICATION] pod.submitted — podId={} bookingId={} farmerUserId={}",
                event.getPodId(), event.getBookingId(), event.getFarmerUserId());

        if (event.getFarmerUserId() != null) {
            notificationService.create(
                    event.getFarmerUserId(),
                    NotificationType.POD_SUBMITTED,
                    "Proof of Delivery Submitted",
                    "Driver submitted Proof of Delivery for booking " + event.getBookingId() + ". Please confirm delivery.",
                    "POD",
                    event.getPodId()
            );
        }
    }

    private UUID resolveAgencyUserId(UUID agencyId) {
        if (agencyId == null) return null;
        return agencyProfileRepository.findById(agencyId)
                .map(ap -> ap.getUser().getId())
                .orElseGet(() -> agencyProfileRepository.findByUserId(agencyId)
                        .map(ap -> ap.getUser().getId())
                        .orElse(agencyId));
    }

    private UUID resolveFarmerUserId(UUID farmerId) {
        if (farmerId == null) return null;
        return farmerProfileRepository.findById(farmerId)
                .map(fp -> fp.getUser().getId())
                .orElseGet(() -> farmerProfileRepository.findByUserId(farmerId)
                        .map(fp -> fp.getUser().getId())
                        .orElse(farmerId));
    }
}
