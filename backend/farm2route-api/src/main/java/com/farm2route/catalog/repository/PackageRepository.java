package com.farm2route.catalog.repository;

import com.farm2route.catalog.entity.TransportPackage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface PackageRepository extends JpaRepository<TransportPackage, UUID>, JpaSpecificationExecutor<TransportPackage> {

    List<TransportPackage> findByIsActiveTrue();

    List<TransportPackage> findByAgencyIdAndIsActiveTrue(UUID agencyId);

    List<TransportPackage> findByAgencyId(UUID agencyId);

    boolean existsByIdAndAgencyId(UUID id, UUID agencyId);
}
