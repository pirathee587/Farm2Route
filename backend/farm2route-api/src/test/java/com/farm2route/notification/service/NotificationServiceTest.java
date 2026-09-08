package com.farm2route.notification.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.common.enums.NotificationType;
import com.farm2route.notification.entity.Notification;
import com.farm2route.notification.repository.NotificationRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
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
        verify(repository).findByRecipientIdOrderByCreatedAtDesc(userId);
        verify(repository).countByRecipientIdAndReadFalse(userId);
    }

    @Test
    void markReadCannotCrossRecipientBoundary() {
        UUID userId = UUID.randomUUID();
        when(repository.findByIdAndRecipientId(any(), eq(userId))).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.markRead(userId, UUID.randomUUID()))
                .isInstanceOf(com.farm2route.common.exception.ResourceNotFoundException.class);
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
        assertThat(created.getNotificationType()).isEqualTo(NotificationType.KYC_STATUS);
    }
}
