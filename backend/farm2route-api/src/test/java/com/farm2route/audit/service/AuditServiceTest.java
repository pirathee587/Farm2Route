package com.farm2route.audit.service;

import com.farm2route.audit.dto.PagedAuditLogDto;
import com.farm2route.audit.entity.AuditLog;
import com.farm2route.audit.repository.AuditLogRepository;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.auth.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.context.ActiveProfiles;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

import static org.awaitility.Awaitility.await;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
class AuditServiceTest {

    @Autowired
    private AuditService auditService;

    @Autowired
    private AuditLogRepository auditLogRepository;

    @Autowired
    private UserRepository userRepository;

    private User testUser;

    @BeforeEach
    void setUp() {
        auditLogRepository.deleteAll();
        userRepository.deleteAll();

        testUser = User.builder()
                .phoneNumber("+94770000000")
                .email("admin.test@farm2route.com")
                .passwordHash("$2a$12$hashedpassword")
                .role(Role.ADMIN)
                .status(UserStatus.ACTIVE)
                .phoneVerified(true)
                .build();
        testUser = userRepository.save(testUser);
    }

    @Test
    @DisplayName("logAction should asynchronously persist audit log record in H2 database")
    void testLogActionPersistsCorrectly() {
        auditService.logAction(
                testUser,
                "REVIEW_AGENCY_KYC",
                "AgencyProfile",
                "agency-uuid-123",
                "{\"kycStatus\":\"PENDING\"}",
                "{\"kycStatus\":\"APPROVED\"}",
                "192.168.1.100",
                "Mozilla/5.0"
        );

        await().atMost(3, TimeUnit.SECONDS).untilAsserted(() -> {
            List<AuditLog> logs = auditLogRepository.findAll();
            assertFalse(logs.isEmpty(), "Audit logs should not be empty");
            AuditLog log = logs.get(0);
            assertEquals("REVIEW_AGENCY_KYC", log.getAction());
            assertEquals("AgencyProfile", log.getEntityName());
            assertEquals("agency-uuid-123", log.getEntityId());
            assertEquals("ADMIN", log.getActorRole());
            assertNotNull(log.getActor());
            assertEquals(testUser.getId(), log.getActor().getId());
            assertEquals("192.168.1.100", log.getIpAddress());
            assertEquals("Mozilla/5.0", log.getUserAgent());
            assertNotNull(log.getOldValue());
            assertTrue(log.getOldValue().contains("PENDING"));
            assertNotNull(log.getNewValue());
            assertTrue(log.getNewValue().contains("APPROVED"));
        });
    }

    @Test
    @DisplayName("getAuditLogs should filter and paginate audit logs accurately")
    void testGetAuditLogsWithFilteringAndPagination() {
        auditService.logAction(testUser, "REVIEW_AGENCY_KYC", "AgencyProfile", "agency-1", "{}", "{}", "127.0.0.1", "Agent");
        auditService.logAction(testUser, "REVIEW_DRIVER_KYC", "DriverProfile", "driver-1", "{}", "{}", "127.0.0.1", "Agent");
        auditService.logAction(null, "SYSTEM_CLEANUP", "System", "sys-1", "{}", "{}", "127.0.0.1", "System");

        await().atMost(3, TimeUnit.SECONDS).untilAsserted(() -> {
            assertEquals(3, auditLogRepository.count());
        });

        // Filter by action
        PagedAuditLogDto agencyKycLogs = auditService.getAuditLogs(
                "REVIEW_AGENCY_KYC", null, null, null, null, PageRequest.of(0, 10)
        );
        assertEquals(1, agencyKycLogs.getTotalElements());
        assertEquals("AgencyProfile", agencyKycLogs.getContent().get(0).getEntityName());

        // Filter by entityName
        PagedAuditLogDto driverLogs = auditService.getAuditLogs(
                null, "DriverProfile", null, null, null, PageRequest.of(0, 10)
        );
        assertEquals(1, driverLogs.getTotalElements());
        assertEquals("REVIEW_DRIVER_KYC", driverLogs.getContent().get(0).getAction());

        // Filter by actorId
        PagedAuditLogDto actorLogs = auditService.getAuditLogs(
                null, null, testUser.getId(), null, null, PageRequest.of(0, 10)
        );
        assertEquals(2, actorLogs.getTotalElements());

        // Filter by date range
        Instant from = Instant.now().minusSeconds(60);
        Instant to = Instant.now().plusSeconds(60);
        PagedAuditLogDto dateFilteredLogs = auditService.getAuditLogs(
                null, null, null, from, to, PageRequest.of(0, 10)
        );
        assertEquals(3, dateFilteredLogs.getTotalElements());
    }
}
