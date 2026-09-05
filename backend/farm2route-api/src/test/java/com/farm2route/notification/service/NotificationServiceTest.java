package com.farm2route.notification.service;

import com.farm2route.common.enums.NotificationType;
import com.farm2route.common.exception.ForbiddenException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.notification.dto.NotificationDto;
import com.farm2route.notification.entity.Notification;
import com.farm2route.notification.repository.NotificationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {

    @Mock
    private NotificationRepository notificationRepository;

    @InjectMocks
    private NotificationService notificationService;

    private UUID userId;
    private UUID notificationId;
    private Notification sampleNotification;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        notificationId = UUID.randomUUID();

        sampleNotification = Notification.builder()
                .id(notificationId)
                .userId(userId)
                .title("Booking Confirmed")
                .message("Your booking F2R-1234 has been created.")
                .notificationType(NotificationType.BOOKING_UPDATE)
                .referenceType("BOOKING")
                .referenceId(UUID.randomUUID())
                .isRead(false)
                .createdAt(Instant.now())
                .build();
    }

    @Test
    @DisplayName("create persists notification and returns NotificationDto")
    void testCreate_Success() {
        when(notificationRepository.save(any(Notification.class))).thenReturn(sampleNotification);

        NotificationDto result = notificationService.create(
                userId,
                NotificationType.BOOKING_UPDATE,
                "Booking Confirmed",
                "Your booking F2R-1234 has been created.",
                "BOOKING",
                sampleNotification.getReferenceId()
        );

        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(notificationId);
        assertThat(result.getUserId()).isEqualTo(userId);
        assertThat(result.getTitle()).isEqualTo("Booking Confirmed");
        assertThat(result.getNotificationType()).isEqualTo(NotificationType.BOOKING_UPDATE);

        ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);
        verify(notificationRepository, times(1)).save(captor.capture());
        assertThat(captor.getValue().isRead()).isFalse();
    }

    @Test
    @DisplayName("markAsRead updates isRead to true and sets readAt")
    void testMarkAsRead_Success() {
        when(notificationRepository.findById(notificationId)).thenReturn(Optional.of(sampleNotification));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(invocation -> invocation.getArgument(0));

        NotificationDto result = notificationService.markAsRead(notificationId, userId);

        assertThat(result).isNotNull();
        assertThat(result.isRead()).isTrue();
        assertThat(result.getReadAt()).isNotNull();

        verify(notificationRepository, times(1)).save(sampleNotification);
    }

    @Test
    @DisplayName("markAsRead throws ForbiddenException when notification belongs to another user")
    void testMarkAsRead_WrongUser_ThrowsForbiddenException() {
        UUID otherUserId = UUID.randomUUID();
        when(notificationRepository.findById(notificationId)).thenReturn(Optional.of(sampleNotification));

        assertThatThrownBy(() -> notificationService.markAsRead(notificationId, otherUserId))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("You are not authorized to update this notification");

        verify(notificationRepository, never()).save(any());
    }

    @Test
    @DisplayName("markAsRead throws ResourceNotFoundException when notification does not exist")
    void testMarkAsRead_NotFound_ThrowsResourceNotFoundException() {
        when(notificationRepository.findById(notificationId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> notificationService.markAsRead(notificationId, userId))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Notification not found with id: " + notificationId);
    }

    @Test
    @DisplayName("getUnreadCount returns correct unread count")
    void testGetUnreadCount_Success() {
        when(notificationRepository.countByUserIdAndIsReadFalse(userId)).thenReturn(5L);

        long count = notificationService.getUnreadCount(userId);

        assertThat(count).isEqualTo(5L);
        verify(notificationRepository, times(1)).countByUserIdAndIsReadFalse(userId);
    }

    @Test
    @DisplayName("getHistory returns paged NotificationDto")
    void testGetHistory_Success() {
        Pageable pageable = PageRequest.of(0, 10);
        Page<Notification> page = new PageImpl<>(List.of(sampleNotification), pageable, 1);
        when(notificationRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable)).thenReturn(page);

        Page<NotificationDto> result = notificationService.getHistory(userId, pageable);

        assertThat(result).isNotNull();
        assertThat(result.getTotalElements()).isEqualTo(1);
        assertThat(result.getContent().get(0).getId()).isEqualTo(notificationId);
    }
}
