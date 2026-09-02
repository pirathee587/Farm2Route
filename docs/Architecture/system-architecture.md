# Farm2Route — System Architecture Specification

## 1. High-Level Architectural Overview

Farm2Route is an agricultural logistics and fleet management platform engineered to connect farmers directly with verified logistics agencies and drivers, eliminating intermediary exploitation and optimizing harvest transportation through real-time GPS telemetry, Proof of Delivery (POD) validation, and automated financial settlements.

```mermaid
graph TD
    subgraph Client Layer
        F[Farmer Flutter App]
        A[Agency Flutter App]
        D[Driver Flutter App]
        AD[Admin Web / Console]
    end

    subgraph API & Security Layer
        GW[Spring Boot 3 API Gateway / REST / WebSocket]
        SEC[Spring Security 6 + JWT + BCrypt + Blacklist]
        WS[STOMP WebSocket Message Broker]
    end

    subgraph Core Domain Modules
        AUTH[Auth & OTP Engine]
        FARM[Farmer Domain]
        AGY[Agency Domain]
        DRV[Driver Domain]
        BKG[Booking State Machine]
        TRK[Live GPS Tracking]
        POD[Proof of Delivery Engine]
        INC[Incident Resolution]
        REV[Review Moderation]
        SMART[Smart Recommendation, Matching & Pricing]
        FIN[Finance & Wallet]
        AUD[Audit Trail Service]
    end

    subgraph Infrastructure & Persistence Layer
        DB[(Supabase PostgreSQL Database)]
        STG[Supabase Storage Buckets]
        SMS[Twilio / SMS Gateway]
    end

    F -->|HTTPS REST / WSS| GW
    A -->|HTTPS REST / WSS| GW
    D -->|HTTPS REST / WSS| GW
    AD -->|HTTPS REST| GW

    GW --> SEC
    GW --> WS

    SEC --> AUTH
    AUTH --> SMS

    GW --> FARM
    GW --> AGY
    GW --> DRV
    GW --> BKG
    GW --> TRK
    GW --> POD
    GW --> INC
    GW --> REV
    GW --> SMART
    GW --> FIN
    GW --> AUD

    FARM & AGY & DRV & BKG & TRK & POD & INC & REV & FIN & AUD --> DB
    POD & INC & AGY & DRV --> STG
```

---

## 2. Technology Stack & Framework Choices

### Backend
- **Language/Platform**: Java 21 LTS
- **Framework**: Spring Boot 3.3.4
- **Security**: Spring Security 6, JJWT (HMAC-SHA256), BCrypt (Cost factor 12)
- **Data Access**: Spring Data JPA / Hibernate
- **Database**: Supabase PostgreSQL managed via Flyway (`V1` to `V16`)
- **Real-Time Telemetry**: Spring WebSocket with STOMP over SockJS
- **Documentation**: OpenAPI 3.0 / Swagger UI (SpringDoc 2.6.0)

### Mobile
- **Framework**: Flutter 3 (Dart)
- **Design System**: Material 3 Responsive Architecture
- **State Management**: Flutter Riverpod (`StateNotifierProvider`)
- **Networking**: Dio with `AuthInterceptor` (automatic refresh token rotation)
- **Secure Persistence**: `flutter_secure_storage` (Android Keystore / iOS Keychain)
- **Navigation**: GoRouter with asynchronous auth state redirect guards
