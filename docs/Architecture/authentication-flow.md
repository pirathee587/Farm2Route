# Farm2Route — Authentication & Authorization Foundation

## 1. Authentication Lifecycle Sequence

```mermaid
sequenceDiagram
    autonumber
    actor User as Mobile App (Farmer / Agency / Driver)
    participant API as Farm2Route API (/api/v1/auth)
    participant SEC as Spring Security & BCrypt
    participant OTP as OtpService & Provider
    participant DB as PostgreSQL (users, refresh_tokens)
    participant SS as Flutter SecureStorage

    %% Registration Flow
    Note over User, DB: 1. Registration Flow
    User->>API: POST /register (fullName, phone, password, role)
    API->>SEC: Hash password with BCrypt (factor 12)
    API->>DB: Save user (status: PENDING_VERIFICATION)
    API->>OTP: Generate 6-digit OTP & dispatch SMS
    API-->>User: 201 Created (requiresOtp: true)

    %% OTP Verification
    Note over User, DB: 2. OTP Verification & Activation
    User->>API: POST /verify-otp (phone, otpCode, purpose: REGISTRATION)
    API->>OTP: Validate OTP expiry & attempts
    API->>DB: Update user (status: ACTIVE, isPhoneVerified: true)
    API->>DB: Persist hashed Refresh Token
    API-->>User: 200 OK (accessToken, refreshToken, userDetails)
    User->>SS: Save tokens securely

    %% Authenticated Requests
    Note over User, DB: 3. Authenticated REST Requests
    User->>API: GET /farmer/profile (Authorization: Bearer <accessToken>)
    API->>SEC: Validate JWT signature & blacklist status
    API-->>User: 200 OK (Farmer Profile Data)

    %% Token Rotation on Expiration
    Note over User, DB: 4. Transparent Refresh Token Rotation (401 Interception)
    User->>API: GET /bookings (Access token expired -> 401 Unauthorized)
    User->>API: POST /refresh (refreshToken: <oldRefreshToken>)
    API->>DB: Validate & revoke old token (detect replay attacks)
    API->>DB: Persist new rotated Refresh Token
    API-->>User: 200 OK (newAccessToken, newRefreshToken)
    User->>SS: Update SecureStorage
    User->>API: Retry GET /bookings (Authorization: Bearer <newAccessToken>)
    API-->>User: 200 OK (Bookings List)
```

---

## 2. Security Safeguards Implemented

1. **Password Hashing**: BCrypt with work factor 12.
2. **Access Token Lifespan**: Short-lived (15 minutes).
3. **Refresh Token Storage**: Server-side persistence with SHA-256 token hashing.
4. **Single-Use Refresh Token Rotation**: When a refresh token is exchanged, it is immediately revoked, preventing token theft and replay attacks.
5. **Immediate Token Revocation**: Logout blacklists the JWT in `TokenBlacklistService` and marks the database refresh token record as revoked.
6. **Rate Limiting on OTP**: 60-second cooldown between consecutive OTP requests and a maximum limit of 5 failed attempts per OTP lifecycle.
