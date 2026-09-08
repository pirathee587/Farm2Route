package com.farm2route.admin.service;

import com.farm2route.admin.dto.AdminStatsDto;
import com.farm2route.admin.dto.KycApprovalDto;
import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.audit.service.AuditService;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.event.KycReviewedEvent;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.driver.repository.DriverProfileRepository;
import com.farm2route.incident.repository.IncidentRepository;
import com.farm2route.vehicle.entity.Vehicle;
import com.farm2route.vehicle.repository.VehicleRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdminServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private AgencyProfileRepository agencyProfileRepository;

    @Mock
    private DriverProfileRepository driverProfileRepository;

    @Mock
    private VehicleRepository vehicleRepository;

    @Mock
    private BookingRepository bookingRepository;

    @Mock
    private IncidentRepository incidentRepository;

    @Mock
    private AuditService auditService;

    @Spy
    private ObjectMapper objectMapper = new ObjectMapper();

    @Mock
    private ApplicationEventPublisher applicationEventPublisher;

    @InjectMocks
    private AdminService adminService;

    private UUID agencyUserId;
    private UUID agencyId;
    private UUID driverId;
    private UUID vehicleId;
    private AgencyProfile agencyProfile;
    private DriverProfile driverProfile;
    private Vehicle vehicle;

    @BeforeEach
    void setUp() {
        agencyUserId = UUID.randomUUID();
        agencyId = UUID.randomUUID();
        driverId = UUID.randomUUID();
        vehicleId = UUID.randomUUID();

        User agencyUser = User.builder().id(agencyUserId).role(Role.AGENCY).build();
        agencyProfile = AgencyProfile.builder().id(agencyId).user(agencyUser).kycStatus(KycStatus.PENDING).build();
        driverProfile = DriverProfile.builder().id(driverId).user(User.builder().id(UUID.randomUUID()).build()).kycStatus(KycStatus.PENDING).build();
        vehicle = Vehicle.builder().id(vehicleId).agency(agencyProfile).kycStatus(KycStatus.PENDING_APPROVAL).build();
    }

    @Test
    @DisplayName("getDashboardStats aggregates counts from repositories")
    void testGetDashboardStats_Success() {
        when(userRepository.count()).thenReturn(10L);
        when(userRepository.findByRole(Role.FARMER)).thenReturn(List.of(mock(User.class), mock(User.class), mock(User.class), mock(User.class)));
        when(userRepository.findByRole(Role.AGENCY)).thenReturn(List.of(mock(User.class), mock(User.class), mock(User.class)));
        when(userRepository.findByRole(Role.DRIVER)).thenReturn(List.of(mock(User.class), mock(User.class)));

        when(agencyProfileRepository.countByKycStatusIn(anyList())).thenReturn(2L);
        when(driverProfileRepository.countByKycStatusIn(anyList())).thenReturn(1L);
        when(vehicleRepository.countByKycStatusIn(anyList())).thenReturn(3L);

        when(bookingRepository.countByStatusNotIn(anyList())).thenReturn(5L);
        when(incidentRepository.countByStatusIn(anyList())).thenReturn(2L);

        AdminStatsDto stats = adminService.getDashboardStats();

        assertThat(stats).isNotNull();
        assertThat(stats.getTotalUsers()).isEqualTo(10L);
        assertThat(stats.getTotalFarmers()).isEqualTo(4L);
        assertThat(stats.getTotalAgencies()).isEqualTo(3L);
        assertThat(stats.getTotalDrivers()).isEqualTo(2L);
        assertThat(stats.getPendingKycs()).isEqualTo(6L); // 2 + 1 + 3
        assertThat(stats.getActiveBookings()).isEqualTo(5L);
        assertThat(stats.getOpenIncidents()).isEqualTo(2L);
    }

    @Test
    @DisplayName("reviewVehicleKyc approves vehicle KYC and publishes KycReviewedEvent")
    void testReviewVehicleKyc_Approved_Success() {
        KycApprovalDto dto = KycApprovalDto.builder()
                .entityId(vehicleId)
                .status(KycStatus.APPROVED)
                .build();

        when(vehicleRepository.findById(vehicleId)).thenReturn(Optional.of(vehicle));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(i -> i.getArgument(0));

        adminService.reviewVehicleKyc(dto);

        assertThat(vehicle.getKycStatus()).isEqualTo(KycStatus.APPROVED);
        assertThat(vehicle.getVerifiedAt()).isNotNull();

        verify(vehicleRepository, times(1)).save(vehicle);

        ArgumentCaptor<KycReviewedEvent> captor = ArgumentCaptor.forClass(KycReviewedEvent.class);
        verify(applicationEventPublisher, times(1)).publishEvent(captor.capture());
        KycReviewedEvent publishedEvent = captor.getValue();
        assertThat(publishedEvent.getEntityType()).isEqualTo("VEHICLE");
        assertThat(publishedEvent.getEntityId()).isEqualTo(vehicleId);
        assertThat(publishedEvent.getOwnerUserId()).isEqualTo(agencyUserId);
        assertThat(publishedEvent.getStatus()).isEqualTo(KycStatus.APPROVED);
    }

    @Test
    @DisplayName("reviewVehicleKyc rejects vehicle KYC with reason and publishes event")
    void testReviewVehicleKyc_Rejected_Success() {
        KycApprovalDto dto = KycApprovalDto.builder()
                .entityId(vehicleId)
                .status(KycStatus.REJECTED)
                .rejectionReason("Expired insurance documents")
                .build();

        when(vehicleRepository.findById(vehicleId)).thenReturn(Optional.of(vehicle));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(i -> i.getArgument(0));

        adminService.reviewVehicleKyc(dto);

        assertThat(vehicle.getKycStatus()).isEqualTo(KycStatus.REJECTED);
        assertThat(vehicle.getRejectionReason()).isEqualTo("Expired insurance documents");

        verify(vehicleRepository, times(1)).save(vehicle);

        ArgumentCaptor<KycReviewedEvent> captor = ArgumentCaptor.forClass(KycReviewedEvent.class);
        verify(applicationEventPublisher, times(1)).publishEvent(captor.capture());
        KycReviewedEvent publishedEvent = captor.getValue();
        assertThat(publishedEvent.getStatus()).isEqualTo(KycStatus.REJECTED);
        assertThat(publishedEvent.getRejectionReason()).isEqualTo("Expired insurance documents");
    }

    @Test
    @DisplayName("reviewVehicleKyc throws ResourceNotFoundException when vehicle not found")
    void testReviewVehicleKyc_NotFound_ThrowsResourceNotFoundException() {
        KycApprovalDto dto = KycApprovalDto.builder()
                .entityId(vehicleId)
                .status(KycStatus.APPROVED)
                .build();

        when(vehicleRepository.findById(vehicleId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adminService.reviewVehicleKyc(dto))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Vehicle not found with ID: " + vehicleId);

        verify(vehicleRepository, never()).save(any());
        verify(applicationEventPublisher, never()).publishEvent(any());
    }
}
