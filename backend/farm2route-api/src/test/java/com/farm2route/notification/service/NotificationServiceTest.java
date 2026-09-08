package com.farm2route.notification.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.common.enums.NotificationType;
import com.farm2route.common.exception.ForbiddenException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.notification.dto.NotificationDto;
import com.farm2route.notification.entity.Notification;
import com.farm2route.notification.repository.NotificationRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {
    @Mock NotificationRepository repository;
    @Mock UserRepository userRepository;
    @Mock AgencyProfileRepository agencyRepository;
    @InjectMocks NotificationService service;

    @Test
    void listsAndCountsOnlyRecipientNotifications() {
        UUID userId = UUID.randomUUID();
        Notification notification = Notification.builder().id(UUID.randomUUID()).title("Booking")
                .message("Received").notificationType(NotificationType.BOOKING_UPDATE).build();
        when(repository.findByRecipientIdOrderByCreatedAtDesc(userId)).thenReturn(List.of(notification));
        when(repository.countByRecipientIdAndReadFalse(userId)).thenReturn(1L);
        assertThat(service.list(userId)).hasSize(1);
        assertThat(service.unreadCount(userId)).isOne();
    }

    @Test
    void markReadCannotCrossRecipientBoundary() {
        UUID userId = UUID.randomUUID();
        when(repository.findByIdAndRecipientId(any(), eq(userId))).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.markRead(userId, UUID.randomUUID()))
                .isInstanceOf(ResourceNotFoundException.class);
        verify(repository, never()).save(any());
    }

    @Test
    void createsNotificationForAgencyUser() {
        UUID agencyId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        User user = User.builder().id(userId).build();
        AgencyProfile agency = AgencyProfile.builder().id(agencyId).user(user).build();
        when(agencyRepository.findById(agencyId)).thenReturn(Optional.of(agency));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(repository.save(any(Notification.class))).thenAnswer(invocation -> invocation.getArgument(0));
        Notification created = service.createForAgency(agencyId, NotificationType.KYC_STATUS, "KYC", "Updated",
                "VEHICLE", UUID.randomUUID());
        assertThat(created.getRecipient()).isSameAs(user);
    }

    @Test
    void createReturnsUserScopedDto() {
        UUID userId = UUID.randomUUID();
        User user = User.builder().id(userId).build();
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(repository.save(any(Notification.class))).thenAnswer(invocation -> invocation.getArgument(0));
        NotificationDto result = service.create(userId, NotificationType.BOOKING_UPDATE, "Booking", "Created", "BOOKING", null);
        assertThat(result.getUserId()).isEqualTo(userId);
    }

    @Test
    void markAsReadRejectsAnotherRecipient() {
        UUID ownerId = UUID.randomUUID();
        Notification notification = Notification.builder().recipient(User.builder().id(ownerId).build()).build();
        UUID notificationId = UUID.randomUUID();
        when(repository.findById(notificationId)).thenReturn(Optional.of(notification));
        assertThatThrownBy(() -> service.markAsRead(notificationId, UUID.randomUUID()))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void getHistoryReturnsPagedNotifications() {
        UUID userId = UUID.randomUUID();
        Pageable pageable = PageRequest.of(0, 10);
        Notification notification = Notification.builder().recipient(User.builder().id(userId).build()).build();
        when(repository.findByRecipientIdOrderByCreatedAtDesc(userId, pageable))
                .thenReturn(new PageImpl<>(List.of(notification), pageable, 1));
        Page<NotificationDto> result = service.getHistory(userId, pageable);
        assertThat(result.getTotalElements()).isOne();
    }
}
