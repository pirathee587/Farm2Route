package com.farm2route.farmer.service;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.OtpPurpose;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.auth.service.OtpService;
import com.farm2route.common.event.FarmerRegisteredEvent;
import com.farm2route.common.exception.DuplicatePhoneException;
import com.farm2route.common.exception.ExpiredOtpException;
import com.farm2route.common.exception.InvalidOtpException;
import com.farm2route.common.exception.OtpExpiredException;
import com.farm2route.common.exception.OtpMismatchException;
import com.farm2route.farmer.dto.FarmerOtpRequest;
import com.farm2route.farmer.dto.FarmerOtpResponse;
import com.farm2route.farmer.dto.FarmerResponse;
import com.farm2route.farmer.dto.FarmerVerifyRequest;
import com.farm2route.farmer.entity.Farmer;
import com.farm2route.farmer.enums.CropType;
import com.farm2route.farmer.enums.FarmerStatus;
import com.farm2route.farmer.enums.PreferredLanguage;
import com.farm2route.farmer.repository.FarmerProfileRepository;
import com.farm2route.farmer.repository.FarmerRepository;
import com.farm2route.security.JwtService;
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

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FarmerServiceTest {

    @Mock
    private FarmerProfileRepository farmerProfileRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private FarmerRepository farmerRepository;

    @Mock
    private OtpService otpService;

    @Mock
    private JwtService jwtService;

    @Mock
    private ApplicationEventPublisher applicationEventPublisher;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private FarmerService farmerService;

    private FarmerOtpRequest validOtpRequest;
    private FarmerVerifyRequest validVerifyRequest;

    @BeforeEach
    void setUp() {
        validOtpRequest = FarmerOtpRequest.builder()
                .phoneNumber("+94771234567")
                .build();

        validVerifyRequest = FarmerVerifyRequest.builder()
                .phoneNumber("+94771234567")
                .otp("123456")
                .fullName("Kamal Perera")
                .district("Anuradhapura")
                .gnDivision("Medawachchiya-North")
                .address("45 Field Track, Medawachchiya")
                .email("kamal.perera@example.lk")
                .latitude(8.5342)
                .longitude(80.4958)
                .farmSizeAcres(BigDecimal.valueOf(3.5))
                .primaryCrops(List.of(CropType.GRAINS, CropType.VEGETABLES))
                .preferredLanguage(PreferredLanguage.SI)
                .bankAccountNumber("1234567890")
                .mobileWalletNumber("0771234567")
                .nicNumber("198512345678")
                .build();
    }

    @Test
    @DisplayName("requestOtp() successfully generates and sends OTP when phone is not registered")
    void testRequestOtp_Success() {
        when(farmerRepository.existsByPhoneNumber(validOtpRequest.getPhoneNumber())).thenReturn(false);

        FarmerOtpResponse response = farmerService.requestOtp(validOtpRequest);

        assertNotNull(response);
        assertEquals("+94771234567", response.getPhoneNumber());
        assertTrue(response.getMessage().contains("+94771234567"));

        verify(farmerRepository).existsByPhoneNumber("+94771234567");
        verify(otpService).generateAndSendOtp("+94771234567", OtpPurpose.REGISTRATION, null);
    }

    @Test
    @DisplayName("requestOtp() throws DuplicatePhoneException when phone is already registered")
    void testRequestOtp_DuplicatePhone_ThrowsDuplicatePhoneException() {
        when(farmerRepository.existsByPhoneNumber(validOtpRequest.getPhoneNumber())).thenReturn(true);

        DuplicatePhoneException exception = assertThrows(
                DuplicatePhoneException.class,
                () -> farmerService.requestOtp(validOtpRequest)
        );

        assertTrue(exception.getMessage().contains("+94771234567"));
        verify(farmerRepository).existsByPhoneNumber("+94771234567");
        verify(otpService, never()).generateAndSendOtp(anyString(), any(), any());
    }

    @Test
    @DisplayName("verifyAndSignup() successfully verifies OTP, creates Farmer and User records, publishes event, and returns JWT")
    void testVerifyAndSignup_Success() {
        UUID farmerId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();

        when(farmerRepository.existsByPhoneNumber(validVerifyRequest.getPhoneNumber())).thenReturn(false);
        when(otpService.verifyOtp(validVerifyRequest.getPhoneNumber(), validVerifyRequest.getOtp(), OtpPurpose.REGISTRATION))
                .thenReturn(true);

        when(farmerRepository.save(any(Farmer.class))).thenAnswer(invocation -> {
            Farmer saved = invocation.getArgument(0);
            saved.setId(farmerId);
            saved.setCreatedAt(Instant.now());
            saved.setUpdatedAt(Instant.now());
            return saved;
        });

        when(userRepository.findByPhoneNumber(validVerifyRequest.getPhoneNumber())).thenReturn(Optional.empty());
        when(passwordEncoder.encode(anyString())).thenReturn("hashed_dummy_password");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User saved = invocation.getArgument(0);
            saved.setId(userId);
            return saved;
        });

        when(jwtService.generateToken(eq(userId), eq("FARMER"), eq("+94771234567")))
                .thenReturn("mocked.jwt.token");

        FarmerResponse response = farmerService.verifyAndSignup(validVerifyRequest);

        assertNotNull(response);
        assertEquals(farmerId, response.getId());
        assertEquals("Kamal Perera", response.getFullName());
        assertEquals("+94771234567", response.getPhoneNumber());
        assertEquals("kamal.perera@example.lk", response.getEmail());
        assertEquals("Anuradhapura", response.getDistrict());
        assertEquals("Medawachchiya-North", response.getGnDivision());
        assertEquals("45 Field Track, Medawachchiya", response.getAddress());
        assertEquals(8.5342, response.getLatitude());
        assertEquals(80.4958, response.getLongitude());
        assertEquals(BigDecimal.valueOf(3.5), response.getFarmSizeAcres());
        assertEquals(PreferredLanguage.SI, response.getPreferredLanguage());
        assertEquals(Set.of(CropType.GRAINS, CropType.VEGETABLES), response.getPrimaryCrops());
        assertTrue(response.isPhoneVerified());
        assertEquals(FarmerStatus.ACTIVE, response.getStatus());
        assertEquals("mocked.jwt.token", response.getToken());
        assertEquals("Bearer", response.getTokenType());

        // Verify Farmer entity persistence
        ArgumentCaptor<Farmer> farmerCaptor = ArgumentCaptor.forClass(Farmer.class);
        verify(farmerRepository).save(farmerCaptor.capture());
        Farmer savedFarmer = farmerCaptor.getValue();
        assertTrue(savedFarmer.isPhoneVerified());
        assertEquals(FarmerStatus.ACTIVE, savedFarmer.getStatus());
        assertEquals("1234567890", savedFarmer.getBankAccountNumber());
        assertEquals("0771234567", savedFarmer.getMobileWalletNumber());

        // Verify User entity persistence
        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(userCaptor.capture());
        User savedUser = userCaptor.getValue();
        assertEquals("+94771234567", savedUser.getPhoneNumber());
        assertEquals(Role.FARMER, savedUser.getRole());
        assertEquals(UserStatus.ACTIVE, savedUser.getStatus());
        assertTrue(savedUser.isPhoneVerified());

        // Verify FarmerRegisteredEvent publication
        ArgumentCaptor<FarmerRegisteredEvent> eventCaptor = ArgumentCaptor.forClass(FarmerRegisteredEvent.class);
        verify(applicationEventPublisher).publishEvent(eventCaptor.capture());
        FarmerRegisteredEvent publishedEvent = eventCaptor.getValue();
        assertEquals(farmerId, publishedEvent.getFarmerId());
        assertEquals("Kamal Perera", publishedEvent.getFullName());
        assertEquals("+94771234567", publishedEvent.getPhoneNumber());
        assertEquals("Anuradhapura", publishedEvent.getDistrict());
        assertEquals(PreferredLanguage.SI, publishedEvent.getPreferredLanguage());
        assertEquals("farmer.registered", publishedEvent.getEventType());
    }

    @Test
    @DisplayName("verifyAndSignup() throws OtpExpiredException when OTP is expired")
    void testVerifyAndSignup_ExpiredOtp_ThrowsOtpExpiredException() {
        when(farmerRepository.existsByPhoneNumber(validVerifyRequest.getPhoneNumber())).thenReturn(false);
        when(otpService.verifyOtp(validVerifyRequest.getPhoneNumber(), validVerifyRequest.getOtp(), OtpPurpose.REGISTRATION))
                .thenThrow(new ExpiredOtpException("OTP has expired"));

        OtpExpiredException exception = assertThrows(
                OtpExpiredException.class,
                () -> farmerService.verifyAndSignup(validVerifyRequest)
        );

        assertTrue(exception.getMessage().contains("expired"));
        verify(farmerRepository, never()).save(any());
        verify(userRepository, never()).save(any());
        verify(applicationEventPublisher, never()).publishEvent(any());
    }

    @Test
    @DisplayName("verifyAndSignup() throws OtpMismatchException when OTP is invalid or wrong")
    void testVerifyAndSignup_WrongOtp_ThrowsOtpMismatchException() {
        when(farmerRepository.existsByPhoneNumber(validVerifyRequest.getPhoneNumber())).thenReturn(false);
        when(otpService.verifyOtp(validVerifyRequest.getPhoneNumber(), validVerifyRequest.getOtp(), OtpPurpose.REGISTRATION))
                .thenThrow(new InvalidOtpException("Invalid OTP code"));

        OtpMismatchException exception = assertThrows(
                OtpMismatchException.class,
                () -> farmerService.verifyAndSignup(validVerifyRequest)
        );

        assertTrue(exception.getMessage().contains("Invalid OTP code"));
        verify(farmerRepository, never()).save(any());
        verify(userRepository, never()).save(any());
        verify(applicationEventPublisher, never()).publishEvent(any());
    }

    @Test
    @DisplayName("verifyAndSignup() throws DuplicatePhoneException when phone number already exists")
    void testVerifyAndSignup_DuplicatePhone_ThrowsDuplicatePhoneException() {
        when(farmerRepository.existsByPhoneNumber(validVerifyRequest.getPhoneNumber())).thenReturn(true);

        DuplicatePhoneException exception = assertThrows(
                DuplicatePhoneException.class,
                () -> farmerService.verifyAndSignup(validVerifyRequest)
        );

        assertTrue(exception.getMessage().contains("+94771234567"));
        verify(otpService, never()).verifyOtp(anyString(), anyString(), any());
        verify(farmerRepository, never()).save(any());
        verify(applicationEventPublisher, never()).publishEvent(any());
    }
}
