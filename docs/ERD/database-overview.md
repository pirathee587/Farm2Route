# Farm2Route — Entity Relationship Diagram & Database Overview

```mermaid
erDiagram
    users ||--o| farmer_profiles : "has"
    users ||--o| agency_profiles : "has"
    users ||--o| driver_profiles : "has"
    users ||--o{ refresh_tokens : "owns"
    users ||--o{ bank_details : "owns"
    users ||--o{ notifications : "receives"
    users ||--o{ audit_logs : "triggers"

    agency_profiles ||--o{ driver_profiles : "employs"
    agency_profiles ||--o{ vehicles : "owns"
    agency_profiles ||--o{ packages : "offers"
    agency_profiles ||--o{ bookings : "receives"

    farmer_profiles ||--o{ bookings : "creates"
    farmer_profiles ||--o{ reviews : "writes"

    vehicles ||--o{ trip_assignments : "assigned_to"
    vehicles ||--o{ vehicle_maintenance : "undergoes"

    bookings ||--o| trip_assignments : "executes"
    bookings ||--o| pod_records : "validated_by"
    bookings ||--o{ incident_reports : "associated_with"
    bookings ||--o| reviews : "receives"
    bookings ||--o{ transactions : "generates"

    trip_assignments ||--o{ gps_locations : "streams"
    incident_reports ||--o{ incident_evidence : "contains"
```

---

## Entity Summary Table

| Entity | Primary Key | Key Foreign Keys | Purpose |
|---|---|---|---|
| `users` | `UUID` | - | Identity, credentials hash, role, account status |
| `refresh_tokens` | `UUID` | `user_id` | Server-side refresh token rotation and revocation tracking |
| `otp_verifications` | `UUID` | - | Transient OTP lifecycle with attempt counters and rate limits |
| `farmer_profiles` | `UUID` | `user_id` | Farm location, acreage, and crop specializations |
| `agency_profiles` | `UUID` | `user_id` | Business registration, tax ID, and KYC compliance |
| `driver_profiles` | `UUID` | `user_id`, `agency_id` | Driving license, NIC, KYC status, and ratings |
| `vehicles` | `UUID` | `agency_id`, `assigned_driver_id` | Registration number, payload weight, volume, refrigeration |
| `packages` | `UUID` | `agency_id` | Rates per km/kg, origin-destination routes, schedule days |
| `bookings` | `UUID` | `farmer_id`, `agency_id`, `driver_id` | Cargo specs, addresses, status state-machine, fare |
| `trip_assignments` | `UUID` | `booking_id`, `driver_id`, `vehicle_id` | Active dispatch and transit workflow |
| `gps_locations` | `UUID` | `trip_id`, `booking_id`, `driver_id` | High-frequency telemetry coordinates for live tracking |
| `pod_records` | `UUID` | `booking_id`, `driver_id` | Geotagged delivery photo, digital recipient signature |
| `incident_reports` | `UUID` | `booking_id`, `reported_by_user_id` | Cargo damage, accident, delays, or theft investigation |
| `incident_evidence`| `UUID` | `incident_id` | Attached evidence images/videos |
| `reviews` | `UUID` | `booking_id`, `farmer_id`, `agency_id` | Dual-sided driver & agency ratings and feedback |
| `vehicle_maintenance` | `UUID` | `vehicle_id` | Maintenance service log and cost records |
| `notifications` | `UUID` | `user_id` | Real-time push and in-app alerts |
| `transactions` | `UUID` | `booking_id`, `payer_user_id`, `payee_user_id` | Payments, commission deductions, and payouts |
| `audit_logs` | `UUID` | `actor_id` | Immutable security audit trail |
