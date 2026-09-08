package com.farm2route.notification.repository;

import com.farm2route.common.enums.NotificationType;
import com.farm2route.notification.entity.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, UUID> {
    List<Notification> findByRecipientIdOrderByCreatedAtDesc(UUID userId);
    Page<Notification> findByRecipientIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);
    long countByRecipientIdAndReadFalse(UUID userId);
    Optional<Notification> findByIdAndRecipientId(UUID id, UUID userId);
    boolean existsByRecipientIdAndNotificationTypeAndReferenceTypeAndReferenceId(
            UUID userId, NotificationType type, String referenceType, UUID referenceId);
}
