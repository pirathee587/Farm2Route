package com.farm2route.incident.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.IncidentStatus;
import com.farm2route.common.enums.IncidentType;
import com.farm2route.common.event.IncidentStatusChangedEvent;
import com.farm2route.common.exception.BadRequestException;
import com.farm2route.farmer.entity.FarmerProfile;
import com.farm2route.finance.FinanceService;
import com.farm2route.incident.dto.AdminIncidentDetailDto;
import com.farm2route.incident.entity.IncidentReport;
import com.farm2route.incident.repository.IncidentRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdminIncidentDisputeTest {

    @Mock
    private IncidentRepository incidentRepository;

    @Mock
    private BookingRepository bookingRepository;

    @Mock
    private FinanceService financeService;

    @Mock
    private ApplicationEventPublisher eventPublisher;

    @InjectMocks
    private AdminIncidentService adminIncidentService;

    private UUID bookingId;
    private UUID farmerId;
    private UUID farmerUserId;
    private UUID agencyId;
    private UUID adminId;
    private Booking booking;

    @BeforeEach
    void setUp() {
        bookingId = UUID.randomUUID();
        farmerId = UUID.randomUUID();
        farmerUserId = UUID.randomUUID();
        agencyId = UUID.randomUUID();
        adminId = UUID.randomUUID();

        FarmerProfile farmerProfile = FarmerProfile.builder().id(farmerId).build();
        AgencyProfile agencyProfile = AgencyProfile.builder().id(agencyId).build();

        booking = Booking.builder()
                .id(bookingId)
                .bookingNumber("BKG-9900")
                .farmer(farmerProfile)
                .agency(agencyProfile)
                .build();
    }

    @Test
    @DisplayName("openFromPodDispute creates an IncidentReport with CARGO_DAMAGE and OPEN status")
    void testOpenFromPodDispute_CreatesIncidentCorrectly() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(incidentRepository.save(any(IncidentReport.class))).thenAnswer(inv -> {
            IncidentReport saved = inv.getArgument(0);
            saved.setId(UUID.randomUUID());
            return saved;
        });

        AdminIncidentDetailDto dto = adminIncidentService.openFromPodDispute(bookingId, farmerUserId, "Damaged apples on delivery");

        assertNotNull(dto);
        assertEquals(bookingId, dto.getBookingId());
        assertEquals(IncidentType.CARGO_DAMAGE, dto.getIncidentType());
        assertEquals("POD Delivery Disputed", dto.getTitle());
        assertEquals("Damaged apples on delivery", dto.getDescription());
        assertEquals(IncidentStatus.OPEN, dto.getStatus());

        ArgumentCaptor<IncidentStatusChangedEvent> eventCaptor = ArgumentCaptor.forClass(IncidentStatusChangedEvent.class);
        verify(eventPublisher).publishEvent(eventCaptor.capture());
        assertEquals(bookingId, eventCaptor.getValue().getBookingId());
    }

    @Test
    @DisplayName("decideRefund calls FinanceService with exact args and persists RESOLVED status and refund details")
    void testDecideRefund_CallsFinanceServiceAndPersists() {
        UUID incidentId = UUID.randomUUID();
        IncidentReport incident = IncidentReport.builder()
                .id(incidentId)
                .booking(booking)
                .reportedByUserId(farmerUserId)
                .incidentType(IncidentType.CARGO_DAMAGE)
                .status(IncidentStatus.INVESTIGATING)
                .build();

        BigDecimal refundAmount = BigDecimal.valueOf(5000.00);

        when(incidentRepository.findById(incidentId)).thenReturn(Optional.of(incident));
        when(financeService.refund(bookingId, farmerId, agencyId, refundAmount, adminId, "Partial damage compensation"))
                .thenReturn(new FinanceService.RefundResult(bookingId, refundAmount, FinanceService.RefundStatus.ACCEPTED_PENDING_PROCESSING));
        when(incidentRepository.save(any(IncidentReport.class))).thenAnswer(inv -> inv.getArgument(0));

        AdminIncidentDetailDto dto = adminIncidentService.decideRefund(incidentId, adminId, refundAmount, "Partial damage compensation");

        verify(financeService).refund(bookingId, farmerId, agencyId, refundAmount, adminId, "Partial damage compensation");
        assertEquals(IncidentStatus.RESOLVED, dto.getStatus());
        assertEquals(refundAmount, dto.getRefundAmount());
        assertEquals("Partial damage compensation", dto.getResolutionOutcome());
        assertEquals(adminId, dto.getResolvedByAdminId());
        assertNotNull(dto.getResolvedAt());

        verify(eventPublisher).publishEvent(any(IncidentStatusChangedEvent.class));
    }

    @Test
    @DisplayName("decideRefund propagates BadRequestException from FinanceService when refund amount is invalid")
    void testDecideRefund_PropagatesBadRequestException() {
        UUID incidentId = UUID.randomUUID();
        IncidentReport incident = IncidentReport.builder()
                .id(incidentId)
                .booking(booking)
                .status(IncidentStatus.OPEN)
                .build();

        when(incidentRepository.findById(incidentId)).thenReturn(Optional.of(incident));
        when(financeService.refund(bookingId, farmerId, agencyId, BigDecimal.ZERO, adminId, "Invalid zero refund"))
                .thenThrow(new BadRequestException("Refund amount must be positive"));

        BadRequestException ex = assertThrows(BadRequestException.class, () ->
                adminIncidentService.decideRefund(incidentId, adminId, BigDecimal.ZERO, "Invalid zero refund"));

        assertEquals("Refund amount must be positive", ex.getMessage());
        verify(incidentRepository, never()).save(any(IncidentReport.class));
    }

    @Test
    @DisplayName("recordAgencyResponse appends response to adminNotes")
    void testRecordAgencyResponse_AppendsToNotes() {
        UUID incidentId = UUID.randomUUID();
        IncidentReport incident = IncidentReport.builder()
                .id(incidentId)
                .booking(booking)
                .adminNotes("Existing note")
                .status(IncidentStatus.OPEN)
                .build();

        when(incidentRepository.findById(incidentId)).thenReturn(Optional.of(incident));
        when(incidentRepository.save(any(IncidentReport.class))).thenAnswer(inv -> inv.getArgument(0));

        UUID agencyUserId = UUID.randomUUID();
        AdminIncidentDetailDto dto = adminIncidentService.recordAgencyResponse(incidentId, agencyUserId, "We inspected the cargo before departure.");

        assertTrue(dto.getAdminNotes().contains("Existing note"));
        assertTrue(dto.getAdminNotes().contains("AGENCY RESPONSE"));
        assertTrue(dto.getAdminNotes().contains("We inspected the cargo before departure."));
    }
}
