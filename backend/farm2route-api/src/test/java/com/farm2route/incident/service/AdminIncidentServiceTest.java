package com.farm2route.incident.service;

import com.farm2route.common.enums.IncidentStatus;
import com.farm2route.common.enums.IncidentType;
import com.farm2route.common.event.IncidentEscalatedEvent;
import com.farm2route.common.event.IncidentStatusChangedEvent;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.incident.dto.AdminIncidentDetailDto;
import com.farm2route.incident.dto.ResolveIncidentRequest;
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

import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.finance.FinanceService;

@ExtendWith(MockitoExtension.class)
class AdminIncidentServiceTest {

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

    private UUID incidentId;
    private UUID reportedByUserId;
    private UUID adminId;
    private IncidentReport incident;

    @BeforeEach
    void setUp() {
        incidentId = UUID.randomUUID();
        reportedByUserId = UUID.randomUUID();
        adminId = UUID.randomUUID();

        incident = IncidentReport.builder()
                .id(incidentId)
                .reportedByUserId(reportedByUserId)
                .incidentType(IncidentType.CARGO_DAMAGE)
                .title("Cargo Damaged during Transit")
                .description("Produce packages crushed due to improper handling")
                .status(IncidentStatus.OPEN)
                .build();
    }

    @Test
    @DisplayName("addInvestigationNote transitions status OPEN -> INVESTIGATING and publishes IncidentStatusChangedEvent")
    void testAddInvestigationNote_TransitionsOpenToInvestigating() {
        when(incidentRepository.findById(incidentId)).thenReturn(Optional.of(incident));
        when(incidentRepository.save(any(IncidentReport.class))).thenAnswer(inv -> inv.getArgument(0));

        AdminIncidentDetailDto result = adminIncidentService.addInvestigationNote(incidentId, "Contacted agency driver", adminId);

        assertNotNull(result);
        assertEquals(IncidentStatus.INVESTIGATING, result.getStatus());
        assertTrue(result.getInvestigationNotes().contains("Contacted agency driver"));

        ArgumentCaptor<IncidentStatusChangedEvent> eventCaptor = ArgumentCaptor.forClass(IncidentStatusChangedEvent.class);
        verify(eventPublisher).publishEvent(eventCaptor.capture());

        IncidentStatusChangedEvent event = eventCaptor.getValue();
        assertEquals(incidentId, event.getIncidentId());
        assertEquals(IncidentStatus.OPEN, event.getOldStatus());
        assertEquals(IncidentStatus.INVESTIGATING, event.getNewStatus());
        assertEquals(adminId, event.getAdminId());
    }

    @Test
    @DisplayName("resolve transitions status to RESOLVED and invokes refund hook if refund amount present")
    void testResolve_ResolvedOutcomeWithRefund() {
        incident.setStatus(IncidentStatus.INVESTIGATING);
        when(incidentRepository.findById(incidentId)).thenReturn(Optional.of(incident));
        when(financeService.refund(any(), any(), any(), eq(BigDecimal.valueOf(15000.00)), eq(adminId), eq("Full refund issued to farmer")))
                .thenReturn(new FinanceService.RefundResult(null, BigDecimal.valueOf(15000.00), FinanceService.RefundStatus.ACCEPTED_PENDING_PROCESSING));
        when(incidentRepository.save(any(IncidentReport.class))).thenAnswer(inv -> inv.getArgument(0));

        ResolveIncidentRequest request = ResolveIncidentRequest.builder()
                .status(IncidentStatus.RESOLVED)
                .notes("Full refund issued to farmer")
                .refundAmount(BigDecimal.valueOf(15000.00))
                .build();

        AdminIncidentDetailDto result = adminIncidentService.resolve(incidentId, request, adminId);

        assertNotNull(result);
        assertEquals(IncidentStatus.RESOLVED, result.getStatus());
        assertEquals("Full refund issued to farmer", result.getResolutionOutcome());
        assertEquals(adminId, result.getResolvedByAdminId());
        assertEquals(BigDecimal.valueOf(15000.00), result.getRefundAmount());
        assertNotNull(result.getResolvedAt());

        ArgumentCaptor<IncidentStatusChangedEvent> eventCaptor = ArgumentCaptor.forClass(IncidentStatusChangedEvent.class);
        verify(eventPublisher).publishEvent(eventCaptor.capture());
        assertEquals(IncidentStatus.INVESTIGATING, eventCaptor.getValue().getOldStatus());
        assertEquals(IncidentStatus.RESOLVED, eventCaptor.getValue().getNewStatus());
    }

    @Test
    @DisplayName("resolve transitions status to REJECTED when request status is REJECTED")
    void testResolve_RejectedOutcome() {
        when(incidentRepository.findById(incidentId)).thenReturn(Optional.of(incident));
        when(incidentRepository.save(any(IncidentReport.class))).thenAnswer(inv -> inv.getArgument(0));

        ResolveIncidentRequest request = ResolveIncidentRequest.builder()
                .status(IncidentStatus.REJECTED)
                .notes("Insufficient evidence provided")
                .build();

        AdminIncidentDetailDto result = adminIncidentService.resolve(incidentId, request, adminId);

        assertEquals(IncidentStatus.REJECTED, result.getStatus());
        assertEquals("Insufficient evidence provided", result.getResolutionOutcome());
    }

    @Test
    @DisplayName("escalate appends ESCALATED note, leaves status unchanged, and publishes IncidentEscalatedEvent")
    void testEscalate_AppendsNoteAndFiresEventWithoutChangingStatus() {
        incident.setStatus(IncidentStatus.INVESTIGATING);
        when(incidentRepository.findById(incidentId)).thenReturn(Optional.of(incident));
        when(incidentRepository.save(any(IncidentReport.class))).thenAnswer(inv -> inv.getArgument(0));

        AdminIncidentDetailDto result = adminIncidentService.escalate(incidentId, "High value claim require senior management review", adminId);

        assertNotNull(result);
        assertEquals(IncidentStatus.INVESTIGATING, result.getStatus()); // Status unchanged!
        assertTrue(result.getInvestigationNotes().contains("ESCALATED: High value claim require senior management review"));

        ArgumentCaptor<IncidentEscalatedEvent> eventCaptor = ArgumentCaptor.forClass(IncidentEscalatedEvent.class);
        verify(eventPublisher).publishEvent(eventCaptor.capture());

        IncidentEscalatedEvent event = eventCaptor.getValue();
        assertEquals(incidentId, event.getIncidentId());
        assertEquals(adminId, event.getAdminId());
        assertEquals("High value claim require senior management review", event.getNotes());
    }

    @Test
    @DisplayName("getDetail throws ResourceNotFoundException for bad incident ID")
    void testGetDetail_NotFoundThrowsException() {
        UUID unknownId = UUID.randomUUID();
        when(incidentRepository.findById(unknownId)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> adminIncidentService.getDetail(unknownId));
    }
}
