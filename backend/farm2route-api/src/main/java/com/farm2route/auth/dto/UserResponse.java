package com.farm2route.auth.dto;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
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
    private String phoneNumber;
    private String email;
    private Role role;
    private UserStatus status;
    private boolean phoneVerified;
    private Instant createdAt;

    public static UserResponse fromUser(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .phoneNumber(user.getPhoneNumber())
                .email(user.getEmail())
                .role(user.getRole())
                .status(user.getStatus())
                .phoneVerified(user.isPhoneVerified())
                .createdAt(user.getCreatedAt())
                .build();
    }
}
