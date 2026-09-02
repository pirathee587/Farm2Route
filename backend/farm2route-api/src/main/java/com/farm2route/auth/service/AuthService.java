package com.farm2route.auth.service;

import com.farm2route.auth.dto.*;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.OtpPurpose;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.common.exception.AccountLockedException;
import com.farm2route.common.exception.AuthenticationException;
import com.farm2route.common.exception.ConflictException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.security.JwtService;
import com.farm2route.security.TokenBlacklistService;
import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordService passwordService;
    private final JwtService jwtService;
    private final RefreshTokenService refreshTokenService;
    private final OtpService otpService;
    private final TokenBlacklistService tokenBlacklistService;
    private final LoginRateLimitService loginRateLimitService;
    private final RegistrationRateLimitService registrationRateLimitService;
    private final AuthenticationAuditService auditService;

    @Value("${security.login.max-failed-attempts:5}")
    private int maxFailedLoginAttempts;

    @Value("${security.login.lock-duration-minutes:15}")
    private int lockDurationMinutes;

    @Transactional
    public AuthResponse register(RegisterRequest request, String clientIp) {
        // Distributed rate limit
        registrationRateLimitService.checkAndIncrement(clientIp, request.getPhoneNumber());

        // Reject public ADMIN registration
        if (request.getRole() == Role.ADMIN) {
            throw new ConflictException("Admin accounts cannot be registered publicly. Must be provisioned by system.");
        }

        // Duplicate checks
        if (userRepository.existsByPhoneNumber(request.getPhoneNumber())) {
            throw new ConflictException("User with this phone number already exists.");
        }

        if (request.getEmail() != null && !request.getEmail().isBlank() && userRepository.existsByEmail(request.getEmail())) {
            throw new ConflictException("User with this email address already exists.");
        }

        // Hash password with BCrypt (strength 12)
        String passwordHash = passwordService.hashPassword(request.getPassword());

        User user = User.builder()
                .phoneNumber(request.getPhoneNumber())
                .email(request.getEmail() != null && !request.getEmail().isBlank() ? request.getEmail().trim().toLowerCase() : null)
                .passwordHash(passwordHash)
                .role(request.getRole())
                .status(UserStatus.PENDING_VERIFICATION)
                .phoneVerified(false)
                .failedLoginCount(0)
                .build();

        User savedUser = userRepository.save(user);

        // Generate & dispatch OTP
        otpService.generateAndSendOtp(savedUser.getPhoneNumber(), OtpPurpose.REGISTRATION, savedUser.getId());

        auditService.logUserRegistered(savedUser.getId(), savedUser.getPhoneNumber(), savedUser.getRole().name(), clientIp);
        auditService.logOtpRequested(savedUser.getPhoneNumber(), OtpPurpose.REGISTRATION.name(), clientIp);

        return AuthResponse.builder()
                .requiresOtp(true)
                .message("User registered successfully. Verification OTP dispatched.")
                .user(UserResponse.fromUser(savedUser))
                .build();
    }

    @Transactional
    public AuthResponse verifyOtp(VerifyOtpRequest request, String clientIp, String userAgent) {
        // Validate OTP using timing-safe compare
        otpService.verifyOtp(request.getPhoneNumber(), request.getOtp(), request.getPurpose());

        User user = userRepository.findByPhoneNumber(request.getPhoneNumber())
                .orElseThrow(() -> new ResourceNotFoundException("User not found for phone: " + request.getPhoneNumber()));

        user.setPhoneVerified(true);
        if (user.getStatus() == UserStatus.PENDING_VERIFICATION) {
            user.setStatus(UserStatus.ACTIVE);
        }
        user.setFailedLoginCount(0);
        user.setLockedUntil(null);
        user.setLastLoginAt(Instant.now());
        User savedUser = userRepository.save(user);

        String accessToken = jwtService.generateToken(savedUser);
        RefreshTokenService.CreatedToken refreshToken = refreshTokenService.createRefreshToken(savedUser, userAgent, clientIp);

        auditService.logOtpVerified(savedUser.getId(), savedUser.getPhoneNumber(), request.getPurpose().name(), clientIp);
        auditService.logLoginSuccess(savedUser.getId(), savedUser.getRole().name(), clientIp);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken.getRawToken())
                .tokenType("Bearer")
                .expiresIn(jwtService.getAccessTokenExpirationMs() / 1000)
                .user(UserResponse.fromUser(savedUser))
                .requiresOtp(false)
                .message("OTP verified successfully. Authentication complete.")
                .build();
    }

    @Transactional
    public AuthResponse login(LoginRequest request, String clientIp, String userAgent) {
        // Rate limiting
        loginRateLimitService.checkAndIncrement(clientIp, request.getPhoneNumber());

        User user = userRepository.findByIdentifier(request.getPhoneNumber())
                .orElseThrow(() -> {
                    auditService.logLoginFailed(request.getPhoneNumber(), "USER_NOT_FOUND", clientIp);
                    return new AuthenticationException("Invalid phone number/email or password.");
                });

        Instant now = Instant.now();

        // Check account lock
        if (user.getStatus() == UserStatus.LOCKED) {
            if (user.getLockedUntil() != null && now.isBefore(user.getLockedUntil())) {
                auditService.logLoginFailed(request.getPhoneNumber(), "ACCOUNT_LOCKED", clientIp);
                throw new AccountLockedException("Account is temporarily locked due to consecutive failed login attempts. Please try again later.");
            } else {
                // Lock has expired -> auto unlock
                user.setStatus(user.isPhoneVerified() ? UserStatus.ACTIVE : UserStatus.PENDING_VERIFICATION);
                user.setFailedLoginCount(0);
                user.setLockedUntil(null);
            }
        }

        if (user.getStatus() == UserStatus.SUSPENDED || user.getStatus() == UserStatus.DISABLED) {
            auditService.logLoginFailed(request.getPhoneNumber(), "ACCOUNT_" + user.getStatus().name(), clientIp);
            throw new AuthenticationException("Your account is " + user.getStatus().name().toLowerCase() + ". Please contact support.");
        }

        // Validate password
        if (!passwordService.matches(request.getPassword(), user.getPasswordHash())) {
            int failed = user.getFailedLoginCount() + 1;
            user.setFailedLoginCount(failed);

            if (failed >= maxFailedLoginAttempts) {
                user.setStatus(UserStatus.LOCKED);
                user.setLockedUntil(now.plus(Duration.ofMinutes(lockDurationMinutes)));
                userRepository.save(user);
                auditService.logAccountLocked(user.getId(), request.getPhoneNumber(), lockDurationMinutes, clientIp);
                throw new AccountLockedException("Account locked for " + lockDurationMinutes + " minutes due to multiple failed login attempts.");
            }

            userRepository.save(user);
            auditService.logLoginFailed(request.getPhoneNumber(), "BAD_CREDENTIALS", clientIp);
            throw new AuthenticationException("Invalid phone number/email or password.");
        }

        // Credentials valid -> reset counters
        user.setFailedLoginCount(0);
        user.setLockedUntil(null);
        user.setLastLoginAt(now);
        User savedUser = userRepository.save(user);
        loginRateLimitService.reset(clientIp, request.getPhoneNumber());

        // Check if phone verification is still pending
        if (!savedUser.isPhoneVerified() || savedUser.getStatus() == UserStatus.PENDING_VERIFICATION) {
            otpService.generateAndSendOtp(savedUser.getPhoneNumber(), OtpPurpose.LOGIN, savedUser.getId());
            auditService.logOtpRequested(savedUser.getPhoneNumber(), OtpPurpose.LOGIN.name(), clientIp);
            return AuthResponse.builder()
                    .requiresOtp(true)
                    .message("Account verification required. OTP has been sent.")
                    .user(UserResponse.fromUser(savedUser))
                    .build();
        }

        String accessToken = jwtService.generateToken(savedUser);
        RefreshTokenService.CreatedToken refreshToken = refreshTokenService.createRefreshToken(savedUser, userAgent, clientIp);

        auditService.logLoginSuccess(savedUser.getId(), savedUser.getRole().name(), clientIp);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken.getRawToken())
                .tokenType("Bearer")
                .expiresIn(jwtService.getAccessTokenExpirationMs() / 1000)
                .user(UserResponse.fromUser(savedUser))
                .requiresOtp(false)
                .message("Login successful.")
                .build();
    }

    @Transactional
    public AuthResponse refresh(RefreshTokenRequest request, String clientIp, String userAgent) {
        RefreshTokenService.CreatedToken rotated = refreshTokenService.verifyAndRotate(
                request.getRefreshToken(), userAgent, clientIp
        );

        User user = rotated.getEntity().getUser();
        String newAccessToken = jwtService.generateToken(user);

        return AuthResponse.builder()
                .accessToken(newAccessToken)
                .refreshToken(rotated.getRawToken())
                .tokenType("Bearer")
                .expiresIn(jwtService.getAccessTokenExpirationMs() / 1000)
                .user(UserResponse.fromUser(user))
                .requiresOtp(false)
                .message("Token refreshed successfully.")
                .build();
    }

    @Transactional
    public void logout(String authHeader, LogoutRequest request, String clientIp) {
        UUID userId = null;

        // Blacklist Access Token in Redis with TTL = remaining lifetime
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            try {
                Claims claims = jwtService.extractAllClaims(token);
                String jti = claims.getId();
                Date expiration = claims.getExpiration();
                if (jti != null && expiration != null) {
                    long remainingSeconds = Math.max(0, (expiration.getTime() - System.currentTimeMillis()) / 1000);
                    tokenBlacklistService.blacklistToken(jti, remainingSeconds);
                }
                if (claims.getSubject() != null) {
                    userId = UUID.fromString(claims.getSubject());
                }
            } catch (Exception ex) {
                log.debug("Logout JWT blacklist skipped: {}", ex.getMessage());
            }
        }

        // Revoke Refresh Token in database
        if (request != null && request.getRefreshToken() != null && !request.getRefreshToken().isBlank()) {
            refreshTokenService.revokeToken(request.getRefreshToken());
        }

        auditService.logLogout(userId, clientIp);
    }

    @Transactional(readOnly = true)
    public UserResponse getCurrentUser(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));
        return UserResponse.fromUser(user);
    }
}
