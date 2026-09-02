package com.farm2route.security;

import com.farm2route.admin.service.AdminService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SecurityConfigTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private AdminService adminService;

    @Test
    @DisplayName("RBAC: Unauthenticated user should be rejected with 401 on /api/v1/admin/**")
    void testUnauthenticatedAdminAccess() throws Exception {
        mockMvc.perform(get("/api/v1/admin/stats"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = "FARMER")
    @DisplayName("RBAC: FARMER should be rejected with 403 Forbidden on /api/v1/admin/**")
    void testFarmerCannotAccessAdmin() throws Exception {
        mockMvc.perform(get("/api/v1/admin/stats"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "AGENCY")
    @DisplayName("RBAC: AGENCY should be rejected with 403 Forbidden on /api/v1/admin/**")
    void testAgencyCannotAccessAdmin() throws Exception {
        mockMvc.perform(get("/api/v1/admin/stats"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "DRIVER")
    @DisplayName("RBAC: DRIVER should be rejected with 403 Forbidden on /api/v1/admin/**")
    void testDriverCannotAccessAdmin() throws Exception {
        mockMvc.perform(get("/api/v1/admin/stats"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("RBAC: ADMIN should be allowed with 200 OK on /api/v1/admin/**")
    void testAdminCanAccessAdmin() throws Exception {
        mockMvc.perform(get("/api/v1/admin/stats"))
                .andExpect(status().isOk());
    }
}
