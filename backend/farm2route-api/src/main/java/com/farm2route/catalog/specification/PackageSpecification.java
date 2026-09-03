package com.farm2route.catalog.specification;

import com.farm2route.catalog.dto.PackageSearchRequest;
import com.farm2route.catalog.entity.TransportPackage;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;

public final class PackageSpecification {

    private PackageSpecification() {
        // Utility specification builder
    }

    public static Specification<TransportPackage> withFilters(PackageSearchRequest request) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            // Always only active packages
            predicates.add(cb.isTrue(root.get("isActive")));

            if (request.getRouteOrigin() != null && !request.getRouteOrigin().trim().isEmpty()) {
                String originPattern = "%" + request.getRouteOrigin().trim().toLowerCase() + "%";
                predicates.add(cb.like(cb.lower(root.get("routeOrigin")), originPattern));
            }

            if (request.getRouteDestination() != null && !request.getRouteDestination().trim().isEmpty()) {
                String destPattern = "%" + request.getRouteDestination().trim().toLowerCase() + "%";
                predicates.add(cb.like(cb.lower(root.get("routeDestination")), destPattern));
            }

            if (request.getPackageType() != null) {
                predicates.add(cb.equal(root.get("packageType"), request.getPackageType()));
            }

            if (request.getMaxWeight() != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("maxWeightKg"), request.getMaxWeight()));
            }

            if (request.getMaxPrice() != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("basePrice"), request.getMaxPrice()));
            }

            if (request.getAgencyId() != null) {
                predicates.add(cb.equal(root.get("agency").get("id"), request.getAgencyId()));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
