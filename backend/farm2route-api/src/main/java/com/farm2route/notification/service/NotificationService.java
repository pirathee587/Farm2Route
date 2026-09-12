package com.farm2route.notification.service;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.common.enums.NotificationType;
import com.farm2route.common.exception.ForbiddenException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.notification.dto.NotificationDto;
import com.farm2route.notification.entity.Notification;
import com.farm2route.notification.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class NotificationService {
    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final AgencyProfileRepository agencyProfileRepository;

    @Transactional(readOnly = true)
    public List<NotificationDto> list(UUID recipientUserId) {
        return notificationRepository.findByRecipientIdOrderByCreatedAtDesc(recipientUserId).stream()
                .map(NotificationDto::from).toList();
    }

    @Transactional(readOnly = true)
    public long unreadCount(UUID recipientUserId) {
        return notificationRepository.countByRecipientIdAndReadFalse(recipientUserId);
    }

    @Transactional
    public NotificationDto markRead(UUID recipientUserId, UUID notificationId) {
        Notification notification = notificationRepository.findByIdAndRecipientId(notificationId, recipientUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found"));
        if (!notification.isRead()) {
            notification.setRead(true);
            notification.setReadAt(Instant.now());
        }
        return NotificationDto.from(notificationRepository.save(notification));
    }

    @Transactional
    public Notification createForUser(UUID recipientUserId, NotificationType type, String title, String message,
                                      String referenceType, UUID referenceId) {
        User recipient = userRepository.findById(recipientUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification recipient not found"));
        return notificationRepository.save(Notification.builder().recipient(recipient).notificationType(type)
                .title(title).message(message).referenceType(referenceType).referenceId(referenceId).build());
    }

    @Transactional
    public Notification createForAgency(UUID agencyId, NotificationType type, String title, String message,
                                        String referenceType, UUID referenceId) {
        UUID userId = agencyProfileRepository.findById(agencyId)
                .map(profile -> profile.getUser().getId())
                .orElseThrow(() -> new ResourceNotFoundException("Agency notification recipient not found"));
        return createForUser(userId, type, title, message, referenceType, referenceId);
    }

    @Transactional
    public NotificationDto create(UUID userId, NotificationType type, String title, String message,
                                  String referenceType, UUID referenceId) {
        return NotificationDto.from(createForUser(userId, type, title, message, referenceType, referenceId));
    }

    @Transactional
    public NotificationDto markAsRead(UUID notificationId, UUID userId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found with id: " + notificationId));
        if (notification.getRecipient() == null || !userId.equals(notification.getRecipient().getId())) {
            throw new ForbiddenException("You are not authorized to update this notification");
        }
        return markRead(userId, notificationId);
    }

    @Transactional(readOnly = true)
    public long getUnreadCount(UUID userId) {
        return unreadCount(userId);
    }

    @Transactional(readOnly = true)
    public Page<NotificationDto> getHistory(UUID userId, Pageable pageable) {
        return notificationRepository.findByRecipientIdOrderByCreatedAtDesc(userId, pageable)
                .map(NotificationDto::from);
    }
}
