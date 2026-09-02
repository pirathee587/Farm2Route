package com.farm2route.auth.repository;

import com.farm2route.auth.entity.OtpVerification;
import com.farm2route.auth.model.OtpPurpose;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OtpVerificationRepository extends JpaRepository<OtpVerification, UUID> {

    @Query("SELECT o FROM OtpVerification o WHERE o.phoneNumber = :phoneNumber AND o.purpose = :purpose AND o.verifiedAt IS NULL AND o.expiresAt > :now ORDER BY o.createdAt DESC LIMIT 1")
    Optional<OtpVerification> findLatestActiveOtp(
            @Param("phoneNumber") String phoneNumber,
            @Param("purpose") OtpPurpose purpose,
            @Param("now") Instant now);

    @Query("SELECT COUNT(o) FROM OtpVerification o WHERE o.phoneNumber = :phoneNumber AND o.purpose = :purpose AND o.createdAt >= :windowStart")
    long countRecentRequests(
            @Param("phoneNumber") String phoneNumber,
            @Param("purpose") OtpPurpose purpose,
            @Param("windowStart") Instant windowStart);

    @Modifying
    @Query("DELETE FROM OtpVerification o WHERE o.expiresAt < :now OR o.verifiedAt IS NOT NULL")
    void deleteExpiredOrVerifiedOtps(@Param("now") Instant now);
}
