# Farm2Route Authentication REST API Contract

Base URL: `/api/v1/auth`

---

## 1. Register User

- **Endpoint**: `POST /api/v1/auth/register`
- **Access**: Public

### Request Body
```json
{
  "fullName": "Kamal Perera",
  "phoneNumber": "+94771234567",
  "email": "kamal@farm2route.com",
  "password": "Password123!",
  "role": "FARMER"
}
```

### Response (201 Created)
```json
{
  "success": true,
  "message": "User registered successfully. Verification OTP dispatched.",
  "data": {
    "user": {
      "id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
      "email": "kamal@farm2route.com",
      "phoneNumber": "+94771234567",
      "fullName": "Kamal Perera",
      "role": "FARMER",
      "status": "PENDING_VERIFICATION",
      "isPhoneVerified": false,
      "isEmailVerified": false,
      "createdAt": "2026-09-02T18:00:00Z"
    },
    "requiresOtp": true
  },
  "timestamp": "2026-09-02T18:00:00Z",
  "path": "/api/v1/auth/register"
}
```

---

## 2. Verify OTP

- **Endpoint**: `POST /api/v1/auth/verify-otp`
- **Access**: Public

### Request Body
```json
{
  "phoneNumber": "+94771234567",
  "otpCode": "123456",
  "purpose": "REGISTRATION"
}
```

### Response (200 OK)
```json
{
  "success": true,
  "message": "OTP verified successfully. Authentication complete.",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "4e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b",
    "tokenType": "Bearer",
    "expiresInMs": 900000,
    "user": {
      "id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
      "phoneNumber": "+94771234567",
      "fullName": "Kamal Perera",
      "role": "FARMER",
      "status": "ACTIVE",
      "isPhoneVerified": true
    },
    "requiresOtp": false
  },
  "timestamp": "2026-09-02T18:01:00Z",
  "path": "/api/v1/auth/verify-otp"
}
```

---

## 3. Login

- **Endpoint**: `POST /api/v1/auth/login`
- **Access**: Public

### Request Body
```json
{
  "identifier": "+94771234567",
  "password": "Password123!"
}
```

---

## 4. Refresh Token

- **Endpoint**: `POST /api/v1/auth/refresh`
- **Access**: Public

### Request Body
```json
{
  "refreshToken": "4e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b"
}
```

---

## 5. Logout

- **Endpoint**: `POST /api/v1/auth/logout`
- **Access**: Authenticated (`Bearer <token>`)

### Request Body
```json
{
  "refreshToken": "4e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b"
}
```

---

## 6. Get Current User

- **Endpoint**: `GET /api/v1/auth/me`
- **Access**: Authenticated (`Bearer <token>`)
