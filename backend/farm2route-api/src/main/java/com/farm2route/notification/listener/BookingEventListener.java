package com.farm2route.notification.listener;

import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.NotificationType;
import com.farm2route.common.event.*;
import com.farm2route.config.RabbitMQConfig;
import com.farm2route.notification.service.NotificationService;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;

import java.util.UUID;

/** Persists recipient-scoped in-app notifications for existing RabbitMQ events. */
@Component
public class BookingEventListener {
    private final IdempotentConsumerHelper idempotentHelper;
    private final NotificationService notificationService;
    private final BookingRepository bookingRepository;

    public BookingEventListener(IdempotentConsumerHelper idempotentHelper) {
        this(idempotentHelper, null, null);
    }

    @Autowired
    public BookingEventListener(IdempotentConsumerHelper idempotentHelper, NotificationService notificationService,
                                BookingRepository bookingRepository) {
        this.idempotentHelper = idempotentHelper;
        this.notificationService = notificationService;
        this.bookingRepository = bookingRepository;
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleBookingCreated(@Payload BookingCreatedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;
        notifyAgency(event.getAgencyId(), NotificationType.BOOKING_UPDATE, "New booking received",
                "Booking " + event.getBookingNumber() + " has been received.", "BOOKING", event.getBookingId());
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleBookingCancelled(@Payload BookingCancelledEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;
        notifyAgency(event.getAgencyId(), NotificationType.BOOKING_UPDATE, "Booking cancelled",
                "Booking " + event.getBookingNumber() + " was cancelled.", "BOOKING", event.getBookingId());
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleIncidentSubmitted(@Payload IncidentSubmittedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handlePodConfirmed(@Payload PodConfirmedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;
        notifyAgencyForBooking(event.getBookingId(), NotificationType.POD_SUBMITTED, "Delivery confirmed",
                "Proof of delivery was confirmed for the booking.", "BOOKING", event.getBookingId());
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleReviewSubmitted(@Payload ReviewSubmittedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;
        notifyAgency(event.getAgencyId(), NotificationType.SYSTEM, "New review received",
                "A farmer submitted a review with rating " + event.getAgencyRating() + ".", "REVIEW", event.getReviewId());
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleVehicleKycUpdated(@Payload VehicleKycUpdatedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;
        notifyAgency(event.getAgencyId(), NotificationType.KYC_STATUS, "Vehicle KYC updated",
                "Vehicle KYC status changed to " + event.getKycStatus() + ".", "VEHICLE", event.getVehicleId());
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handlePackageCreated(@Payload PackageCreatedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleDriverAssigned(@Payload DriverAssignedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;
        notifyAgencyForBooking(event.getBookingId(), NotificationType.TRIP_DISPATCH, "Trip assigned",
                "A driver and vehicle were assigned to a booking.", "TRIP", event.getAssignmentId());
    }

    private void notifyAgency(UUID agencyId, NotificationType type, String title, String message,
                              String referenceType, UUID referenceId) {
        if (notificationService != null && agencyId != null) {
            notificationService.createForAgency(agencyId, type, title, message, referenceType, referenceId);
        }
    }

    private void notifyAgencyForBooking(UUID bookingId, NotificationType type, String title, String message,
                                        String referenceType, UUID referenceId) {
        if (notificationService == null || bookingRepository == null || bookingId == null) return;
        bookingRepository.findById(bookingId).ifPresent(booking -> {
            if (booking.getAgency() != null) {
                notifyAgency(booking.getAgency().getId(), type, title, message, referenceType, referenceId);
            }
        });
    }
}
