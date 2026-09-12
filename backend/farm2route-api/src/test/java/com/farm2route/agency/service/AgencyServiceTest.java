package com.farm2route.agency.service;

import com.farm2route.agency.dto.AgencyResponse;
import com.farm2route.agency.dto.AgencySignupRequest;
import com.farm2route.agency.dto.AgencyStatusResponse;
import com.farm2route.agency.entity.Agency;
import com.farm2route.agency.entity.AgencyStatusHistory;
import com.farm2route.agency.enums.AgencyStatus;
import com.farm2route.agency.enums.AgencyType;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.agency.repository.AgencyRepository;
import com.farm2route.agency.repository.AgencyStatusHistoryRepository;
import com.farm2route.auth.model.OtpPurpose;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.auth.service.OtpService;
import com.farm2route.common.email.EmailSender;
import com.farm2route.common.event.AgencyRegisteredEvent;
import com.farm2route.common.exception.BadRequestException;
import com.farm2route.common.exception.DuplicateResourceException;
import jakarta.validation.ValidationException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AgencyServiceTest {

    @Mock
    private AgencyProfileRepository agencyProfileRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private AgencyRepository agencyRepository;

    @Mock
    private AgencyStatusHistoryRepository agencyStatusHistoryRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private ApplicationEventPublisher applicationEventPublisher;

    @Mock
    private OtpService otpService;

    @Mock
    private EmailSender emailSender;

    @InjectMocks
    private AgencyService agencyService;

    private AgencySignupRequest validRequest;
    private UUID agencyId;
    private Agency existingAgency;

    @BeforeEach
    void setUp() {
        agencyId = UUID.randomUUID();

        validRequest = AgencySignupRequest.builder()
                .agencyName("Lanka Agri Logistics")
                .email("info@lankalogistics.lk")
                .phoneNumber("+94771234567")
                .password("SecurePass123!")
                .confirmPassword("SecurePass123!")
                .agencyType(AgencyType.COMPANY)
                .businessRegNumber("PV-123456")
                .district("Colombo")
                .address("123 Harbour Road, Colombo 01")
                .contactPersonName("Sunil Perera")
                .build();

        existingAgency = Agency.builder()
                .id(agencyId)
                .agencyName("Lanka Agri Logistics")
                .email("info@lankalogistics.lk")
                .phoneNumber("+94771234567")
                .agencyType(AgencyType.COMPANY)
                .businessRegNumber("PV-123456")
                .district("Colombo")
                .address("123 Harbour Road, Colombo 01")
                .status(AgencyStatus.ACCOUNT_CREATED)
                .emailVerified(false)
                .phoneVerified(false)
                .emailVerificationToken("valid-email-token")
                .emailVerificationExpiresAt(Instant.now().plusSeconds(3600))
                .build();
    }

    @Test
    @DisplayName("signup() successfully saves agency with ACCOUNT_CREATED, dispatches email & SMS OTP")
    void testSignup_Success() {
        when(agencyRepository.existsByEmail(validRequest.getEmail())).thenReturn(false);
        when(agencyRepository.existsByPhoneNumber(validRequest.getPhoneNumber())).thenReturn(false);
        when(agencyRepository.existsByBusinessRegNumber("PV-123456")).thenReturn(false);
        when(passwordEncoder.encode(validRequest.getPassword())).thenReturn("bcrypt_hashed_password");

        when(agencyRepository.save(any(Agency.class))).thenAnswer(invocation -> {
            Agency agencyToSave = invocation.getArgument(0);
            agencyToSave.setId(agencyId);
            agencyToSave.setCreatedAt(Instant.now());
            agencyToSave.setUpdatedAt(Instant.now());
            return agencyToSave;
        });

        AgencyResponse response = agencyService.signup(validRequest);

        assertNotNull(response);
        assertEquals(agencyId, response.getId());
        assertEquals("Lanka Agri Logistics", response.getAgencyName());
        assertEquals("info@lankalogistics.lk", response.getEmail());
        assertEquals("+94771234567", response.getPhoneNumber());
        assertEquals(AgencyType.COMPANY, response.getAgencyType());
        assertEquals("PV-123456", response.getBusinessRegNumber());
        assertEquals(AgencyStatus.ACCOUNT_CREATED, response.getStatus());
        assertFalse(response.isEmailVerified());
        assertFalse(response.isPhoneVerified());

        verify(passwordEncoder).encode("SecurePass123!");
        verify(emailSender).sendVerificationEmail(eq("info@lankalogistics.lk"), anyString(), eq("Lanka Agri Logistics"));
        verify(otpService).generateAndSendOtp(eq("+94771234567"), eq(OtpPurpose.PHONE_VERIFICATION), eq(agencyId));
        verify(agencyStatusHistoryRepository).save(any(AgencyStatusHistory.class));
        // AgencyRegisteredEvent should NOT be published yet (only after dual verification)
        verify(applicationEventPublisher, never()).publishEvent(any(AgencyRegisteredEvent.class));
    }

    @Test
    @DisplayName("signup() throws ValidationException when businessRegNumber is missing for COMPANY")
    void testSignup_MissingBusinessRegNumber_ForCompany() {
        validRequest.setBusinessRegNumber(null);

        ValidationException exception = assertThrows(
                ValidationException.class,
                () -> agencyService.signup(validRequest)
        );

        assertTrue(exception.getMessage().contains("Business registration number is mandatory"));
        verify(agencyRepository, never()).save(any());
    }

    @Test
    @DisplayName("signup() throws DuplicateResourceException when email already exists")
    void testSignup_DuplicateEmail() {
        when(agencyRepository.existsByEmail(validRequest.getEmail())).thenReturn(true);

        DuplicateResourceException exception = assertThrows(
                DuplicateResourceException.class,
                () -> agencyService.signup(validRequest)
        );

        assertTrue(exception.getMessage().contains("email"));
        verify(agencyRepository, never()).save(any());
    }

    @Test
    @DisplayName("signup() throws DuplicateResourceException when phone number already exists")
    void testSignup_DuplicatePhoneNumber() {
        when(agencyRepository.existsByEmail(validRequest.getEmail())).thenReturn(false);
        when(agencyRepository.existsByPhoneNumber(validRequest.getPhoneNumber())).thenReturn(true);

        DuplicateResourceException exception = assertThrows(
                DuplicateResourceException.class,
                () -> agencyService.signup(validRequest)
        );

        assertTrue(exception.getMessage().contains("phone number"));
        verify(agencyRepository, never()).save(any());
    }

    @Test
    @DisplayName("signup() throws BadRequestException when password and confirmPassword do not match")
    void testSignup_PasswordMismatch() {
        validRequest.setConfirmPassword("MismatchPass456!");

        BadRequestException exception = assertThrows(
                BadRequestException.class,
                () -> agencyService.signup(validRequest)
        );

        assertEquals("Password and confirm password do not match", exception.getMessage());
        verify(agencyRepository, never()).save(any());
    }

    @Test
    @DisplayName("verifyEmail() succeeds and stays ACCOUNT_CREATED if phone is not yet verified")
    void testVerifyEmail_PhoneNotYetVerified() {
        when(agencyRepository.findById(agencyId)).thenReturn(Optional.of(existingAgency));
        when(agencyRepository.save(any(Agency.class))).thenAnswer(i -> i.getArgument(0));

        AgencyStatusResponse response = agencyService.verifyEmail(agencyId, "valid-email-token");

        assertTrue(response.isEmailVerified());
        assertFalse(response.isPhoneVerified());
        assertEquals(AgencyStatus.ACCOUNT_CREATED, response.getStatus());
        verify(applicationEventPublisher, never()).publishEvent(any(AgencyRegisteredEvent.class));
    }

    @Test
    @DisplayName("verifyPhone() succeeds and auto-transitions to PENDING_VERIFICATION when email is already verified")
    void testVerifyPhone_AutoTransitionsToPendingVerification() {
        existingAgency.setEmailVerified(true);
        when(agencyRepository.findById(agencyId)).thenReturn(Optional.of(existingAgency));
        when(otpService.verifyOtp(existingAgency.getPhoneNumber(), "123456", OtpPurpose.PHONE_VERIFICATION)).thenReturn(true);
        when(agencyRepository.save(any(Agency.class))).thenAnswer(i -> i.getArgument(0));

        AgencyStatusResponse response = agencyService.verifyPhone(agencyId, "123456");

        assertTrue(response.isPhoneVerified());
        assertTrue(response.isEmailVerified());
        assertEquals(AgencyStatus.PENDING_VERIFICATION, response.getStatus());

        verify(agencyStatusHistoryRepository).save(any(AgencyStatusHistory.class));
        verify(applicationEventPublisher).publishEvent(any(AgencyRegisteredEvent.class));
    }

    @Test
    @DisplayName("approveAgency() transitions agency status to APPROVED and logs history")
    void testApproveAgency() {
        existingAgency.setStatus(AgencyStatus.PENDING_VERIFICATION);
        when(agencyRepository.findById(agencyId)).thenReturn(Optional.of(existingAgency));
        when(agencyRepository.save(any(Agency.class))).thenAnswer(i -> i.getArgument(0));

        UUID adminId = UUID.randomUUID();
        AgencyResponse response = agencyService.approveAgency(agencyId, adminId);

        assertEquals(AgencyStatus.APPROVED, response.getStatus());
        ArgumentCaptor<AgencyStatusHistory> historyCaptor = ArgumentCaptor.forClass(AgencyStatusHistory.class);
        verify(agencyStatusHistoryRepository).save(historyCaptor.capture());
        assertEquals("APPROVED", historyCaptor.getValue().getNewStatus());
        assertEquals(adminId.toString(), historyCaptor.getValue().getChangedBy());
    }

    @Test
    @DisplayName("rejectAgency() sets status REJECTED, stores rejection reason and logs history")
    void testRejectAgency() {
        existingAgency.setStatus(AgencyStatus.PENDING_VERIFICATION);
        when(agencyRepository.findById(agencyId)).thenReturn(Optional.of(existingAgency));
        when(agencyRepository.save(any(Agency.class))).thenAnswer(i -> i.getArgument(0));

        UUID adminId = UUID.randomUUID();
        String reason = "Business registration document is expired";
        AgencyResponse response = agencyService.rejectAgency(agencyId, reason, adminId);

        assertEquals(AgencyStatus.REJECTED, response.getStatus());
        assertEquals(reason, response.getRejectionReason());
        assertNotNull(response.getRejectedAt());

        ArgumentCaptor<AgencyStatusHistory> historyCaptor = ArgumentCaptor.forClass(AgencyStatusHistory.class);
        verify(agencyStatusHistoryRepository).save(historyCaptor.capture());
        assertEquals("REJECTED", historyCaptor.getValue().getNewStatus());
        assertEquals(reason, historyCaptor.getValue().getNotes());
    }
}
