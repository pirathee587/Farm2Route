package com.farm2route.maintenance.repository;

import com.farm2route.common.enums.MaintenanceStatus;
import com.farm2route.maintenance.entity.VehicleMaintenance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.time.LocalDate;
import java.util.UUID;
import jakarta.persistence.LockModeType;
import java.util.Optional;

public interface VehicleMaintenanceRepository extends JpaRepository<VehicleMaintenance, UUID> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select m from VehicleMaintenance m where m.id = :id")
    Optional<VehicleMaintenance> findByIdForUpdate(@Param("id") UUID id);
    List<VehicleMaintenance> findByVehicleIdOrderByMaintenanceDateDesc(UUID vehicleId);
    List<VehicleMaintenance> findByVehicleAgencyIdAndStatusOrderByMaintenanceDateDesc(UUID agencyId, MaintenanceStatus status);
    List<VehicleMaintenance> findByStatusOrderByMaintenanceDateDesc(MaintenanceStatus status);
    long countByVehicleAgencyIdAndStatus(UUID agencyId, MaintenanceStatus status);

    @Query("select m from VehicleMaintenance m where m.nextDueDate <= :date and m.status in :statuses")
    List<VehicleMaintenance> findDueForNotification(@Param("date") LocalDate date,
                                                     @Param("statuses") List<MaintenanceStatus> statuses);

    @Query("select count(m) from VehicleMaintenance m where m.vehicle.agency.id = :agencyId " +
            "and m.nextDueDate < :date and m.status in :statuses")
    long countOverdueForAgency(@Param("agencyId") UUID agencyId, @Param("date") LocalDate date,
                               @Param("statuses") List<MaintenanceStatus> statuses);
}
