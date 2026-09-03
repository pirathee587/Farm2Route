package com.farm2route.notification.service;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.common.enums.NotificationType;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.notification.channel.NotificationChannel;
import com.farm2route.notification.dto.NotificationDto;
import com.farm2route.notification.entity.Notification;
import com.farm2route.notification.repository.NotificationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
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

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {

    @Mock
    private NotificationRepository notificationRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private NotificationChannel notificationChannel;

    private NotificationService notificationService;

    private UUID userId;
    private User testUser;

    @BeforeEach
    void setUp() {
        notificationService = new NotificationService(
                notificationRepository,
                userRepository,
                List.of(notificationChannel)
        );

        userId = UUID.randomUUID();
        testUser = User.builder()
                .id(userId)
                .phoneNumber("+94771234567")
                .email("test@farm2route.com")
                .build();
    }

    @Test
    @DisplayName("Should successfully send notification and invoke notification channels")
    void testSendNotificationSuccess() {
        UUID referenceId = UUID.randomUUID();
        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(invocation -> {
            Notification n = invocation.getArgument(0);
            n.setId(UUID.randomUUID());
            n.setCreatedAt(Instant.now());
            return n;
        });

        NotificationDto dto = notificationService.send(
                userId,
                NotificationType.BOOKING_UPDATE,
                "Booking Confirmed",
                "Your booking #123 has been accepted.",
                "BOOKING",
                referenceId
        );

        assertNotNull(dto);
        assertEquals("Booking Confirmed", dto.getTitle());
        assertEquals("Your booking #123 has been accepted.", dto.getMessage());
        assertEquals(NotificationType.BOOKING_UPDATE, dto.getNotificationType());
        assertEquals("BOOKING", dto.getReferenceType());
        assertEquals(referenceId, dto.getReferenceId());
        assertFalse(dto.isRead());

        verify(notificationRepository).save(any(Notification.class));
        verify(notificationChannel).send(any(Notification.class));
    }

    @Test
    @DisplayName("Should throw ResourceNotFoundException when sending notification to non-existent user")
    void testSendNotificationUserNotFound() {
        when(userRepository.findById(userId)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () ->
                notificationService.send(
                        userId,
                        NotificationType.SYSTEM,
                        "Title",
                        "Message",
                        null,
                        null
                )
        );

        verify(notificationRepository, never()).save(any());
        verify(notificationChannel, never()).send(any());
    }

    @Test
    @DisplayName("Should mark notification as read for authorized owner")
    void testMarkAsReadSuccess() {
        UUID notificationId = UUID.randomUUID();
        Notification notification = Notification.builder()
                .id(notificationId)
                .user(testUser)
                .title("Test Notification")
                .message("Test Message")
                .isRead(false)
                .build();

        when(notificationRepository.findById(notificationId)).thenReturn(Optional.of(notification));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(i -> i.getArgument(0));

        NotificationDto result = notificationService.markAsRead(notificationId, userId);

        assertTrue(result.isRead());
        assertNotNull(result.getReadAt());
        verify(notificationRepository).save(notification);
    }

    @Test
    @DisplayName("Should throw ResourceNotFoundException when marking notification belonging to another user")
    void testMarkAsReadUnauthorizedUser() {
        UUID notificationId = UUID.randomUUID();
        User anotherUser = User.builder().id(UUID.randomUUID()).build();
        Notification notification = Notification.builder()
                .id(notificationId)
                .user(anotherUser)
                .build();

        when(notificationRepository.findById(notificationId)).thenReturn(Optional.of(notification));

        assertThrows(ResourceNotFoundException.class, () ->
                notificationService.markAsRead(notificationId, userId)
        );

        verify(notificationRepository, never()).save(any());
    }

    @Test
    @DisplayName("Should return correct unread notification count")
    void testGetUnreadCount() {
        when(notificationRepository.countByUserIdAndIsReadFalse(userId)).thenReturn(4L);

        long count = notificationService.getUnreadCount(userId);

        assertEquals(4L, count);
        verify(notificationRepository).countByUserIdAndIsReadFalse(userId);
    }

    @Test
    @DisplayName("Should return paginated in-app notification history")
    void testGetInAppHistory() {
        Pageable pageable = PageRequest.of(0, 10);
        Notification notification = Notification.builder()
                .id(UUID.randomUUID())
                .user(testUser)
                .title("Trip Dispatched")
                .message("Driver is on the way")
                .notificationType(NotificationType.TRIP_DISPATCH)
                .build();

        Page<Notification> mockPage = new PageImpl<>(List.of(notification), pageable, 1);
        when(notificationRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable)).thenReturn(mockPage);

        Page<NotificationDto> result = notificationService.getInAppHistory(userId, pageable);

        assertEquals(1, result.getTotalElements());
        assertEquals("Trip Dispatched", result.getContent().get(0).getTitle());
        verify(notificationRepository).findByUserIdOrderByCreatedAtDesc(userId, pageable);
    }
}
