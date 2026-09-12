package com.farm2route.notification.dto;

import com.farm2route.common.enums.NotificationType;
import com.farm2route.notification.entity.Notification;
import lombok.Builder;
import lombok.Value;

import java.time.Instant;
import java.util.UUID;

@Value @Builder
public class NotificationDto {
    UUID id;
    UUID userId;
    String title;
    String message;
    NotificationType notificationType;
    String referenceType;
    UUID referenceId;
    boolean read;
    Instant readAt;
    Instant createdAt;

    public static NotificationDto from(Notification notification) {
        UUID userId = notification.getRecipient() == null ? null : notification.getRecipient().getId();
        return NotificationDto.builder().id(notification.getId()).userId(userId).title(notification.getTitle())
                .message(notification.getMessage()).notificationType(notification.getNotificationType())
                .referenceType(notification.getReferenceType()).referenceId(notification.getReferenceId())
                .read(notification.isRead()).readAt(notification.getReadAt())
                .createdAt(notification.getCreatedAt()).build();
    }
}
