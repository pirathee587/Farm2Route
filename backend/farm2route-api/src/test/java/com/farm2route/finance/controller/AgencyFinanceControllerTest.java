package com.farm2route.finance.controller;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.common.filter.RequestCorrelationFilter;
import com.farm2route.finance.AgencyFinanceService;
import com.farm2route.finance.dto.AgencyEarningsSummaryDto;
import com.farm2route.security.JwtAuthenticationFilter;
import com.farm2route.security.UserPrincipal;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
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
import java.util.UUID;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = AgencyFinanceController.class, excludeFilters = @ComponentScan.Filter(
        type = FilterType.ASSIGNABLE_TYPE, classes = {JwtAuthenticationFilter.class, RequestCorrelationFilter.class}
))
@AutoConfigureMockMvc(addFilters = false)
class AgencyFinanceControllerTest {
    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;
    @MockBean AgencyFinanceService financeService;

    private UUID agencyUserId;

    @BeforeEach
    void setUp() {
        agencyUserId = UUID.randomUUID();
        User user = User.builder().id(agencyUserId).role(Role.AGENCY).status(UserStatus.ACTIVE)
                .phoneNumber("+94770000000").passwordHash("hash").build();
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(new UserPrincipal(user), null, new UserPrincipal(user).getAuthorities()));
    }

    @Test
    void summaryReturnsAgencyScopedDto() throws Exception {
        when(financeService.getSummary(eq(agencyUserId))).thenReturn(AgencyEarningsSummaryDto.builder()
                .grossEarnings(new BigDecimal("100.00")).commission(new BigDecimal("10.00"))
                .netEarnings(new BigDecimal("90.00")).withdrawn(BigDecimal.ZERO)
                .availableBalance(new BigDecimal("90.00")).build());

        mockMvc.perform(get("/api/v1/agency/finance/summary"))
                .andExpect(status().isOk());
    }

    @Test
    void withdrawalRequestValidatesBody() throws Exception {
        mockMvc.perform(post("/api/v1/agency/finance/withdrawals")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(java.util.Map.of("amount", "0.00"))))
                .andExpect(status().isBadRequest());
    }

}
