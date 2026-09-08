package com.farm2route.maintenance.service;

import com.farm2route.common.enums.MaintenanceStatus;
import com.farm2route.common.enums.NotificationType;
import com.farm2route.common.event.IdempotentConsumerHelper;
import com.farm2route.maintenance.entity.VehicleMaintenance;
import com.farm2route.maintenance.repository.VehicleMaintenanceRepository;
import com.farm2route.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class MaintenanceDueAlertProcessor {
    private static final List<MaintenanceStatus> ALERTABLE_STATUSES =
            List.of(MaintenanceStatus.SCHEDULED, MaintenanceStatus.IN_PROGRESS);

    private final VehicleMaintenanceRepository maintenanceRepository;
    private final NotificationService notificationService;
    private final IdempotentConsumerHelper idempotentConsumerHelper;

    @Scheduled(
            fixedDelayString = "${farm2route.maintenance.due-check-interval-ms:3600000}",
            initialDelayString = "${farm2route.maintenance.due-initial-delay-ms:60000}")
    public void scheduledProcess() {
        processDueAlerts(LocalDate.now());
    }

    @Transactional
    public int processDueAlerts(LocalDate today) {
        List<VehicleMaintenance> candidates = maintenanceRepository.findDueForNotification(today, ALERTABLE_STATUSES);
        int generated = 0;
        for (VehicleMaintenance candidate : candidates) {
            VehicleMaintenance maintenance = maintenanceRepository.findByIdForUpdate(candidate.getId()).orElse(null);
            if (maintenance == null || maintenance.getNextDueDate() == null
                    || maintenance.getNextDueDate().isAfter(today)
                    || !ALERTABLE_STATUSES.contains(maintenance.getStatus())) continue;

            UUID notificationKey = UUID.nameUUIDFromBytes(
                    ("maintenance-due:" + maintenance.getId()).getBytes(StandardCharsets.UTF_8));
            if (idempotentConsumerHelper.tryMarkProcessed(notificationKey)) {
                notificationService.createForAgency(maintenance.getVehicle().getAgency().getId(),
                        NotificationType.SYSTEM, "Vehicle service due",
                        "Vehicle maintenance is due for " + maintenance.getTitle() + ".", "MAINTENANCE",
                        maintenance.getId());
                generated++;
            }
        }
        log.info("Maintenance due processing completed: candidates={}, alertsGenerated={}", candidates.size(), generated);
        return generated;
    }
}
