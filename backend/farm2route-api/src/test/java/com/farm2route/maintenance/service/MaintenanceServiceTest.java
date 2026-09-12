package com.farm2route.maintenance.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.common.enums.MaintenanceStatus;
import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.common.exception.BusinessRuleException;
import com.farm2route.maintenance.dto.CreateMaintenanceRequest;
import com.farm2route.maintenance.dto.UpdateMaintenanceRequest;
import com.farm2route.maintenance.entity.VehicleMaintenance;
import com.farm2route.maintenance.repository.VehicleMaintenanceRepository;
import com.farm2route.vehicle.entity.Vehicle;
import com.farm2route.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MaintenanceServiceTest {
    @Mock VehicleMaintenanceRepository maintenanceRepository;
    @Mock VehicleRepository vehicleRepository;
    @Mock AgencyProfileRepository agencyProfileRepository;

    private MaintenanceService service;
    private UUID userId;
    private UUID vehicleId;
    private AgencyProfile agency;
    private Vehicle vehicle;

    @BeforeEach
    void setUp() {
        service = new MaintenanceService(maintenanceRepository, vehicleRepository, agencyProfileRepository);
        userId = UUID.randomUUID();
        vehicleId = UUID.randomUUID();
        agency = AgencyProfile.builder().id(UUID.randomUUID()).build();
        vehicle = Vehicle.builder().id(vehicleId).agency(agency).status(VehicleStatus.AVAILABLE).build();
        when(agencyProfileRepository.findByUserId(userId)).thenReturn(Optional.of(agency));
        when(vehicleRepository.findByIdAndAgencyId(vehicleId, agency.getId())).thenReturn(Optional.of(vehicle));
    }

    @Test
    void createInProgressMakesVehicleUnavailable() {
        when(maintenanceRepository.save(any(VehicleMaintenance.class))).thenAnswer(invocation -> {
            VehicleMaintenance record = invocation.getArgument(0);
            record.setId(UUID.randomUUID());
            return record;
        });

        var response = service.create(userId, vehicleId, CreateMaintenanceRequest.builder()
                .maintenanceType("ENGINE_REPAIR").title("Engine repair")
                .cost(new BigDecimal("125.50")).maintenanceDate(LocalDate.now())
                .status(MaintenanceStatus.IN_PROGRESS).build());

        assertThat(response.getStatus()).isEqualTo(MaintenanceStatus.IN_PROGRESS);
        assertThat(vehicle.getStatus()).isEqualTo(VehicleStatus.UNDER_MAINTENANCE);
        verify(vehicleRepository).save(vehicle);
    }

    @Test
    void rejectsNextDueDateBeforeMaintenanceDate() {
        assertThatThrownBy(() -> service.create(userId, vehicleId, CreateMaintenanceRequest.builder()
                .maintenanceType("INSPECTION").title("Inspection").cost(BigDecimal.ZERO)
                .maintenanceDate(LocalDate.of(2026, 9, 10))
                .nextDueDate(LocalDate.of(2026, 9, 9)).build()))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Next due date");
        verifyNoInteractions(maintenanceRepository);
    }

    @Test
    void updateRequiresValidStatusTransitionAndChecksAgencyOwnership() {
        UUID recordId = UUID.randomUUID();
        VehicleMaintenance record = VehicleMaintenance.builder()
                .id(recordId).vehicle(vehicle).maintenanceType("SERVICE").title("Service")
                .cost(BigDecimal.TEN).maintenanceDate(LocalDate.now())
                .status(MaintenanceStatus.COMPLETED).build();
        when(maintenanceRepository.findById(recordId)).thenReturn(Optional.of(record));

        assertThatThrownBy(() -> service.update(userId, recordId, UpdateMaintenanceRequest.builder()
                .status(MaintenanceStatus.IN_PROGRESS).build()))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Invalid maintenance status transition");
        verify(maintenanceRepository, never()).save(any());
    }
}
