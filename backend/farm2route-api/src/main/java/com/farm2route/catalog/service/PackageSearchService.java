package com.farm2route.catalog.service;

import com.farm2route.catalog.dto.PackageResponse;
import com.farm2route.catalog.dto.PackageSearchRequest;
import com.farm2route.catalog.entity.TransportPackage;
import com.farm2route.catalog.repository.PackageRepository;
import com.farm2route.catalog.specification.PackageSpecification;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.common.util.GeoUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class PackageSearchService {

    private final PackageRepository packageRepository;

    @Transactional(readOnly = true)
    public Page<PackageResponse> searchPackages(PackageSearchRequest request) {
        Sort.Direction direction = "ASC".equalsIgnoreCase(request.getSortDirection()) ? Sort.Direction.ASC : Sort.Direction.DESC;
        String sortBy = request.getSortBy() != null && !request.getSortBy().isBlank() ? request.getSortBy() : "basePrice";

        Pageable pageable = PageRequest.of(Math.max(0, request.getPage()), Math.max(1, request.getSize()), Sort.by(direction, sortBy));
        Specification<TransportPackage> spec = PackageSpecification.withFilters(request);

        Page<TransportPackage> page = packageRepository.findAll(spec, pageable);
        return page.map(pkg -> mapToResponse(pkg, request.getDistanceKm(), request.getWeightKg()));
    }

    @Transactional(readOnly = true)
    public PackageResponse getPackageById(UUID packageId) {
        TransportPackage pkg = packageRepository.findById(packageId)
                .orElseThrow(() -> new ResourceNotFoundException("Transport package not found with id: " + packageId));
        return mapToResponse(pkg, null, null);
    }

    private PackageResponse mapToResponse(TransportPackage pkg, BigDecimal distanceKm, BigDecimal weightKg) {
        BigDecimal estimatedCost = null;
        if (distanceKm != null || weightKg != null) {
            estimatedCost = GeoUtils.estimateTotalCost(
                    pkg.getBasePrice(),
                    pkg.getPricePerKm(),
                    pkg.getPricePerKg(),
                    distanceKm,
                    weightKg
            );
        }

        return PackageResponse.builder()
                .id(pkg.getId())
                .agencyId(pkg.getAgency() != null ? pkg.getAgency().getId() : null)
                .agencyName(pkg.getAgency() != null ? pkg.getAgency().getCompanyName() : null)
                .agencyPhone(pkg.getAgency() != null ? pkg.getAgency().getContactPersonPhone() : null)
                .title(pkg.getTitle())
                .description(pkg.getDescription())
                .packageType(pkg.getPackageType())
                .basePrice(pkg.getBasePrice())
                .pricePerKm(pkg.getPricePerKm())
                .pricePerKg(pkg.getPricePerKg())
                .maxWeightKg(pkg.getMaxWeightKg())
                .routeOrigin(pkg.getRouteOrigin())
                .routeDestination(pkg.getRouteDestination())
                .scheduleDays(pkg.getScheduleDays())
                .isActive(pkg.isActive())
                .estimatedCost(estimatedCost)
                .createdAt(pkg.getCreatedAt())
                .build();
    }
}
