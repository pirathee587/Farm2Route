package com.farm2route.transport.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.catalog.repository.PackageRepository;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.common.enums.VehicleType;
import com.farm2route.transport.dto.PriceEstimationResponse;
import com.farm2route.transport.dto.TransportRecommendationRequest;
import com.farm2route.transport.dto.TransportRecommendationResponse;
import com.farm2route.transport.dto.VehicleRecommendationDto;
import com.farm2route.vehicle.entity.Vehicle;
import com.farm2route.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TransportRecommendationServiceTest {

    @Mock
    private VehicleRepository vehicleRepository;

    @Mock
    private PackageRepository packageRepository;

    @Mock
    private BookingRepository bookingRepository;

    @Mock
    private PriceEstimationService priceEstimationService;

    @InjectMocks
    private TransportRecommendationService transportRecommendationService;

    private AgencyProfile mockAgency;
    private Vehicle van;
    private Vehicle truck;
    private Vehicle heavyLorry;
    private Vehicle freezerTruck;

    @BeforeEach
    void setUp() {
        mockAgency = AgencyProfile.builder()
                .id(UUID.randomUUID())
                .companyName("Green Route Logistics")
                .district("Kurunegala")
                .kycStatus(KycStatus.APPROVED)
                .build();

        van = Vehicle.builder()
                .id(UUID.randomUUID())
                .agency(mockAgency)
                .registrationNumber("WP-CAC-2034")
                .makeAndModel("Toyota HiAce Cargo")
                .vehicleType(VehicleType.VAN)
                .capacity(new BigDecimal("1500.00"))
                .cargoVolumeCbm(new BigDecimal("9.50"))
                .isRefrigerated(false)
                .status(VehicleStatus.AVAILABLE)
                .kycStatus(KycStatus.APPROVED)
                .build();

        truck = Vehicle.builder()
                .id(UUID.randomUUID())
                .agency(mockAgency)
                .registrationNumber("WP-LD-5982")
                .makeAndModel("Isuzu Elf Truck")
                .vehicleType(VehicleType.TRUCK)
                .capacity(new BigDecimal("4500.00"))
                .cargoVolumeCbm(new BigDecimal("18.00"))
                .isRefrigerated(false)
                .status(VehicleStatus.AVAILABLE)
                .kycStatus(KycStatus.APPROVED)
                .build();

        heavyLorry = Vehicle.builder()
                .id(UUID.randomUUID())
                .agency(mockAgency)
                .registrationNumber("NC-LH-4411")
                .makeAndModel("Tata LPT 1618")
                .vehicleType(VehicleType.LORRY)
                .capacity(new BigDecimal("10000.00"))
                .cargoVolumeCbm(new BigDecimal("35.00"))
                .isRefrigerated(false)
                .status(VehicleStatus.AVAILABLE)
                .kycStatus(KycStatus.APPROVED)
                .build();

        freezerTruck = Vehicle.builder()
                .id(UUID.randomUUID())
                .agency(mockAgency)
                .registrationNumber("WP-FZ-1109")
                .makeAndModel("Hino 300 Reefer")
                .vehicleType(VehicleType.FREEZER_TRUCK)
                .capacity(new BigDecimal("3500.00"))
                .cargoVolumeCbm(new BigDecimal("14.00"))
                .isRefrigerated(true)
                .status(VehicleStatus.AVAILABLE)
                .kycStatus(KycStatus.APPROVED)
                .build();
    }

    @Test
    @DisplayName("Should rank vehicles with highest payload utilization and type compatibility first")
    void shouldRankOptimalVehiclesFirst() {
        TransportRecommendationRequest request = TransportRecommendationRequest.builder()
                .pickupLocation("Kurunegala")
                .destination("Colombo")
                .requiredCapacity(new BigDecimal("1200.00"))
                .vehicleType(VehicleType.VAN)
                .requiresRefrigeration(false)
                .isFragile(false)
                .build();

        when(priceEstimationService.resolveDistanceKm(any(), any(), any(), any(), any(), any()))
                .thenReturn(new BigDecimal("85.00"));

        when(vehicleRepository.findByStatusAndKycStatusAndCapacityGreaterThanEqual(
                eq(VehicleStatus.AVAILABLE), eq(KycStatus.APPROVED), eq(new BigDecimal("1200.00"))))
                .thenReturn(List.of(heavyLorry, truck, van));

        when(priceEstimationService.calculateDetailedPrice(any(), any(), any(), eq(false), eq(false)))
                .thenReturn(PriceEstimationResponse.builder()
                        .estimatedDistanceKm(new BigDecimal("85.00"))
                        .baseFare(new BigDecimal("3500.00"))
                        .estimatedTotal(new BigDecimal("15000.00"))
                        .build());

        TransportRecommendationResponse response = transportRecommendationService.getRecommendations(request);

        assertThat(response).isNotNull();
        assertThat(response.getRecommendations()).hasSize(3);

        // Van has 80% utilization (1200/1500) and exact vehicleType match, so it should rank #1
        VehicleRecommendationDto topRecommendation = response.getRecommendations().get(0);
        assertThat(topRecommendation.getVehicleType()).isEqualTo(VehicleType.VAN);
        assertThat(topRecommendation.getRegistrationNumber()).isEqualTo("WP-CAC-2034");
        assertThat(topRecommendation.getRecommendationScore()).isGreaterThan(response.getRecommendations().get(1).getRecommendationScore());
    }

    @Test
    @DisplayName("Should strictly filter out non-refrigerated vehicles when cold-chain is required")
    void shouldFilterNonRefrigeratedVehiclesWhenRefrigerationRequired() {
        TransportRecommendationRequest request = TransportRecommendationRequest.builder()
                .pickupLocation("Dambulla")
                .destination("Colombo")
                .requiredCapacity(new BigDecimal("2000.00"))
                .requiresRefrigeration(true)
                .isFragile(false)
                .build();

        when(priceEstimationService.resolveDistanceKm(any(), any(), any(), any(), any(), any()))
                .thenReturn(new BigDecimal("150.00"));

        // Repository returns both dry truck and reefer
        when(vehicleRepository.findByStatusAndKycStatusAndCapacityGreaterThanEqual(
                eq(VehicleStatus.AVAILABLE), eq(KycStatus.APPROVED), eq(new BigDecimal("2000.00"))))
                .thenReturn(List.of(truck, freezerTruck));

        when(priceEstimationService.calculateDetailedPrice(any(), any(), any(), eq(true), eq(false)))
                .thenReturn(PriceEstimationResponse.builder()
                        .estimatedDistanceKm(new BigDecimal("150.00"))
                        .baseFare(new BigDecimal("8000.00"))
                        .estimatedTotal(new BigDecimal("35000.00"))
                        .build());

        TransportRecommendationResponse response = transportRecommendationService.getRecommendations(request);

        assertThat(response).isNotNull();
        // Only freezerTruck should pass refrigeration filter
        assertThat(response.getRecommendations()).hasSize(1);
        assertThat(response.getRecommendations().get(0).getVehicleType()).isEqualTo(VehicleType.FREEZER_TRUCK);
        assertThat(response.getRecommendations().get(0).isRefrigerated()).isTrue();
    }

    @Test
    @DisplayName("Should return empty list when no vehicle satisfies required load capacity")
    void shouldReturnEmptyWhenNoVehicleMeetsCapacity() {
        TransportRecommendationRequest request = TransportRecommendationRequest.builder()
                .pickupLocation("Anuradhapura")
                .destination("Colombo")
                .requiredCapacity(new BigDecimal("25000.00")) // Exceeds fleet max
                .requiresRefrigeration(false)
                .build();

        when(priceEstimationService.resolveDistanceKm(any(), any(), any(), any(), any(), any()))
                .thenReturn(new BigDecimal("200.00"));

        when(vehicleRepository.findByStatusAndKycStatusAndCapacityGreaterThanEqual(
                eq(VehicleStatus.AVAILABLE), eq(KycStatus.APPROVED), eq(new BigDecimal("25000.00"))))
                .thenReturn(List.of());

        TransportRecommendationResponse response = transportRecommendationService.getRecommendations(request);

        assertThat(response).isNotNull();
        assertThat(response.getRecommendations()).isEmpty();
        assertThat(response.getTotalCandidatesFound()).isEqualTo(0);
    }

    @Test
    @DisplayName("Should recommend vehicles for an existing booking entity")
    void shouldRecommendVehiclesForBooking() {
        UUID bookingId = UUID.randomUUID();
        Booking booking = Booking.builder()
                .id(bookingId)
                .pickupAddress("Kurunegala")
                .deliveryAddress("Colombo")
                .cargoWeightKg(new BigDecimal("1000.00"))
                .requiresRefrigeration(false)
                .isFragile(false)
                .build();

        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(priceEstimationService.resolveDistanceKm(any(), any(), any(), any(), any(), any()))
                .thenReturn(new BigDecimal("85.00"));
        when(vehicleRepository.findByStatusAndKycStatusAndCapacityGreaterThanEqual(any(), any(), any()))
                .thenReturn(List.of(van));
        when(priceEstimationService.calculateDetailedPrice(any(), any(), any(), any(Boolean.class), any(Boolean.class)))
                .thenReturn(PriceEstimationResponse.builder().baseFare(BigDecimal.ZERO).estimatedTotal(BigDecimal.TEN).build());

        List<UUID> recommendedIds = transportRecommendationService.recommendVehiclesForBooking(bookingId);

        assertThat(recommendedIds).hasSize(1);
        assertThat(recommendedIds.get(0)).isEqualTo(van.getId());
    }
}
