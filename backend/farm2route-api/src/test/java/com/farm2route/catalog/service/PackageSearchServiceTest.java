package com.farm2route.catalog.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.catalog.dto.PackageResponse;
import com.farm2route.catalog.dto.PackageSearchRequest;
import com.farm2route.catalog.entity.TransportPackage;
import com.farm2route.catalog.repository.PackageRepository;
import com.farm2route.common.enums.PackageType;
import com.farm2route.common.exception.ResourceNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PackageSearchServiceTest {

    @Mock
    private PackageRepository packageRepository;

    @InjectMocks
    private PackageSearchService packageSearchService;

    private UUID packageId;
    private UUID agencyId;
    private AgencyProfile agency;
    private TransportPackage samplePackage;

    @BeforeEach
    void setUp() {
        packageId = UUID.randomUUID();
        agencyId = UUID.randomUUID();

        agency = AgencyProfile.builder()
                .id(agencyId)
                .companyName("Green Route Logistics")
                .contactPersonPhone("+94770000002")
                .build();

        samplePackage = TransportPackage.builder()
                .id(packageId)
                .agency(agency)
                .title("Kurunegala to Colombo Agro Express")
                .description("Direct overnight produce transit")
                .packageType(PackageType.STANDARD)
                .basePrice(new BigDecimal("5000.00"))
                .pricePerKm(new BigDecimal("120.00"))
                .pricePerKg(new BigDecimal("15.00"))
                .maxWeightKg(new BigDecimal("3500.00"))
                .routeOrigin("Kurunegala")
                .routeDestination("Colombo")
                .scheduleDays(List.of("MONDAY", "WEDNESDAY", "FRIDAY"))
                .isActive(true)
                .createdAt(Instant.now())
                .build();
    }

    @Test
    @DisplayName("Search packages returns paginated list of packages")
    void testSearchPackages_Success() {
        PackageSearchRequest request = PackageSearchRequest.builder()
                .routeOrigin("Kurunegala")
                .routeDestination("Colombo")
                .packageType(PackageType.STANDARD)
                .page(0)
                .size(10)
                .build();

        Page<TransportPackage> page = new PageImpl<>(List.of(samplePackage));
        when(packageRepository.findAll(any(Specification.class), any(Pageable.class))).thenReturn(page);

        Page<PackageResponse> result = packageSearchService.searchPackages(request);

        assertThat(result).isNotNull();
        assertThat(result.getContent()).hasSize(1);
        PackageResponse res = result.getContent().get(0);
        assertThat(res.getId()).isEqualTo(packageId);
        assertThat(res.getTitle()).isEqualTo("Kurunegala to Colombo Agro Express");
        assertThat(res.getAgencyName()).isEqualTo("Green Route Logistics");
        assertThat(res.getEstimatedCost()).isNull();
    }

    @Test
    @DisplayName("Search packages with distance and weight computes estimatedCost")
    void testSearchPackages_WithCostEstimation() {
        PackageSearchRequest request = PackageSearchRequest.builder()
                .distanceKm(new BigDecimal("100.00"))
                .weightKg(new BigDecimal("500.00"))
                .page(0)
                .size(10)
                .build();

        Page<TransportPackage> page = new PageImpl<>(List.of(samplePackage));
        when(packageRepository.findAll(any(Specification.class), any(Pageable.class))).thenReturn(page);

        Page<PackageResponse> result = packageSearchService.searchPackages(request);

        assertThat(result).isNotNull();
        assertThat(result.getContent()).hasSize(1);
        PackageResponse res = result.getContent().get(0);
        // Base 5000 + (100 * 120 = 12000) + (500 * 15 = 7500) = 24500.00
        assertThat(res.getEstimatedCost()).isEqualByComparingTo(new BigDecimal("24500.00"));
    }

    @Test
    @DisplayName("Get package by ID returns single package response")
    void testGetPackageById_Success() {
        when(packageRepository.findById(packageId)).thenReturn(Optional.of(samplePackage));

        PackageResponse result = packageSearchService.getPackageById(packageId);

        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(packageId);
        assertThat(result.getTitle()).isEqualTo("Kurunegala to Colombo Agro Express");
    }

    @Test
    @DisplayName("Get package by ID throws ResourceNotFoundException when package not found")
    void testGetPackageById_NotFound_ThrowsException() {
        when(packageRepository.findById(packageId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> packageSearchService.getPackageById(packageId))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Transport package not found");
    }
}
