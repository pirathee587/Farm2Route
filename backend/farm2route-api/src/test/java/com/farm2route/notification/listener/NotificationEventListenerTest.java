package com.farm2route.notification.listener;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.auth.entity.User;
import com.farm2route.common.enums.NotificationType;
import com.farm2route.common.event.BookingCreatedEvent;
import com.farm2route.common.event.IdempotentConsumerHelper;
import com.farm2route.farmer.entity.FarmerProfile;
import com.farm2route.farmer.repository.FarmerProfileRepository;
import com.farm2route.notification.service.NotificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NotificationEventListenerTest {

    @Mock
    private IdempotentConsumerHelper idempotentHelper;

    @Mock
    private NotificationService notificationService;

    @Mock
    private AgencyProfileRepository agencyProfileRepository;

    @Mock
    private FarmerProfileRepository farmerProfileRepository;

    private NotificationEventListener listener;

    private UUID farmerUserId;
    private UUID farmerProfileId;
    private UUID agencyUserId;
    private UUID agencyProfileId;

    @BeforeEach
    void setUp() {
        listener = new NotificationEventListener(
                idempotentHelper,
                notificationService,
                agencyProfileRepository,
                farmerProfileRepository
        );

        farmerUserId = UUID.randomUUID();
        farmerProfileId = UUID.randomUUID();
        agencyUserId = UUID.randomUUID();
        agencyProfileId = UUID.randomUUID();

        User farmerUser = User.builder().id(farmerUserId).build();
        FarmerProfile farmerProfile = FarmerProfile.builder().id(farmerProfileId).user(farmerUser).build();

        User agencyUser = User.builder().id(agencyUserId).build();
        AgencyProfile agencyProfile = AgencyProfile.builder().id(agencyProfileId).user(agencyUser).build();

        lenient().when(farmerProfileRepository.findById(farmerProfileId)).thenReturn(Optional.of(farmerProfile));
        lenient().when(agencyProfileRepository.findById(agencyProfileId)).thenReturn(Optional.of(agencyProfile));
    }

    @Test
    @DisplayName("handleBookingCreated persists notification for farmer and agency on first delivery")
    void testHandleBookingCreated_PersistsNotifications() {
        BookingCreatedEvent event = BookingCreatedEvent.builder()
                .bookingId(UUID.randomUUID())
                .bookingNumber("F2R-1001")
                .farmerId(farmerProfileId)
                .agencyId(agencyProfileId)
                .packageId(UUID.randomUUID())
                .totalAmount(new BigDecimal("5000.00"))
                .build();

        when(idempotentHelper.tryMarkProcessed(event.getEventId())).thenReturn(true);

        listener.handleBookingCreated(event);

        verify(notificationService, times(1)).create(
                eq(farmerUserId),
                eq(NotificationType.BOOKING_UPDATE),
                eq("Booking Confirmed"),
                contains("F2R-1001"),
                eq("BOOKING"),
                eq(event.getBookingId())
        );

        verify(notificationService, times(1)).create(
                eq(agencyUserId),
                eq(NotificationType.BOOKING_UPDATE),
                eq("New Booking Received"),
                contains("F2R-1001"),
                eq("BOOKING"),
                eq(event.getBookingId())
        );
    }

    @Test
    @DisplayName("handleBookingCreated respects idempotency and skips duplicate delivery")
    void testHandleBookingCreated_Idempotent_SkipsDuplicate() {
        BookingCreatedEvent event = BookingCreatedEvent.builder()
                .bookingId(UUID.randomUUID())
                .bookingNumber("F2R-1001")
                .farmerId(farmerProfileId)
                .agencyId(agencyProfileId)
                .build();

        when(idempotentHelper.tryMarkProcessed(event.getEventId())).thenReturn(false);

        listener.handleBookingCreated(event);

        verify(notificationService, never()).create(any(), any(), any(), any(), any(), any());
    }
}
