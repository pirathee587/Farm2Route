package com.farm2route.notification.dto;

import com.farm2route.common.enums.NotificationType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationDto {

    private UUID id;
    private UUID userId;
    private String title;
    private String message;
    private NotificationType notificationType;
    private String referenceType;
    private UUID referenceId;
    private boolean isRead;
    private Instant readAt;
    private Instant createdAt;
}
