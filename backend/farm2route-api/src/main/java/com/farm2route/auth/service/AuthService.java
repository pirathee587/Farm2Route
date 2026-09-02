package com.farm2route.auth.service;

import com.farm2route.auth.dto.*;
import com.farm2route.auth.entity.RefreshToken;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.common.enums.UserStatus;
import com.farm2route.common.exception.ConflictException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.common.exception.UnauthorizedException;
import com.farm2route.security.JwtService;
import com.farm2route.security.TokenBlacklistService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Date;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final RefreshTokenService refreshTokenService;
    private final OtpService otpService;
    private final TokenBlacklistService tokenBlacklistService;
    private final AuthenticationManager authenticationManager;

    @Transactional
    public AuthResponse register(RegisterRequest request, String clientIp) {
        if (userRepository.existsByPhoneNumber(request.getPhoneNumber())) {
            throw new ConflictException("Phone number is already registered: " + request.getPhoneNumber());
        }

        if (request.getEmail() != null && !request.getEmail().isBlank()
                && userRepository.existsByEmail(request.getEmail())) {
            throw new ConflictException("Email is already registered: " + request.getEmail());
        }

        User user = User.builder()
                .fullName(request.getFullName().trim())
                .phoneNumber(request.getPhoneNumber().trim())
                .email(request.getEmail() != null && !request.getEmail().isBlank() ? request.getEmail().trim() : null)
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(request.getRole())
                .status(UserStatus.PENDING_VERIFICATION)
                .isPhoneVerified(false)
                .isEmailVerified(false)
                .build();

        user = userRepository.save(user);

        // Generate OTP for registration verification
        otpService.generateAndSendOtp(user.getPhoneNumber(), "REGISTRATION");

        return AuthResponse.builder()
                .user(mapToUserResponse(user))
                .requiresOtp(true)
                .build();
    }

    @Transactional
    public AuthResponse verifyOtp(VerifyOtpRequest request, String clientIp) {
        otpService.verifyOtp(request.getPhoneNumber(), request.getOtpCode(), request.getPurpose());

        User user = userRepository.findByPhoneNumber(request.getPhoneNumber())
                .orElseThrow(() -> new ResourceNotFoundException("User not found with phone: " + request.getPhoneNumber()));

        if ("REGISTRATION".equalsIgnoreCase(request.getPurpose())) {
            user.setPhoneVerified(true);
            user.setStatus(UserStatus.ACTIVE);
            user = userRepository.save(user);
        }

        String accessToken = jwtService.generateToken(user);
        String refreshToken = refreshTokenService.createRefreshToken(user, clientIp);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresInMs(jwtService.getExpirationMs())
                .user(mapToUserResponse(user))
                .requiresOtp(false)
                .build();
    }

    @Transactional
    public AuthResponse login(LoginRequest request, String clientIp) {
        User user = userRepository.findByIdentifier(request.getIdentifier().trim())
                .orElseThrow(() -> new BadCredentialsException("Invalid credentials"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new BadCredentialsException("Invalid credentials");
        }

        if (user.getStatus() == UserStatus.SUSPENDED || user.getStatus() == UserStatus.DEACTIVATED) {
            throw new UnauthorizedException("Your account is " + user.getStatus().name().toLowerCase() + ". Please contact support.");
        }

        if (!user.isPhoneVerified()) {
            // Trigger new OTP if account is not verified yet
            otpService.generateAndSendOtp(user.getPhoneNumber(), "REGISTRATION");
            return AuthResponse.builder()
                    .user(mapToUserResponse(user))
                    .requiresOtp(true)
                    .build();
        }

        String accessToken = jwtService.generateToken(user);
        String refreshToken = refreshTokenService.createRefreshToken(user, clientIp);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresInMs(jwtService.getExpirationMs())
                .user(mapToUserResponse(user))
                .requiresOtp(false)
                .build();
    }

    @Transactional
    public AuthResponse refreshToken(RefreshTokenRequest request, String clientIp) {
        RefreshToken oldToken = refreshTokenService.verifyAndRotate(request.getRefreshToken(), clientIp);
        User user = oldToken.getUser();

        String newAccessToken = jwtService.generateToken(user);
        String newRefreshToken = refreshTokenService.createRefreshToken(user, clientIp);

        return AuthResponse.builder()
                .accessToken(newAccessToken)
                .refreshToken(newRefreshToken)
                .tokenType("Bearer")
                .expiresInMs(jwtService.getExpirationMs())
                .user(mapToUserResponse(user))
                .build();
    }

    @Transactional
    public void logout(String authHeader, RefreshTokenRequest refreshRequest) {
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String jwt = authHeader.substring(7);
            try {
                Date expiration = jwtService.extractExpiration(jwt);
                tokenBlacklistService.blacklistToken(jwt, expiration.toInstant());
            } catch (Exception ex) {
                log.warn("Failed to extract expiration during logout blacklist: {}", ex.getMessage());
            }
        }

        if (refreshRequest != null && refreshRequest.getRefreshToken() != null) {
            refreshTokenService.revokeToken(refreshRequest.getRefreshToken());
        }
    }

    @Transactional(readOnly = true)
    public UserResponse getMe(String identifier) {
        User user = userRepository.findByIdentifier(identifier)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + identifier));
        return mapToUserResponse(user);
    }

    public UserResponse mapToUserResponse(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .phoneNumber(user.getPhoneNumber())
                .fullName(user.getFullName())
                .role(user.getRole())
                .status(user.getStatus())
                .profileImageUrl(user.getProfileImageUrl())
                .isPhoneVerified(user.isPhoneVerified())
                .isEmailVerified(user.isEmailVerified())
                .createdAt(user.getCreatedAt())
                .build();
    }
}
