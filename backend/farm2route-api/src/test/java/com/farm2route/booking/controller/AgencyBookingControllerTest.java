package com.farm2route.booking.controller;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.booking.dto.BookingDto;
import com.farm2route.booking.dto.RejectBookingRequest;
import com.farm2route.booking.service.BookingService;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.filter.RequestCorrelationFilter;
import com.farm2route.security.JwtAuthenticationFilter;
import com.farm2route.security.UserPrincipal;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(
        controllers = AgencyBookingController.class,
        excludeFilters = @ComponentScan.Filter(
                type = FilterType.ASSIGNABLE_TYPE,
                classes = {JwtAuthenticationFilter.class, RequestCorrelationFilter.class}
        )
)
@AutoConfigureMockMvc(addFilters = false)
class AgencyBookingControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private BookingService bookingService;

    private UUID agencyUserId;
    private UUID bookingId;
    private UserPrincipal agencyPrincipal;
    private BookingDto acceptedBookingDto;
    private BookingDto rejectedBookingDto;

    @BeforeEach
    void setUp() {
        agencyUserId = UUID.randomUUID();
        bookingId = UUID.randomUUID();

        User agencyUser = User.builder()
                .id(agencyUserId)
                .email("agency@farm2route.lk")
                .phoneNumber("+94771234567")
                .role(Role.AGENCY)
                .status(UserStatus.ACTIVE)
                .build();

        agencyPrincipal = new UserPrincipal(agencyUser);

        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())
        );

        acceptedBookingDto = BookingDto.builder()
                .id(bookingId)
                .bookingNumber("F2R-TEST-1001")
                .farmerId(UUID.randomUUID())
                .agencyId(UUID.randomUUID())
                .status(BookingStatus.ACCEPTED)
                .totalAmount(new BigDecimal("18500.00"))
                .build();

        rejectedBookingDto = BookingDto.builder()
                .id(bookingId)
                .bookingNumber("F2R-TEST-1001")
                .farmerId(UUID.randomUUID())
                .agencyId(UUID.randomUUID())
                .status(BookingStatus.REJECTED)
                .cancellationReason("Fleet fully booked")
                .totalAmount(new BigDecimal("18500.00"))
                .build();
    }

    @Test
    @DisplayName("GET /api/v1/agency/bookings returns list of agency bookings")
    void testGetAgencyBookings_Success() throws Exception {
        when(bookingService.getAgencyBookings(agencyUserId)).thenReturn(List.of(acceptedBookingDto));

        mockMvc.perform(get("/api/v1/agency/bookings")
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].id").value(bookingId.toString()));
    }

    @Test
    @DisplayName("POST /api/v1/agency/bookings/{id}/accept accepts booking successfully")
    void testAcceptBooking_Post_Success() throws Exception {
        when(bookingService.acceptBooking(agencyUserId, bookingId)).thenReturn(acceptedBookingDto);

        mockMvc.perform(post("/api/v1/agency/bookings/" + bookingId + "/accept")
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("ACCEPTED"));
    }

    @Test
    @DisplayName("PUT /api/v1/agency/bookings/{id}/accept accepts booking via PUT alias")
    void testAcceptBooking_Put_Success() throws Exception {
        when(bookingService.acceptBooking(agencyUserId, bookingId)).thenReturn(acceptedBookingDto);

        mockMvc.perform(put("/api/v1/agency/bookings/" + bookingId + "/accept")
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("ACCEPTED"));
    }

    @Test
    @DisplayName("POST /api/v1/agency/bookings/{id}/reject rejects booking successfully")
    void testRejectBooking_Post_Success() throws Exception {
        RejectBookingRequest request = RejectBookingRequest.builder()
                .reason("Fleet fully booked")
                .build();

        when(bookingService.rejectBooking(eq(agencyUserId), eq(bookingId), eq("Fleet fully booked")))
                .thenReturn(rejectedBookingDto);

        mockMvc.perform(post("/api/v1/agency/bookings/" + bookingId + "/reject")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("REJECTED"))
                .andExpect(jsonPath("$.data.cancellationReason").value("Fleet fully booked"));
    }

    @Test
    @DisplayName("PUT /api/v1/agency/bookings/{id}/reject rejects booking via PUT alias")
    void testRejectBooking_Put_Success() throws Exception {
        RejectBookingRequest request = RejectBookingRequest.builder()
                .reason("Fleet fully booked")
                .build();

        when(bookingService.rejectBooking(eq(agencyUserId), eq(bookingId), eq("Fleet fully booked")))
                .thenReturn(rejectedBookingDto);

        mockMvc.perform(put("/api/v1/agency/bookings/" + bookingId + "/reject")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("REJECTED"));
    }
}
