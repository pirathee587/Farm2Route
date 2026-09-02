# Farm2Route — Scalable Agricultural Logistics & Fleet Management

[![Java 21](https://img.shields.io/badge/Java-21-blue.svg)](https://openjdk.org/projects/jdk/21/)
[![Spring Boot 3.3.4](https://img.shields.io/badge/Spring%20Boot-3.3.4-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg)](https://flutter.dev/)
[![Database](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E.svg)](https://supabase.com/)

**Farm2Route** is an industry-standard, scalable agricultural logistics and fleet management platform engineered for university final-year excellence and real-world deployment. The platform connects farmers directly with verified logistics agencies and drivers, eliminating intermediary inefficiencies through transparent pricing, live GPS telemetry, digital Proof of Delivery (POD), and automated financial settlements.

---

## Architecture Overview

```
Farm2Route/
├── backend/
│   └── farm2route-api/          # Spring Boot 3 API (Java 21, Security 6, JWT, Flyway, WebSocket)
├── mobile/
│   └── farm2route_app/          # Flutter Clean Architecture (Riverpod, Dio, SecureStorage, GoRouter)
├── database/
│   ├── migrations/              # Flyway migrations V1 to V16
│   ├── seed/                    # Development seed SQL
│   └── documentation/           # Schema design guide
├── docs/
│   ├── API/                     # REST API Contracts
│   ├── Architecture/            # System Architecture, Auth Flow, Team Divisions
│   └── ERD/                     # Entity Relationship Diagrams
├── docker-compose.yml           # Local & cloud development services
└── README.md
```

---

## Technology Stack

### Backend
- **Core**: Java 21, Spring Boot 3.3.4, Maven
- **Security**: Spring Security 6, JWT (io.jsonwebtoken 0.12.6), BCrypt (work factor 12)
- **Token Management**: Server-side Refresh Token Rotation & Token Blacklist Service
- **OTP Subsystem**: Pluggable `OtpProvider` interface (Mock & Twilio implementations)
- **Persistence**: Spring Data JPA, Hibernate, PostgreSQL, Flyway Migrations (V1 to V16)
- **Real-Time Telemetry**: STOMP over WebSocket for live driver GPS tracking
- **Storage**: Supabase Storage REST API abstraction (`SupabaseStorageService`)
- **API Documentation**: OpenAPI 3.0 & Swagger UI (`/swagger-ui.html`)
- **Testing**: JUnit 5, Mockito, Spring Security Test, H2 In-Memory DB

### Mobile
- **Core**: Flutter 3 (Dart), Material 3 Design
- **Architecture**: Feature-First Clean Architecture
- **State Management**: Flutter Riverpod (`StateNotifierProvider`)
- **Networking**: Dio with `AuthInterceptor` (auto token refresh on 401 & retry)
- **Secure Storage**: `flutter_secure_storage` (Android Keystore / iOS Keychain)
- **Navigation**: GoRouter with asynchronous role-based route guards

---

## Three-Member Team Boundaries

| Member | Responsibilities | Backend Scope | Mobile Scope |
|---|---|---|---|
| **Member 1** | Auth, Farmer & Booking | `auth`, `farmer`, `booking`, `smart/recommendation` | `features/auth`, `features/farmer`, `features/booking`, `features/profile` |
| **Member 2** | Agency, Fleet & Drivers | `agency`, `driver`, `maintenance`, `smart/assignment`, `finance` | `features/agency`, `features/driver`, `features/maintenance` |
| **Member 3** | Admin, Tracking, POD & Incidents | `admin`, `tracking`, `pod`, `incident`, `review`, `notification`, `audit` | `features/admin`, `features/tracking`, `features/pod`, `features/incident`, `features/notification` |

---

## Quick Start Guide

### 1. Backend Setup & Run

```bash
# Navigate to backend API
cd backend/farm2route-api

# Copy environment variables
cp .env.example .env

# Run automated tests
mvn clean test

# Run application locally
mvn spring-boot:run
```

- **Swagger UI**: [http://localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html)
- **API Base URL**: `http://localhost:8080/api/v1`

### 2. Mobile Setup & Run

```bash
# Navigate to Flutter app
cd mobile/farm2route_app

# Install dependencies
flutter pub get

# Run on emulator/device
flutter run
```

---

## Required Environment Variables

| Variable | Description | Example |
|---|---|---|
| `DB_HOST` | Supabase / PostgreSQL Host | `aws-0-ap-southeast-1.pooler.supabase.com` |
| `DB_PORT` | Database Port | `5432` |
| `DB_NAME` | Database Name | `postgres` |
| `DB_USER` | Database User | `postgres.your-ref` |
| `DB_PASSWORD` | Database Password | `your-secure-password` |
| `JWT_SECRET` | 256-bit Base64 Secret | `404E6352...` |
| `SUPABASE_URL` | Supabase Project URL | `https://your-ref.supabase.co` |
| `SUPABASE_SERVICE_KEY`| Supabase Service Role Key | `eyJhbGci...` |
| `OTP_PROVIDER` | OTP provider (`mock` or `twilio`) | `mock` |
