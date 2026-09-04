package com.farm2route.catalog.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.catalog.dto.CreatePackageRequest;
import com.farm2route.catalog.dto.PackageResponse;
import com.farm2route.catalog.dto.UpdatePackageRequest;
import com.farm2route.catalog.entity.TransportPackage;
import com.farm2route.catalog.repository.PackageRepository;
import com.farm2route.common.enums.PackageType;
import com.farm2route.common.event.PackageCreatedEvent;
import com.farm2route.common.exception.ResourceNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PackageServiceTest {

    @Mock
    private PackageRepository packageRepository;

    @Mock
    private AgencyProfileRepository agencyProfileRepository;

    @Mock
    private ApplicationEventPublisher applicationEventPublisher;

    @InjectMocks
    private PackageService packageService;

    private UUID agencyUserId;
    private UUID agencyId;
    private UUID otherAgencyUserId;
    private UUID otherAgencyId;
    private UUID packageId;
    private AgencyProfile agencyProfile;
    private AgencyProfile otherAgencyProfile;
    private TransportPackage samplePackage;
    private CreatePackageRequest createRequest;

    @BeforeEach
    void setUp() {
        agencyUserId = UUID.randomUUID();
        agencyId = UUID.randomUUID();
        otherAgencyUserId = UUID.randomUUID();
        otherAgencyId = UUID.randomUUID();
        packageId = UUID.randomUUID();

        agencyProfile = AgencyProfile.builder()
                .id(agencyId)
                .companyName("Green Route Logistics")
                .contactPersonPhone("+94771234567")
                .build();

        otherAgencyProfile = AgencyProfile.builder()
                .id(otherAgencyId)
                .companyName("Other Logistics")
                .build();

        createRequest = CreatePackageRequest.builder()
                .title("Standard Vegetable Transport")
                .description("Daily vegetable route")
                .packageType(PackageType.WEIGHT_BASED)
                .basePrice(new BigDecimal("1500.00"))
                .pricePerKm(new BigDecimal("50.00"))
                .pricePerKg(new BigDecimal("10.00"))
                .maxWeightKg(new BigDecimal("1000.00"))
                .routeOrigin("Dambulla")
                .routeDestination("Colombo")
                .scheduleDays(List.of("MONDAY", "WEDNESDAY", "FRIDAY"))
                .build();

        samplePackage = TransportPackage.builder()
                .id(packageId)
                .agency(agencyProfile)
                .title("Standard Vegetable Transport")
                .description("Daily vegetable route")
                .packageType(PackageType.WEIGHT_BASED)
                .basePrice(new BigDecimal("1500.00"))
                .pricePerKm(new BigDecimal("50.00"))
                .pricePerKg(new BigDecimal("10.00"))
                .maxWeightKg(new BigDecimal("1000.00"))
                .routeOrigin("Dambulla")
                .routeDestination("Colombo")
                .scheduleDays(List.of("MONDAY", "WEDNESDAY", "FRIDAY"))
                .isActive(true)
                .build();
    }

    @Test
    @DisplayName("Create package successfully publishes PackageCreatedEvent")
    void testCreatePackage_Success_PublishesEvent() {
        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.of(agencyProfile));
        when(packageRepository.save(any(TransportPackage.class))).thenAnswer(invocation -> {
            TransportPackage p = invocation.getArgument(0);
            p.setId(packageId);
            return p;
        });

        PackageResponse result = packageService.createPackage(agencyUserId, createRequest);

        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(packageId);
        assertThat(result.getTitle()).isEqualTo("Standard Vegetable Transport");
        assertThat(result.getAgencyId()).isEqualTo(agencyId);

        verify(packageRepository, times(1)).save(any(TransportPackage.class));
        verify(applicationEventPublisher, times(1)).publishEvent(any(PackageCreatedEvent.class));
    }

    @Test
    @DisplayName("Create package does not publish event if packageRepository.save throws")
    void testCreatePackage_WhenSaveFails_DoesNotPublishEvent() {
        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.of(agencyProfile));
        when(packageRepository.save(any(TransportPackage.class))).thenThrow(new RuntimeException("Database error"));

        assertThatThrownBy(() -> packageService.createPackage(agencyUserId, createRequest))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("Database error");

        verify(applicationEventPublisher, never()).publishEvent(any());
    }

    @Test
    @DisplayName("Create package throws ResourceNotFoundException if agency profile not found")
    void testCreatePackage_AgencyNotFound_ThrowsResourceNotFoundException() {
        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> packageService.createPackage(agencyUserId, createRequest))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Agency profile not found");

        verify(packageRepository, never()).save(any());
        verify(applicationEventPublisher, never()).publishEvent(any());
    }

    @Test
    @DisplayName("Get agency packages returns list of packages owned by agency")
    void testGetAgencyPackages_Success() {
        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.of(agencyProfile));
        when(packageRepository.findByAgencyId(agencyId)).thenReturn(List.of(samplePackage));

        List<PackageResponse> result = packageService.getAgencyPackages(agencyUserId);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getTitle()).isEqualTo("Standard Vegetable Transport");
        assertThat(result.get(0).getAgencyId()).isEqualTo(agencyId);
    }

    @Test
    @DisplayName("Get package by ID returns details when package belongs to agency")
    void testGetAgencyPackageById_Success() {
        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.of(agencyProfile));
        when(packageRepository.findById(packageId)).thenReturn(Optional.of(samplePackage));

        PackageResponse result = packageService.getAgencyPackageById(packageId, agencyUserId);

        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(packageId);
        assertThat(result.getTitle()).isEqualTo("Standard Vegetable Transport");
    }

    @Test
    @DisplayName("Get package by ID throws ResourceNotFoundException when package belongs to another agency")
    void testGetAgencyPackageById_WrongAgency_ThrowsResourceNotFoundException() {
        when(agencyProfileRepository.findByUserId(otherAgencyUserId)).thenReturn(Optional.of(otherAgencyProfile));
        when(packageRepository.findById(packageId)).thenReturn(Optional.of(samplePackage));

        assertThatThrownBy(() -> packageService.getAgencyPackageById(packageId, otherAgencyUserId))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Package not found with id: " + packageId);
    }

    @Test
    @DisplayName("Get package by ID throws ResourceNotFoundException when package does not exist")
    void testGetAgencyPackageById_NotFound_ThrowsResourceNotFoundException() {
        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.of(agencyProfile));
        when(packageRepository.findById(packageId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> packageService.getAgencyPackageById(packageId, agencyUserId))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Package not found with id: " + packageId);
    }

    @Test
    @DisplayName("Update package updates details successfully when owned by agency")
    void testUpdatePackage_Success() {
        UpdatePackageRequest updateRequest = UpdatePackageRequest.builder()
                .title("Updated Express Transport")
                .basePrice(new BigDecimal("2000.00"))
                .build();

        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.of(agencyProfile));
        when(packageRepository.findById(packageId)).thenReturn(Optional.of(samplePackage));
        when(packageRepository.save(any(TransportPackage.class))).thenAnswer(invocation -> invocation.getArgument(0));

        PackageResponse result = packageService.updatePackage(packageId, agencyUserId, updateRequest);

        assertThat(result.getTitle()).isEqualTo("Updated Express Transport");
        assertThat(result.getBasePrice()).isEqualTo(new BigDecimal("2000.00"));
        verify(packageRepository, times(1)).save(any(TransportPackage.class));
    }

    @Test
    @DisplayName("Update package throws ResourceNotFoundException when owned by another agency")
    void testUpdatePackage_WrongAgency_ThrowsResourceNotFoundException() {
        UpdatePackageRequest updateRequest = UpdatePackageRequest.builder()
                .title("Updated Express Transport")
                .build();

        when(agencyProfileRepository.findByUserId(otherAgencyUserId)).thenReturn(Optional.of(otherAgencyProfile));
        when(packageRepository.findById(packageId)).thenReturn(Optional.of(samplePackage));

        assertThatThrownBy(() -> packageService.updatePackage(packageId, otherAgencyUserId, updateRequest))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Package not found with id: " + packageId);

        verify(packageRepository, never()).save(any());
    }

    @Test
    @DisplayName("Delete package removes package successfully when owned by agency")
    void testDeletePackage_Success() {
        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.of(agencyProfile));
        when(packageRepository.findById(packageId)).thenReturn(Optional.of(samplePackage));

        packageService.deletePackage(packageId, agencyUserId);

        verify(packageRepository, times(1)).delete(samplePackage);
    }

    @Test
    @DisplayName("Delete package throws ResourceNotFoundException when owned by another agency")
    void testDeletePackage_WrongAgency_ThrowsResourceNotFoundException() {
        when(agencyProfileRepository.findByUserId(otherAgencyUserId)).thenReturn(Optional.of(otherAgencyProfile));
        when(packageRepository.findById(packageId)).thenReturn(Optional.of(samplePackage));

        assertThatThrownBy(() -> packageService.deletePackage(packageId, otherAgencyUserId))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Package not found with id: " + packageId);

        verify(packageRepository, never()).delete(any());
    }
}
