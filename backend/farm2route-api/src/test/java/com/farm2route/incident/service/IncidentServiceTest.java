package com.farm2route.incident.service;

import com.farm2route.audit.service.AuditService;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.enums.IncidentStatus;
import com.farm2route.common.enums.IncidentType;
import com.farm2route.common.exception.BadRequestException;
import com.farm2route.common.exception.ForbiddenException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.common.storage.SupabaseStorageService;
import com.farm2route.farmer.entity.FarmerProfile;
import com.farm2route.incident.dto.IncidentResponse;
import com.farm2route.incident.dto.SubmitIncidentRequest;
import com.farm2route.incident.entity.IncidentReport;
import com.farm2route.incident.repository.IncidentEvidenceRepository;
import com.farm2route.incident.repository.IncidentRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class IncidentServiceTest {

    @Mock
    private IncidentRepository incidentRepository;

    @Mock
    private IncidentEvidenceRepository evidenceRepository;

    @Mock
    private BookingRepository bookingRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private SupabaseStorageService storageService;

    @Mock
    private AuditService auditService;

    @InjectMocks
    private IncidentService incidentService;

    private UUID farmerUserId;
    private UUID otherUserId;
    private UUID bookingId;
    private UUID incidentId;
    private User farmerUser;
    private FarmerProfile farmerProfile;
    private Booking booking;
    private SubmitIncidentRequest submitRequest;

    @BeforeEach
    void setUp() {
        farmerUserId = UUID.randomUUID();
        otherUserId = UUID.randomUUID();
        bookingId = UUID.randomUUID();
        incidentId = UUID.randomUUID();

        farmerUser = User.builder()
                .id(farmerUserId)
                .email("farmer@farm2route.lk")
                .phoneNumber("+94771122334")
                .role(Role.FARMER)
                .status(UserStatus.ACTIVE)
                .build();

        farmerProfile = FarmerProfile.builder()
                .id(UUID.randomUUID())
                .user(farmerUser)
                .farmName("Bandara Organic Greens")
                .address("Galgamuwa")
                .district("Kurunegala")
                .province("Wayamba")
                .build();

        booking = Booking.builder()
                .id(bookingId)
                .bookingNumber("F2R-1788414881727-1001")
                .farmer(farmerProfile)
                .cargoType("Vegetables")
                .cargoWeightKg(new BigDecimal("1500.00"))
                .pickupAddress("Galgamuwa Farm")
                .deliveryAddress("Pettah Central Market")
                .status(BookingStatus.IN_TRANSIT)
                .build();

        submitRequest = SubmitIncidentRequest.builder()
                .bookingId(bookingId)
                .incidentType(IncidentType.CROP_DAMAGE)
                .title("Crushed tomato crates during transit")
                .description("Over 20 crates were damaged due to improper stacking by driver.")
                .build();
    }

    @Test
    @DisplayName("Submit incident successfully with evidence photos")
    void testSubmitIncident_Success() throws IOException {
        MockMultipartFile photo1 = new MockMultipartFile("evidencePhotos", "damage1.jpg", "image/jpeg", new byte[]{1, 2, 3});
        MockMultipartFile photo2 = new MockMultipartFile("evidencePhotos", "damage2.png", "image/png", new byte[]{4, 5, 6});

        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(storageService.uploadFile(eq(SupabaseStorageService.BUCKET_INCIDENT_EVIDENCE), any(), any()))
                .thenReturn("https://storage.supabase.co/damage1.jpg")
                .thenReturn("https://storage.supabase.co/damage2.png");

        when(incidentRepository.save(any(IncidentReport.class))).thenAnswer(inv -> {
            IncidentReport report = inv.getArgument(0);
            report.setId(incidentId);
            report.setCreatedAt(Instant.now());
            return report;
        });
        when(userRepository.findById(farmerUserId)).thenReturn(Optional.of(farmerUser));

        IncidentResponse response = incidentService.submitIncident(farmerUserId, submitRequest, new MultipartFile[]{photo1, photo2});

        assertThat(response).isNotNull();
        assertThat(response.getId()).isEqualTo(incidentId);
        assertThat(response.getBookingId()).isEqualTo(bookingId);
        assertThat(response.getBookingNumber()).isEqualTo(booking.getBookingNumber());
        assertThat(response.getIncidentType()).isEqualTo(IncidentType.CROP_DAMAGE);
        assertThat(response.getStatus()).isEqualTo(IncidentStatus.OPEN);
        assertThat(response.getEvidencePhotoUrls()).hasSize(2);

        verify(incidentRepository, atLeastOnce()).save(any(IncidentReport.class));
        verify(storageService, times(2)).uploadFile(eq(SupabaseStorageService.BUCKET_INCIDENT_EVIDENCE), any(), any());
    }

    @Test
    @DisplayName("Submit incident without evidence photos succeeds (evidence is optional)")
    void testSubmitIncident_NoEvidencePhotos_StillSucceeds() throws IOException {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(incidentRepository.save(any(IncidentReport.class))).thenAnswer(inv -> {
            IncidentReport report = inv.getArgument(0);
            report.setId(incidentId);
            report.setCreatedAt(Instant.now());
            return report;
        });

        IncidentResponse response = incidentService.submitIncident(farmerUserId, submitRequest, null);

        assertThat(response).isNotNull();
        assertThat(response.getId()).isEqualTo(incidentId);
        assertThat(response.getEvidencePhotoUrls()).isEmpty();
        assertThat(response.getStatus()).isEqualTo(IncidentStatus.OPEN);

        verify(storageService, never()).uploadFile(any(), any(), any());
        verify(incidentRepository, times(1)).save(any(IncidentReport.class));
    }

    @Test
    @DisplayName("Submit incident throws ForbiddenException when booking does not belong to requesting farmer")
    void testSubmitIncident_BookingNotOwnedByFarmer_ThrowsForbidden() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));

        assertThatThrownBy(() -> incidentService.submitIncident(otherUserId, submitRequest, null))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("not authorized to report an incident for this booking");

        verify(incidentRepository, never()).save(any());
    }

    @Test
    @DisplayName("Submit incident throws ResourceNotFoundException when booking does not exist")
    void testSubmitIncident_BookingNotFound_ThrowsNotFound() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> incidentService.submitIncident(farmerUserId, submitRequest, null))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Booking not found");

        verify(incidentRepository, never()).save(any());
    }

    @Test
    @DisplayName("Submit incident throws BadRequestException when more than 5 photos uploaded")
    void testSubmitIncident_TooManyPhotos_ThrowsBadRequest() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));

        MultipartFile[] sixPhotos = new MultipartFile[6];
        for (int i = 0; i < 6; i++) {
            sixPhotos[i] = new MockMultipartFile("photos", "pic" + i + ".jpg", "image/jpeg", new byte[]{1, 2});
        }

        assertThatThrownBy(() -> incidentService.submitIncident(farmerUserId, submitRequest, sixPhotos))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Maximum of 5 evidence photos allowed");

        verify(incidentRepository, never()).save(any());
    }

    @Test
    @DisplayName("Submit incident throws BadRequestException when photo exceeds 5MB")
    void testSubmitIncident_OversizedPhoto_ThrowsBadRequest() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));

        byte[] largeBytes = new byte[6 * 1024 * 1024]; // 6MB
        MockMultipartFile largePhoto = new MockMultipartFile("photos", "huge.jpg", "image/jpeg", largeBytes);

        assertThatThrownBy(() -> incidentService.submitIncident(farmerUserId, submitRequest, new MultipartFile[]{largePhoto}))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("exceeds maximum size of 5MB");

        verify(incidentRepository, never()).save(any());
    }

    @Test
    @DisplayName("Get farmer incidents with status filter returns matching reports")
    void testGetFarmerIncidents_FiltersByStatus() {
        IncidentReport incident = IncidentReport.builder()
                .id(incidentId)
                .booking(booking)
                .reportedByUserId(farmerUserId)
                .incidentType(IncidentType.DELAY)
                .title("Transit delay")
                .description("Driver arrived 4 hours late")
                .status(IncidentStatus.OPEN)
                .createdAt(Instant.now())
                .build();

        Pageable pageable = PageRequest.of(0, 10);
        when(incidentRepository.findByReportedByUserIdAndStatusOrderByCreatedAtDesc(farmerUserId, IncidentStatus.OPEN, pageable))
                .thenReturn(new PageImpl<>(List.of(incident)));

        Page<IncidentResponse> results = incidentService.getFarmerIncidents(farmerUserId, IncidentStatus.OPEN, pageable);

        assertThat(results).isNotNull();
        assertThat(results.getContent()).hasSize(1);
        assertThat(results.getContent().get(0).getStatus()).isEqualTo(IncidentStatus.OPEN);
        verify(incidentRepository, times(1))
                .findByReportedByUserIdAndStatusOrderByCreatedAtDesc(farmerUserId, IncidentStatus.OPEN, pageable);
    }

    @Test
    @DisplayName("Get incident by ID succeeds when requester is the owner")
    void testGetIncidentById_Success() {
        IncidentReport incident = IncidentReport.builder()
                .id(incidentId)
                .booking(booking)
                .reportedByUserId(farmerUserId)
                .incidentType(IncidentType.CROP_DAMAGE)
                .title("Damaged produce")
                .description("Produce damaged due to rough handling")
                .status(IncidentStatus.OPEN)
                .evidenceList(new ArrayList<>())
                .createdAt(Instant.now())
                .build();

        when(incidentRepository.findById(incidentId)).thenReturn(Optional.of(incident));

        IncidentResponse response = incidentService.getIncidentById(farmerUserId, incidentId);

        assertThat(response).isNotNull();
        assertThat(response.getId()).isEqualTo(incidentId);
        assertThat(response.getBookingNumber()).isEqualTo(booking.getBookingNumber());
    }

    @Test
    @DisplayName("Get incident by ID throws ForbiddenException when requester is not owner")
    void testGetIncidentById_NotOwner_ThrowsForbidden() {
        IncidentReport incident = IncidentReport.builder()
                .id(incidentId)
                .booking(booking)
                .reportedByUserId(farmerUserId)
                .incidentType(IncidentType.CROP_DAMAGE)
                .title("Damaged produce")
                .description("Produce damaged")
                .status(IncidentStatus.OPEN)
                .build();

        when(incidentRepository.findById(incidentId)).thenReturn(Optional.of(incident));

        assertThatThrownBy(() -> incidentService.getIncidentById(otherUserId, incidentId))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("not authorized to view this incident report");
    }

    @Test
    @DisplayName("Get incident by ID throws ResourceNotFoundException when incident does not exist")
    void testGetIncidentById_NotFound_ThrowsNotFound() {
        when(incidentRepository.findById(incidentId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> incidentService.getIncidentById(farmerUserId, incidentId))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Incident report not found");
    }
}
