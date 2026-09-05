package com.farm2route.pod.service;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.enums.PodConfirmationStatus;
import com.farm2route.common.event.PodConfirmedEvent;
import com.farm2route.common.event.PodSubmittedEvent;
import com.farm2route.common.exception.ForbiddenException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.common.storage.SupabaseStorageService;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.farmer.entity.FarmerProfile;
import com.farm2route.pod.dto.ConfirmPodRequest;
import com.farm2route.pod.dto.PodDto;
import com.farm2route.pod.dto.SubmitPodRequest;
import com.farm2route.pod.entity.PodRecord;
import com.farm2route.pod.repository.PodRecordRepository;
import com.farm2route.tracking.entity.TripAssignment;
import com.farm2route.tracking.repository.TripAssignmentRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.mock.web.MockMultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PodServiceTest {

    @Mock
    private PodRecordRepository podRecordRepository;

    @Mock
    private BookingRepository bookingRepository;

    @Mock
    private TripAssignmentRepository tripAssignmentRepository;

    @Mock
    private SupabaseStorageService supabaseStorageService;

    @Mock
    private ApplicationEventPublisher eventPublisher;

    @InjectMocks
    private PodService podService;

    private UUID bookingId;
    private UUID driverUserId;
    private UUID farmerUserId;
    private Booking booking;
    private DriverProfile driverProfile;
    private TripAssignment tripAssignment;
    private MockMultipartFile signatureFile;
    private MockMultipartFile photoFile;

    @BeforeEach
    void setUp() {
        bookingId = UUID.randomUUID();
        driverUserId = UUID.randomUUID();
        farmerUserId = UUID.randomUUID();

        User farmerUser = User.builder().id(farmerUserId).role(Role.FARMER).build();
        FarmerProfile farmerProfile = FarmerProfile.builder().id(UUID.randomUUID()).user(farmerUser).build();

        User driverUser = User.builder().id(driverUserId).role(Role.DRIVER).build();
        driverProfile = DriverProfile.builder().id(UUID.randomUUID()).user(driverUser).fullName("Sunil Perera").build();

        booking = Booking.builder()
                .id(bookingId)
                .bookingNumber("BKG-10001")
                .farmer(farmerProfile)
                .status(BookingStatus.IN_TRANSIT)
                .build();

        tripAssignment = TripAssignment.builder()
                .id(UUID.randomUUID())
                .booking(booking)
                .driver(driverProfile)
                .build();

        signatureFile = new MockMultipartFile("signature", "sign.png", "image/png", "signature-content".getBytes());
        photoFile = new MockMultipartFile("photo", "delivery.jpg", "image/jpeg", "photo-content".getBytes());
    }

    @Test
    @DisplayName("submit POD happy path uploads files, persists record, and publishes PodSubmittedEvent")
    void testSubmit_HappyPath() throws IOException {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(tripAssignmentRepository.findByBookingId(bookingId)).thenReturn(Optional.of(tripAssignment));
        when(supabaseStorageService.uploadFile(eq(SupabaseStorageService.BUCKET_POD_PHOTOS), anyString(), eq(signatureFile)))
                .thenReturn("http://storage.com/sig.png");
        when(supabaseStorageService.uploadFile(eq(SupabaseStorageService.BUCKET_POD_PHOTOS), anyString(), eq(photoFile)))
                .thenReturn("http://storage.com/photo.jpg");
        when(podRecordRepository.save(any(PodRecord.class))).thenAnswer(inv -> inv.getArgument(0));

        SubmitPodRequest request = SubmitPodRequest.builder()
                .recipientName("Kamal Perera")
                .recipientPhone("+94770001111")
                .deliveryLatitude(BigDecimal.valueOf(6.9271))
                .deliveryLongitude(BigDecimal.valueOf(79.8612))
                .notes("Goods received in good condition")
                .build();

        PodDto result = podService.submit(bookingId, driverUserId, request, signatureFile, photoFile);

        assertNotNull(result);
        assertEquals("Kamal Perera", result.getRecipientName());
        assertEquals("http://storage.com/sig.png", result.getRecipientSignatureUrl());
        assertEquals("http://storage.com/photo.jpg", result.getDeliveryPhotoUrl());
        assertEquals(PodConfirmationStatus.PENDING, result.getFarmerConfirmationStatus());

        ArgumentCaptor<PodSubmittedEvent> eventCaptor = ArgumentCaptor.forClass(PodSubmittedEvent.class);
        verify(eventPublisher).publishEvent(eventCaptor.capture());
        assertEquals(bookingId, eventCaptor.getValue().getBookingId());
    }

    @Test
    @DisplayName("submit POD throws ForbiddenException when driver is not assigned to trip")
    void testSubmit_RejectsUnassignedDriver() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(tripAssignmentRepository.findByBookingId(bookingId)).thenReturn(Optional.of(tripAssignment));

        SubmitPodRequest request = SubmitPodRequest.builder()
                .recipientName("Kamal Perera")
                .recipientPhone("+94770001111")
                .deliveryLatitude(BigDecimal.valueOf(6.9271))
                .deliveryLongitude(BigDecimal.valueOf(79.8612))
                .build();

        UUID strangerDriverUserId = UUID.randomUUID();

        assertThrows(ForbiddenException.class, () ->
                podService.submit(bookingId, strangerDriverUserId, request, signatureFile, photoFile));
    }

    @Test
    @DisplayName("confirm set to CONFIRMED transitions Booking status to DELIVERED and publishes PodConfirmedEvent")
    void testConfirm_TransitionsBookingToDelivered() {
        PodRecord pod = PodRecord.builder()
                .id(UUID.randomUUID())
                .booking(booking)
                .driver(driverProfile)
                .farmerConfirmationStatus(PodConfirmationStatus.PENDING)
                .build();

        when(podRecordRepository.findByBookingId(bookingId)).thenReturn(Optional.of(pod));
        when(podRecordRepository.save(any(PodRecord.class))).thenAnswer(inv -> inv.getArgument(0));

        ConfirmPodRequest request = ConfirmPodRequest.builder()
                .status(PodConfirmationStatus.CONFIRMED)
                .notes("Verified and received")
                .build();

        PodDto result = podService.confirm(bookingId, farmerUserId, request);

        assertNotNull(result);
        assertEquals(PodConfirmationStatus.CONFIRMED, result.getFarmerConfirmationStatus());
        assertEquals(BookingStatus.DELIVERED, booking.getStatus());
        assertNotNull(booking.getActualDeliveryAt());

        verify(bookingRepository).save(booking);

        ArgumentCaptor<PodConfirmedEvent> eventCaptor = ArgumentCaptor.forClass(PodConfirmedEvent.class);
        verify(eventPublisher).publishEvent(eventCaptor.capture());
        assertEquals(bookingId, eventCaptor.getValue().getBookingId());
    }

    @Test
    @DisplayName("validateAndMarkDelivered guard blocks DELIVERED status transition if PodRecord is not CONFIRMED")
    void testValidateAndMarkDelivered_BlocksIfUnconfirmed() {
        PodRecord unconfirmedPod = PodRecord.builder()
                .id(UUID.randomUUID())
                .booking(booking)
                .farmerConfirmationStatus(PodConfirmationStatus.PENDING)
                .build();

        when(podRecordRepository.findByBookingId(bookingId)).thenReturn(Optional.of(unconfirmedPod));

        assertThrows(IllegalStateException.class, () -> podService.validateAndMarkDelivered(bookingId));
        assertNotEquals(BookingStatus.DELIVERED, booking.getStatus());
    }

    @Test
    @DisplayName("confirm throws ResourceNotFoundException if PodRecord missing")
    void testConfirm_NotFoundThrowsException() {
        UUID unknownBookingId = UUID.randomUUID();
        when(podRecordRepository.findByBookingId(unknownBookingId)).thenReturn(Optional.empty());

        ConfirmPodRequest request = ConfirmPodRequest.builder().status(PodConfirmationStatus.CONFIRMED).build();
        assertThrows(ResourceNotFoundException.class, () -> podService.confirm(unknownBookingId, farmerUserId, request));
    }
}
