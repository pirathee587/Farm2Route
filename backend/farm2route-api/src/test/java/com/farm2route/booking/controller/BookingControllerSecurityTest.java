package com.farm2route.booking.controller;

import com.farm2route.booking.service.BookingService;
import com.farm2route.security.CustomUserDetailsService;
import com.farm2route.security.JwtService;
import com.farm2route.security.SecurityExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = BookingController.class)
class BookingControllerSecurityTest {

    @Autowired MockMvc mockMvc;
    @MockBean BookingService bookingService;
    @MockBean JwtService jwtService;
    @MockBean CustomUserDetailsService customUserDetailsService;
    @MockBean SecurityExceptionHandler securityExceptionHandler;

    @Test
    void unauthenticatedBookingLookupIsRejected() throws Exception {
        mockMvc.perform(get("/api/v1/bookings/{id}", java.util.UUID.randomUUID()))
                .andExpect(status().isUnauthorized());
    }
}
