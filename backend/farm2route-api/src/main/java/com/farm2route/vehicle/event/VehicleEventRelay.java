package com.farm2route.vehicle.event;

import com.farm2route.common.event.EventPublisher;
import com.farm2route.common.event.VehicleKycUpdatedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Relay between Spring's internal application event bus and RabbitMQ for Vehicle domain events.
 *
 * VehicleService publishes a Spring ApplicationEvent. This relay receives it via
 * @TransactionalEventListener(phase = AFTER_COMMIT), guaranteeing that the message
 * is published to RabbitMQ only after the DB transaction commits.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class VehicleEventRelay {

    private final EventPublisher eventPublisher;

    /**
     * Triggered AFTER the vehicle KYC status update transaction commits.
     * Publishes VehicleKycUpdatedEvent to RabbitMQ routing key "vehicle.kyc_updated".
     */
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onVehicleKycUpdated(VehicleKycUpdatedEvent event) {
        log.info("[VehicleEventRelay] Relaying vehicle.kyc_updated for vehicleId={}, agencyId={}, status={}",
                event.getVehicleId(), event.getAgencyId(), event.getKycStatus());
        eventPublisher.publish(event);
    }
}

