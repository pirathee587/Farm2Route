package com.farm2route.catalog.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.catalog.dto.CreatePackageRequest;
import com.farm2route.catalog.dto.PackageResponse;
import com.farm2route.catalog.dto.UpdatePackageRequest;
import com.farm2route.catalog.entity.TransportPackage;
import com.farm2route.catalog.repository.PackageRepository;
import com.farm2route.common.event.PackageCreatedEvent;
import com.farm2route.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class PackageService {

    private final PackageRepository            packageRepository;
    private final AgencyProfileRepository      agencyProfileRepository;

    /**
     * Used to publish Spring internal events — PackageEventRelay forwards to RabbitMQ AFTER_COMMIT.
     */
    private final ApplicationEventPublisher    applicationEventPublisher;

    @Transactional
    public PackageResponse createPackage(UUID agencyUserId, CreatePackageRequest request) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        TransportPackage pkg = TransportPackage.builder()
                .agency(agency)
                .title(request.getTitle())
                .description(request.getDescription())
                .packageType(request.getPackageType())
                .basePrice(request.getBasePrice())
                .pricePerKm(request.getPricePerKm())
                .pricePerKg(request.getPricePerKg() != null ? request.getPricePerKg() : BigDecimal.ZERO)
                .maxWeightKg(request.getMaxWeightKg())
                .routeOrigin(request.getRouteOrigin())
                .routeDestination(request.getRouteDestination())
                .scheduleDays(request.getScheduleDays() != null ? request.getScheduleDays() : new ArrayList<>())
                .isActive(true)
                .build();

        pkg = packageRepository.save(pkg);
        log.info("Created transport package id={} title='{}' for agencyId={}", pkg.getId(), pkg.getTitle(), agency.getId());

        // Publish Spring ApplicationEvent — PackageEventRelay handles AFTER_COMMIT dispatch to RabbitMQ
        applicationEventPublisher.publishEvent(
                PackageCreatedEvent.builder()
                        .packageId(pkg.getId())
                        .agencyId(agency.getId())
                        .title(pkg.getTitle())
                        .packageType(pkg.getPackageType())
                        .basePrice(pkg.getBasePrice())
                        .build()
        );

        return mapToResponse(pkg);
    }

    @Transactional(readOnly = true)
    public List<PackageResponse> getAgencyPackages(UUID agencyUserId) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        return packageRepository.findByAgencyId(agency.getId()).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public PackageResponse getAgencyPackageById(UUID packageId, UUID agencyUserId) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        TransportPackage pkg = packageRepository.findById(packageId)
                .filter(p -> p.getAgency().getId().equals(agency.getId()))
                .orElseThrow(() -> new ResourceNotFoundException("Package not found with id: " + packageId));

        return mapToResponse(pkg);
    }

    @Transactional
    public PackageResponse updatePackage(UUID packageId, UUID agencyUserId, UpdatePackageRequest request) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        TransportPackage pkg = packageRepository.findById(packageId)
                .filter(p -> p.getAgency().getId().equals(agency.getId()))
                .orElseThrow(() -> new ResourceNotFoundException("Package not found with id: " + packageId));

        if (request.getTitle() != null && !request.getTitle().isBlank()) {
            pkg.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            pkg.setDescription(request.getDescription());
        }
        if (request.getPackageType() != null) {
            pkg.setPackageType(request.getPackageType());
        }
        if (request.getBasePrice() != null) {
            pkg.setBasePrice(request.getBasePrice());
        }
        if (request.getPricePerKm() != null) {
            pkg.setPricePerKm(request.getPricePerKm());
        }
        if (request.getPricePerKg() != null) {
            pkg.setPricePerKg(request.getPricePerKg());
        }
        if (request.getMaxWeightKg() != null) {
            pkg.setMaxWeightKg(request.getMaxWeightKg());
        }
        if (request.getRouteOrigin() != null) {
            pkg.setRouteOrigin(request.getRouteOrigin());
        }
        if (request.getRouteDestination() != null) {
            pkg.setRouteDestination(request.getRouteDestination());
        }
        if (request.getScheduleDays() != null) {
            pkg.setScheduleDays(request.getScheduleDays());
        }
        if (request.getIsActive() != null) {
            pkg.setActive(request.getIsActive());
        }

        pkg = packageRepository.save(pkg);
        log.info("Updated transport package id={} for agencyId={}", packageId, agency.getId());
        return mapToResponse(pkg);
    }

    @Transactional
    public void deletePackage(UUID packageId, UUID agencyUserId) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        TransportPackage pkg = packageRepository.findById(packageId)
                .filter(p -> p.getAgency().getId().equals(agency.getId()))
                .orElseThrow(() -> new ResourceNotFoundException("Package not found with id: " + packageId));

        packageRepository.delete(pkg);
        log.info("Deleted transport package id={} for agencyId={}", packageId, agency.getId());
    }

    private PackageResponse mapToResponse(TransportPackage pkg) {
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
                .createdAt(pkg.getCreatedAt())
                .build();
    }
}
