package com.farm2route.finance.controller;

import com.farm2route.finance.AgencyFinanceService;
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

@WebMvcTest(AgencyFinanceController.class)
class AgencyFinanceAuthenticationTest {
    @Autowired MockMvc mockMvc;
    @MockBean AgencyFinanceService financeService;
    @MockBean JwtService jwtService;
    @MockBean CustomUserDetailsService customUserDetailsService;
    @MockBean SecurityExceptionHandler securityExceptionHandler;

    @Test
    void unauthenticatedFinanceAccessIsRejected() throws Exception {
        mockMvc.perform(get("/api/v1/agency/finance/summary"))
                .andExpect(status().isUnauthorized());
    }
}
