package com.farm2route.finance.repository;

import com.farm2route.finance.entity.WithdrawalRequest;
import com.farm2route.finance.entity.WithdrawalRequestStatus;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public interface WithdrawalRequestRepository extends JpaRepository<WithdrawalRequest, UUID> {
    List<WithdrawalRequest> findByAgencyIdOrderByCreatedAtDesc(UUID agencyId);
    @Query("select coalesce(sum(w.amount), 0) from WithdrawalRequest w where w.agency.id = :agencyId and w.status in :statuses")
    BigDecimal sumAmountsByAgencyIdAndStatusIn(@Param("agencyId") UUID agencyId,
                                               @Param("statuses") List<WithdrawalRequestStatus> statuses);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select w from WithdrawalRequest w where w.id = :id")
    java.util.Optional<WithdrawalRequest> findByIdForUpdate(@Param("id") UUID id);
}
