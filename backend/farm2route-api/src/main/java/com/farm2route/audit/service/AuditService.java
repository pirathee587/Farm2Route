package com.farm2route.audit.service;

import com.farm2route.audit.entity.AuditLog;
import com.farm2route.audit.repository.AuditLogRepository;
import com.farm2route.auth.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuditService {

    private final AuditLogRepository auditLogRepository;

    @Async
    @Transactional
    public void logAction(User actor, String action, String entityName, String entityId,
                          String oldValue, String newValue, String ipAddress, String userAgent) {
        try {
            AuditLog auditLog = AuditLog.builder()
                    .actor(actor)
                    .actorRole(actor != null ? actor.getRole().name() : "SYSTEM")
                    .action(action)
                    .entityName(entityName)
                    .entityId(entityId)
                    .oldValue(oldValue)
                    .newValue(newValue)
                    .ipAddress(ipAddress)
                    .userAgent(userAgent)
                    .build();

            auditLogRepository.save(auditLog);
            log.debug("Recorded audit log: action={}, entity={}/{}", action, entityName, entityId);
        } catch (Exception ex) {
            log.error("Failed to write audit log: {}", ex.getMessage());
        }
    }
}
