package com.farm2route.notification.repository;

import com.farm2route.notification.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import com.farm2route.common.enums.NotificationType;

public interface NotificationRepository extends JpaRepository<Notification, UUID> {
    List<Notification> findByRecipientIdOrderByCreatedAtDesc(UUID userId);
    long countByRecipientIdAndReadFalse(UUID userId);
    Optional<Notification> findByIdAndRecipientId(UUID id, UUID userId);
    boolean existsByRecipientIdAndNotificationTypeAndReferenceTypeAndReferenceId(
            UUID userId, NotificationType type, String referenceType, UUID referenceId);
}
