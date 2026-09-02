package com.farm2route.auth.repository;

import com.farm2route.auth.entity.OtpVerification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OtpVerificationRepository extends JpaRepository<OtpVerification, UUID> {

    @Query("SELECT o FROM OtpVerification o WHERE o.phoneNumber = :phoneNumber AND o.purpose = :purpose AND o.isVerified = false AND o.expiresAt > :now ORDER BY o.createdAt DESC LIMIT 1")
    Optional<OtpVerification> findLatestActiveOtp(
            @Param("phoneNumber") String phoneNumber,
            @Param("purpose") String purpose,
            @Param("now") Instant now);

    @Query("SELECT o FROM OtpVerification o WHERE o.phoneNumber = :phoneNumber AND o.purpose = :purpose ORDER BY o.createdAt DESC LIMIT 1")
    Optional<OtpVerification> findLatestByPhoneAndPurpose(
            @Param("phoneNumber") String phoneNumber,
            @Param("purpose") String purpose);
}
