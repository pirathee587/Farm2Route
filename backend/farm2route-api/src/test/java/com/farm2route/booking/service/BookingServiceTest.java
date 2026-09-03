package com.farm2route.booking.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.booking.dto.BookingDto;
import com.farm2route.booking.dto.CreateBookingRequest;
import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.catalog.entity.TransportPackage;
import com.farm2route.catalog.repository.PackageRepository;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.enums.PackageType;
import com.farm2route.common.exception.BusinessRuleException;
import com.farm2route.common.exception.ForbiddenException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.farmer.entity.FarmerProfile;
import com.farm2route.farmer.repository.FarmerProfileRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BookingServiceTest {

    @Mock
    private BookingRepository bookingRepository;

    @Mock
    private FarmerProfileRepository farmerProfileRepository;

    @Mock
    private AgencyProfileRepository agencyProfileRepository;

    @Mock
    private PackageRepository packageRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private org.springframework.context.ApplicationEventPublisher applicationEventPublisher;

    @InjectMocks
    private BookingService bookingService;

    private UUID farmerUserId;
    private UUID farmerProfileId;
    private UUID agencyId;
    private UUID packageId;
    private UUID bookingId;

    private User farmerUser;
    private FarmerProfile farmerProfile;
    private AgencyProfile agencyProfile;
    private TransportPackage transportPackage;
    private Booking sampleBooking;
    private CreateBookingRequest createRequest;

    @BeforeEach
    void setUp() {
        farmerUserId = UUID.randomUUID();
        farmerProfileId = UUID.randomUUID();
        agencyId = UUID.randomUUID();
        packageId = UUID.randomUUID();
        bookingId = UUID.randomUUID();

        farmerUser = User.builder()
                .id(farmerUserId)
                .email("farmer@farm2route.lk")
                .phoneNumber("+94771122334")
                .role(Role.FARMER)
                .status(UserStatus.ACTIVE)
                .build();

        farmerProfile = FarmerProfile.builder()
                .id(farmerProfileId)
                .user(farmerUser)
                .farmName("Bandara Organic Greens")
                .address("Galgamuwa")
                .district("Kurunegala")
                .province("Wayamba")
                .latitude(new BigDecimal("7.50000000"))
                .longitude(new BigDecimal("80.30000000"))
                .build();

        agencyProfile = AgencyProfile.builder()
                .id(agencyId)
                .companyName("Green Route Logistics")
                .contactPersonPhone("+94770000002")
                .officeAddress("120 Kandy Road, Kurunegala")
                .district("Kurunegala")
                .build();

        transportPackage = TransportPackage.builder()
                .id(packageId)
                .agency(agencyProfile)
                .title("Kurunegala to Colombo Agro Express")
                .packageType(PackageType.STANDARD)
                .basePrice(new BigDecimal("5000.00"))
                .pricePerKm(new BigDecimal("120.00"))
                .pricePerKg(new BigDecimal("15.00"))
                .maxWeightKg(new BigDecimal("3500.00"))
                .routeOrigin("Kurunegala")
                .routeDestination("Colombo")
                .isActive(true)
                .build();

        createRequest = CreateBookingRequest.builder()
                .agencyId(agencyId)
                .pickupAddress("Galgamuwa Farm Road")
                .pickupLatitude(new BigDecimal("7.50000000"))
                .pickupLongitude(new BigDecimal("80.30000000"))
                .deliveryAddress("Pettah Central Market, Colombo")
                .deliveryLatitude(new BigDecimal("6.94000000"))
                .deliveryLongitude(new BigDecimal("79.86000000"))
                .recipientName("Wholesale Trader")
                .recipientPhone("+94719988776")
                .cargoType("Vegetables")
                .cargoWeightKg(new BigDecimal("1200.00"))
                .fragile(false)
                .requiresRefrigeration(false)
                .specialInstructions("Keep well ventilated")
                .scheduledPickupAt(Instant.now().plus(1, ChronoUnit.DAYS))
                .totalAmount(new BigDecimal("18500.00"))
                .build();

        sampleBooking = Booking.builder()
                .id(bookingId)
                .bookingNumber("F2R-TEST-1001")
                .farmer(farmerProfile)
                .agency(agencyProfile)
                .transportPackage(transportPackage)
                .pickupAddress(createRequest.getPickupAddress())
                .pickupLatitude(createRequest.getPickupLatitude())
                .pickupLongitude(createRequest.getPickupLongitude())
                .deliveryAddress(createRequest.getDeliveryAddress())
                .deliveryLatitude(createRequest.getDeliveryLatitude())
                .deliveryLongitude(createRequest.getDeliveryLongitude())
                .recipientName(createRequest.getRecipientName())
                .recipientPhone(createRequest.getRecipientPhone())
                .cargoType(createRequest.getCargoType())
                .cargoWeightKg(createRequest.getCargoWeightKg())
                .totalAmount(createRequest.getTotalAmount())
                .status(BookingStatus.PENDING)
                .scheduledPickupAt(createRequest.getScheduledPickupAt())
                .createdAt(Instant.now())
                .build();
    }

    @Test
    @DisplayName("Create booking successfully without package")
    void testCreateBooking_Success_WithoutPackage() {
        when(farmerProfileRepository.findByUserId(farmerUserId)).thenReturn(Optional.of(farmerProfile));
        when(agencyProfileRepository.findById(agencyId)).thenReturn(Optional.of(agencyProfile));
        when(bookingRepository.save(any(Booking.class))).thenAnswer(invocation -> {
            Booking b = invocation.getArgument(0);
            b.setId(bookingId);
            return b;
        });

        BookingDto result = bookingService.createBooking(farmerUserId, createRequest);

        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(bookingId);
        assertThat(result.getFarmerId()).isEqualTo(farmerProfileId);
        assertThat(result.getAgencyId()).isEqualTo(agencyId);
        assertThat(result.getStatus()).isEqualTo(BookingStatus.PENDING);
        assertThat(result.getTotalAmount()).isEqualByComparingTo(new BigDecimal("18500.00"));
        verify(bookingRepository, times(1)).save(any(Booking.class));
    }

    @Test
    @DisplayName("Create booking successfully with linked package")
    void testCreateBooking_Success_WithPackage() {
        createRequest.setPackageId(packageId);
        createRequest.setTotalAmount(null); // allow auto-estimate

        when(farmerProfileRepository.findByUserId(farmerUserId)).thenReturn(Optional.of(farmerProfile));
        when(agencyProfileRepository.findById(agencyId)).thenReturn(Optional.of(agencyProfile));
        when(packageRepository.findById(packageId)).thenReturn(Optional.of(transportPackage));
        when(bookingRepository.save(any(Booking.class))).thenAnswer(invocation -> {
            Booking b = invocation.getArgument(0);
            b.setId(bookingId);
            return b;
        });

        BookingDto result = bookingService.createBooking(farmerUserId, createRequest);

        assertThat(result).isNotNull();
        assertThat(result.getPackageId()).isEqualTo(packageId);
        assertThat(result.getPackageName()).isEqualTo(transportPackage.getTitle());
        assertThat(result.getTotalAmount()).isNotNull();
        assertThat(result.getTotalAmount()).isGreaterThan(BigDecimal.ZERO);
        verify(packageRepository, times(1)).findById(packageId);
        verify(bookingRepository, times(1)).save(any(Booking.class));
    }

    @Test
    @DisplayName("Create booking throws ResourceNotFoundException when farmer profile is not found")
    void testCreateBooking_FarmerNotFound_ThrowsException() {
        when(farmerProfileRepository.findByUserId(farmerUserId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> bookingService.createBooking(farmerUserId, createRequest))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Farmer profile not found");

        verify(bookingRepository, never()).save(any());
    }

    @Test
    @DisplayName("Create booking throws ResourceNotFoundException when agency is not found")
    void testCreateBooking_AgencyNotFound_ThrowsException() {
        when(farmerProfileRepository.findByUserId(farmerUserId)).thenReturn(Optional.of(farmerProfile));
        when(agencyProfileRepository.findById(agencyId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> bookingService.createBooking(farmerUserId, createRequest))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Agency not found");

        verify(bookingRepository, never()).save(any());
    }

    @Test
    @DisplayName("Create booking throws BusinessRuleException when package is inactive")
    void testCreateBooking_PackageInactive_ThrowsException() {
        createRequest.setPackageId(packageId);
        transportPackage.setActive(false);

        when(farmerProfileRepository.findByUserId(farmerUserId)).thenReturn(Optional.of(farmerProfile));
        when(agencyProfileRepository.findById(agencyId)).thenReturn(Optional.of(agencyProfile));
        when(packageRepository.findById(packageId)).thenReturn(Optional.of(transportPackage));

        assertThatThrownBy(() -> bookingService.createBooking(farmerUserId, createRequest))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Selected transport package is not active");

        verify(bookingRepository, never()).save(any());
    }

    @Test
    @DisplayName("Create booking throws BusinessRuleException when package agency differs from requested agency")
    void testCreateBooking_PackageAgencyMismatch_ThrowsException() {
        createRequest.setPackageId(packageId);
        AgencyProfile otherAgency = AgencyProfile.builder().id(UUID.randomUUID()).build();
        transportPackage.setAgency(otherAgency);

        when(farmerProfileRepository.findByUserId(farmerUserId)).thenReturn(Optional.of(farmerProfile));
        when(agencyProfileRepository.findById(agencyId)).thenReturn(Optional.of(agencyProfile));
        when(packageRepository.findById(packageId)).thenReturn(Optional.of(transportPackage));

        assertThatThrownBy(() -> bookingService.createBooking(farmerUserId, createRequest))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Package does not belong to the selected agency");

        verify(bookingRepository, never()).save(any());
    }

    @Test
    @DisplayName("Create booking throws BusinessRuleException when cargo weight exceeds package max capacity")
    void testCreateBooking_OverweightCargo_ThrowsException() {
        createRequest.setPackageId(packageId);
        createRequest.setCargoWeightKg(new BigDecimal("5000.00")); // Package max is 3500.00 kg

        when(farmerProfileRepository.findByUserId(farmerUserId)).thenReturn(Optional.of(farmerProfile));
        when(agencyProfileRepository.findById(agencyId)).thenReturn(Optional.of(agencyProfile));
        when(packageRepository.findById(packageId)).thenReturn(Optional.of(transportPackage));

        assertThatThrownBy(() -> bookingService.createBooking(farmerUserId, createRequest))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("exceeds package maximum capacity");

        verify(bookingRepository, never()).save(any());
    }

    @Test
    @DisplayName("Get farmer bookings returns list of bookings")
    void testGetFarmerBookings_Success() {
        when(farmerProfileRepository.findByUserId(farmerUserId)).thenReturn(Optional.of(farmerProfile));
        when(bookingRepository.findByFarmerId(farmerProfileId)).thenReturn(List.of(sampleBooking));

        List<BookingDto> result = bookingService.getFarmerBookings(farmerUserId);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getBookingNumber()).isEqualTo("F2R-TEST-1001");
        verify(bookingRepository, times(1)).findByFarmerId(farmerProfileId);
    }

    @Test
    @DisplayName("Get booking by ID with farmer verification succeeds for booking owner")
    void testGetBookingById_Authorized_Success() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(sampleBooking));

        BookingDto result = bookingService.getBookingById(bookingId, farmerUserId);

        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(bookingId);
    }

    @Test
    @DisplayName("Get booking by ID throws ForbiddenException when accessed by another user")
    void testGetBookingById_Unauthorized_ThrowsForbiddenException() {
        UUID otherUserId = UUID.randomUUID();
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(sampleBooking));

        assertThatThrownBy(() -> bookingService.getBookingById(bookingId, otherUserId))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("You are not authorized");
    }

    @Test
    @DisplayName("Cancel booking successfully changes status to CANCELLED")
    void testCancelBooking_Success() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(sampleBooking));
        when(userRepository.findById(farmerUserId)).thenReturn(Optional.of(farmerUser));
        when(bookingRepository.save(any(Booking.class))).thenAnswer(invocation -> invocation.getArgument(0));

        BookingDto result = bookingService.cancelBooking(bookingId, farmerUserId, "Changed schedule");

        assertThat(result.getStatus()).isEqualTo(BookingStatus.CANCELLED);
        assertThat(result.getCancellationReason()).isEqualTo("Changed schedule");
        verify(bookingRepository, times(1)).save(sampleBooking);
    }

    @Test
    @DisplayName("Cancel booking throws BusinessRuleException if already cancelled")
    void testCancelBooking_AlreadyCancelled_ThrowsException() {
        sampleBooking.setStatus(BookingStatus.CANCELLED);
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(sampleBooking));

        assertThatThrownBy(() -> bookingService.cancelBooking(bookingId, farmerUserId, "Trying again"))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("already cancelled");

        verify(bookingRepository, never()).save(any());
    }

    @Test
    @DisplayName("Cancel booking throws BusinessRuleException if already delivered")
    void testCancelBooking_AlreadyDelivered_ThrowsException() {
        sampleBooking.setStatus(BookingStatus.DELIVERED);
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(sampleBooking));

        assertThatThrownBy(() -> bookingService.cancelBooking(bookingId, farmerUserId, "Too late"))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Cannot cancel a completed delivery");

        verify(bookingRepository, never()).save(any());
    }

    @Test
    @DisplayName("Cancel booking throws ForbiddenException when executed by non-owner")
    void testCancelBooking_Unauthorized_ThrowsException() {
        UUID otherUserId = UUID.randomUUID();
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(sampleBooking));

        assertThatThrownBy(() -> bookingService.cancelBooking(bookingId, otherUserId, "Malicious attempt"))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("You are not authorized");

        verify(bookingRepository, never()).save(any());
    }

    @Test
    @DisplayName("Create booking publishes BookingCreatedEvent after save")
    void testCreateBooking_PublishesBookingCreatedEvent() {
        when(farmerProfileRepository.findByUserId(farmerUserId)).thenReturn(Optional.of(farmerProfile));
        when(agencyProfileRepository.findById(agencyId)).thenReturn(Optional.of(agencyProfile));
        when(bookingRepository.save(any(Booking.class))).thenAnswer(invocation -> {
            Booking b = invocation.getArgument(0);
            b.setId(bookingId);
            return b;
        });

        bookingService.createBooking(farmerUserId, createRequest);

        verify(applicationEventPublisher, times(1)).publishEvent(any(com.farm2route.common.event.BookingCreatedEvent.class));
    }

    @Test
    @DisplayName("Create booking does not publish event if repository save throws exception")
    void testCreateBooking_WhenSaveFails_DoesNotPublishEvent() {
        when(farmerProfileRepository.findByUserId(farmerUserId)).thenReturn(Optional.of(farmerProfile));
        when(agencyProfileRepository.findById(agencyId)).thenReturn(Optional.of(agencyProfile));
        when(bookingRepository.save(any(Booking.class))).thenThrow(new RuntimeException("Database error"));

        assertThatThrownBy(() -> bookingService.createBooking(farmerUserId, createRequest))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("Database error");

        verify(applicationEventPublisher, never()).publishEvent(any());
    }

    @Test
    @DisplayName("Cancel booking publishes BookingCancelledEvent upon success")
    void testCancelBooking_PublishesBookingCancelledEvent() {
        sampleBooking.setStatus(BookingStatus.ACCEPTED);
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(sampleBooking));
        when(userRepository.findById(farmerUserId)).thenReturn(Optional.of(farmerUser));
        when(bookingRepository.save(any(Booking.class))).thenReturn(sampleBooking);

        bookingService.cancelBooking(bookingId, farmerUserId, "Plan changed");

        verify(applicationEventPublisher, times(1)).publishEvent(any(com.farm2route.common.event.BookingCancelledEvent.class));
    }
}
