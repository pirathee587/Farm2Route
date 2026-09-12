package com.farm2route.finance.repository;

import com.farm2route.finance.entity.FinancialTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;
import java.util.List;

public interface FinancialTransactionRepository extends JpaRepository<FinancialTransaction, UUID> {
    boolean existsByTransactionReference(String transactionReference);
    List<FinancialTransaction> findByPayeeIdOrderByCreatedAtDesc(UUID payeeId);
}
