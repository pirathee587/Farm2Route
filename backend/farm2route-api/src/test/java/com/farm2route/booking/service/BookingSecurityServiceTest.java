package com.farm2route.booking.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.exception.ForbiddenException;
import com.farm2route.farmer.entity.FarmerProfile;
import com.farm2route.farmer.repository.FarmerProfileRepository;
import com.farm2route.catalog.repository.PackageRepository;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.security.UserPrincipal;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BookingSecurityServiceTest {

    @Mock BookingRepository bookingRepository;
    @Mock FarmerProfileRepository farmerProfileRepository;
    @Mock AgencyProfileRepository agencyProfileRepository;
    @Mock PackageRepository packageRepository;
    @Mock UserRepository userRepository;
    @Mock ApplicationEventPublisher applicationEventPublisher;
    @InjectMocks BookingService bookingService;

    private UUID bookingId;
    private UUID farmerUserId;
    private UUID otherFarmerUserId;
    private UUID agencyUserId;
    private UUID otherAgencyUserId;
    private AgencyProfile agency;
    private Booking booking;

    @BeforeEach
    void setUp() {
        bookingId = UUID.randomUUID();
        farmerUserId = UUID.randomUUID();
        otherFarmerUserId = UUID.randomUUID();
        agencyUserId = UUID.randomUUID();
        otherAgencyUserId = UUID.randomUUID();
        User farmerUser = user(farmerUserId, Role.FARMER);
        FarmerProfile farmer = FarmerProfile.builder().id(UUID.randomUUID()).user(farmerUser).build();
        agency = AgencyProfile.builder().id(UUID.randomUUID()).user(user(agencyUserId, Role.AGENCY)).build();
        booking = Booking.builder().id(bookingId).farmer(farmer).agency(agency).build();
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
    }

    @Test
    void farmerCanViewOwnBookingButNotAnotherFarmersBooking() {
        assertThat(bookingService.getBookingById(bookingId, principal(farmerUserId, Role.FARMER)).getId())
                .isEqualTo(bookingId);

        assertThatThrownBy(() -> bookingService.getBookingById(bookingId, principal(otherFarmerUserId, Role.FARMER)))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void agencyCanViewOwnBookingButNotAnotherAgencysBooking() {
        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.of(agency));
        assertThat(bookingService.getBookingById(bookingId, principal(agencyUserId, Role.AGENCY)).getId())
                .isEqualTo(bookingId);

        when(agencyProfileRepository.findByUserId(otherAgencyUserId))
                .thenReturn(Optional.of(AgencyProfile.builder().id(UUID.randomUUID()).build()));
        assertThatThrownBy(() -> bookingService.getBookingById(bookingId, principal(otherAgencyUserId, Role.AGENCY)))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void adminCanViewAnyBooking() {
        assertThat(bookingService.getBookingById(bookingId, principal(UUID.randomUUID(), Role.ADMIN)).getId())
                .isEqualTo(bookingId);
    }

    private UserPrincipal principal(UUID id, Role role) {
        return new UserPrincipal(user(id, role));
    }

    private User user(UUID id, Role role) {
        return User.builder().id(id).role(role).status(UserStatus.ACTIVE)
                .phoneNumber("+9477" + id.toString().replace("-", "").substring(0, 8))
                .passwordHash("hash").build();
    }
}
