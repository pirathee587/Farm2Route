package com.farm2route.maintenance.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.common.enums.MaintenanceStatus;
import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.common.event.IdempotentConsumerHelper;
import com.farm2route.maintenance.entity.VehicleMaintenance;
import com.farm2route.maintenance.repository.VehicleMaintenanceRepository;
import com.farm2route.notification.service.NotificationService;
import com.farm2route.vehicle.entity.Vehicle;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MaintenanceDueAlertProcessorTest {
    @Mock VehicleMaintenanceRepository maintenanceRepository;
    @Mock NotificationService notificationService;
    @Mock IdempotentConsumerHelper idempotentConsumerHelper;

    private MaintenanceDueAlertProcessor processor;
    private LocalDate today;

    @BeforeEach
    void setUp() {
        processor = new MaintenanceDueAlertProcessor(maintenanceRepository, notificationService, idempotentConsumerHelper);
        today = LocalDate.of(2026, 9, 8);
    }

    @Test
    void generatesAgencyAlertForDueMaintenanceAndDoesNotChangeVehicleStatus() {
        UUID agencyId = UUID.randomUUID();
        AgencyProfile agency = AgencyProfile.builder().id(agencyId).build();
        Vehicle vehicle = Vehicle.builder().id(UUID.randomUUID()).agency(agency).status(VehicleStatus.AVAILABLE).build();
        VehicleMaintenance maintenance = VehicleMaintenance.builder().id(UUID.randomUUID()).vehicle(vehicle)
                .title("Oil service").nextDueDate(today).status(MaintenanceStatus.SCHEDULED).build();
        when(maintenanceRepository.findDueForNotification(eq(today), anyList())).thenReturn(List.of(maintenance));
        when(maintenanceRepository.findByIdForUpdate(maintenance.getId())).thenReturn(Optional.of(maintenance));
        when(idempotentConsumerHelper.tryMarkProcessed(any())).thenReturn(true);

        assertThat(processor.processDueAlerts(today)).isEqualTo(1);

        assertThat(vehicle.getStatus()).isEqualTo(VehicleStatus.AVAILABLE);
        verify(notificationService).createForAgency(eq(agencyId), any(), eq("Vehicle service due"),
                contains("Oil service"), eq("MAINTENANCE"), eq(maintenance.getId()));
    }

    @Test
    void onlyQueriesAlertableStatuses() {
        when(maintenanceRepository.findDueForNotification(eq(today), anyList())).thenReturn(List.of());

        assertThat(processor.processDueAlerts(today)).isZero();

        verify(maintenanceRepository).findDueForNotification(eq(today),
                argThat(statuses -> statuses.contains(MaintenanceStatus.SCHEDULED)
                        && statuses.contains(MaintenanceStatus.IN_PROGRESS)
                        && !statuses.contains(MaintenanceStatus.COMPLETED)
                        && !statuses.contains(MaintenanceStatus.CANCELLED)));
        verifyNoInteractions(notificationService);
    }

    @Test
    void skipsMaintenanceThatIsNoLongerDueAfterLocking() {
        VehicleMaintenance candidate = VehicleMaintenance.builder().id(UUID.randomUUID())
                .title("Inspection").nextDueDate(today.minusDays(1)).status(MaintenanceStatus.SCHEDULED).build();
        VehicleMaintenance updated = VehicleMaintenance.builder().id(candidate.getId())
                .title("Inspection").nextDueDate(today.plusDays(10)).status(MaintenanceStatus.SCHEDULED).build();
        when(maintenanceRepository.findDueForNotification(eq(today), anyList())).thenReturn(List.of(candidate));
        when(maintenanceRepository.findByIdForUpdate(candidate.getId())).thenReturn(Optional.of(updated));

        assertThat(processor.processDueAlerts(today)).isZero();
        verifyNoInteractions(notificationService);
    }

    @Test
    void doesNotDuplicateAlertWhenIdempotencyClaimIsLost() {
        AgencyProfile agency = AgencyProfile.builder().id(UUID.randomUUID()).build();
        Vehicle vehicle = Vehicle.builder().id(UUID.randomUUID()).agency(agency).build();
        VehicleMaintenance maintenance = VehicleMaintenance.builder().id(UUID.randomUUID()).vehicle(vehicle)
                .title("Brake service").nextDueDate(today.minusDays(1)).status(MaintenanceStatus.IN_PROGRESS).build();
        when(maintenanceRepository.findDueForNotification(eq(today), anyList())).thenReturn(List.of(maintenance));
        when(maintenanceRepository.findByIdForUpdate(maintenance.getId())).thenReturn(Optional.of(maintenance));
        when(idempotentConsumerHelper.tryMarkProcessed(any())).thenReturn(false);

        assertThat(processor.processDueAlerts(today)).isZero();
        verify(notificationService, never()).createForAgency(any(), any(), any(), any(), any(), any());
    }
}
