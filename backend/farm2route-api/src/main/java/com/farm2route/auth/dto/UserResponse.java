package com.farm2route.auth.dto;

import com.farm2route.common.enums.Role;
import com.farm2route.common.enums.UserStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserResponse {

    private UUID id;
    private String email;
    private String phoneNumber;
    private String fullName;
    private Role role;
    private UserStatus status;
    private String profileImageUrl;
    private boolean isPhoneVerified;
    private boolean isEmailVerified;
    private Instant createdAt;
}
