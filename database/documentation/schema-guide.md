# Farm2Route Database Architecture & Schema Guide

## Overview

Farm2Route's relational database layer is hosted on **Supabase PostgreSQL** and managed through **Flyway** migrations (`V1` to `V17`).
All entities use UUID primary keys for distributed scalability and safety against enumeration attacks.

---

## Migration Index

| Version | Migration Script | Description |
|---|---|---|
| `V1` | `V1__create_users.sql` | Core identity table (`users`) with phone/email, role, status, and verification flags |
| `V2` | `V2__create_authentication_tables.sql` | Server-side `refresh_tokens` and `otp_verifications` tables |
| `V3` | `V3__create_farmer_tables.sql` | `farmer_profiles` with geolocation and agricultural characteristics |
| `V4` | `V4__create_agency_tables.sql` | `agency_profiles` with KYC compliance, tax identification, and business registration |
| `V5` | `V5__create_driver_tables.sql` | `driver_profiles` with driving licenses, KYC status, and ratings |
| `V6` | `V6__create_vehicle_tables.sql` | `vehicles` fleet tracking payloads, refrigeration, and insurance |
| `V7` | `V7__create_package_tables.sql` | `packages` offering pricing per km/kg, routes, and schedules |
| `V8` | `V8__create_booking_tables.sql` | `bookings` lifecycle state machine and cargo parameters |
| `V9` | `V9__create_tracking_tables.sql` | `trip_assignments` and high-frequency `gps_locations` |
| `V10` | `V10__create_pod_tables.sql` | `pod_records` digital signatures, geotagged photos, and farmer confirmation |
| `V11` | `V11__create_incident_tables.sql` | `incident_reports` and media attachments (`incident_evidence`) |
| `V12` | `V12__create_review_tables.sql` | `reviews` with two-way driver/agency ratings and admin moderation |
| `V13` | `V13__create_maintenance_tables.sql` | `vehicle_maintenance` schedules, costs, and service history |
| `V14` | `V14__create_notification_tables.sql` | In-app push/websocket notifications |
| `V15` | `V15__create_finance_tables.sql` | `bank_details`, `transactions`, and `withdrawals` |
| `V16` | `V16__create_audit_tables.sql` | Immutable `audit_logs` tracking sensitive system mutations |
| `V17` | `V17__create_agency_earnings_and_withdrawal_requests.sql` | Agency earnings ledger and withdrawal requests |
