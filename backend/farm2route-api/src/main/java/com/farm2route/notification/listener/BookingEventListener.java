package com.farm2route.notification.listener;

import com.farm2route.common.event.*;
import com.farm2route.config.RabbitMQConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;

/**
 * RabbitMQ consumer for the notification.queue.
 *
 * Routing keys consumed (bound in RabbitMQConfig):
 *   booking.created, booking.cancelled, incident.submitted, pod.confirmed, review.submitted, vehicle.kyc_updated, package.created
 *
 * Idempotency: each handler calls idempotentHelper.tryMarkProcessed() FIRST.
 * If the event was already processed (duplicate delivery), it returns false and the
 * handler returns immediately without performing the side effect again.
 *
 * Current implementation: structured logging as a notification stub.
 * TODO (future): integrate with actual push notification service (FCM / Twilio)
 * or the in-app notification table to send real alerts to users.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class BookingEventListener {

    private final IdempotentConsumerHelper idempotentHelper;

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleBookingCreated(@Payload BookingCreatedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;

        log.info("[NOTIFICATION] booking.created \u2014 bookingId={} bookingNumber={} farmerId={} agencyId={}",
                event.getBookingId(), event.getBookingNumber(), event.getFarmerId(), event.getAgencyId());

        // TODO: send push notification to farmer confirming booking, notify agency of new booking
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleBookingCancelled(@Payload BookingCancelledEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;

        log.info("[NOTIFICATION] booking.cancelled \u2014 bookingId={} bookingNumber={} reason='{}'",
                event.getBookingId(), event.getBookingNumber(), event.getCancellationReason());

        // TODO: notify agency (and driver if assigned) that booking was cancelled
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleIncidentSubmitted(@Payload IncidentSubmittedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;

        log.info("[NOTIFICATION] incident.submitted \u2014 incidentId={} bookingId={} type={} title='{}'",
                event.getIncidentId(), event.getBookingId(), event.getIncidentType(), event.getTitle());

        // TODO: alert admin queue / ops team of new incident
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handlePodConfirmed(@Payload PodConfirmedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;

        log.info("[NOTIFICATION] pod.confirmed \u2014 podId={} bookingId={} confirmedAt={}",
                event.getPodId(), event.getBookingId(), event.getConfirmedAt());

        // TODO: notify farmer delivery confirmed; notify agency POD received
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleReviewSubmitted(@Payload ReviewSubmittedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;

        log.info("[NOTIFICATION] review.submitted \u2014 reviewId={} bookingId={} agencyId={} agencyRating={}",
                event.getReviewId(), event.getBookingId(), event.getAgencyId(), event.getAgencyRating());

        // TODO: notify agency of new review with rating
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handleVehicleKycUpdated(@Payload VehicleKycUpdatedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;

        log.info("[NOTIFICATION] vehicle.kyc_updated \u2014 vehicleId={} agencyId={} kycStatus={}",
                event.getVehicleId(), event.getAgencyId(), event.getKycStatus());

        // TODO: notify agency of vehicle KYC status update
    }

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handlePackageCreated(@Payload PackageCreatedEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;

        log.info("[NOTIFICATION] package.created \u2014 packageId={} agencyId={} title='{}'",
                event.getPackageId(), event.getAgencyId(), event.getTitle());

        // TODO: notify subscribed farmers or agency confirmation of new package
    }
}
