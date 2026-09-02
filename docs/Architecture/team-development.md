# Farm2Route — Three-Member Team Ownership & Feature Boundaries

To maximize parallel development velocity without merge conflicts, the codebase is modularized by domain boundaries.

---

## Team Division Matrix

| Member | Domain Responsibilities | Backend Packages | Mobile Features |
|---|---|---|---|
| **Member 1** | **Authentication, Farmer & Booking Management** | `com.farm2route.auth`<br>`com.farm2route.farmer`<br>`com.farm2route.booking`<br>`com.farm2route.smart.recommendation` | `features/auth`<br>`features/farmer`<br>`features/booking`<br>`features/profile` |
| **Member 2** | **Agency Fleet, Driver & Maintenance** | `com.farm2route.agency`<br>`com.farm2route.driver`<br>`com.farm2route.maintenance`<br>`com.farm2route.smart.assignment`<br>`com.farm2route.finance` | `features/agency`<br>`features/driver`<br>`features/maintenance` |
| **Member 3** | **Admin Operations, Live Tracking & Quality Control** | `com.farm2route.admin`<br>`com.farm2route.tracking`<br>`com.farm2route.pod`<br>`com.farm2route.incident`<br>`com.farm2route.review`<br>`com.farm2route.notification`<br>`com.farm2route.audit` | `features/admin`<br>`features/tracking`<br>`features/pod`<br>`features/incident`<br>`features/notification` |

---

## Git Workflow Guidelines

1. `main`: Production-ready releases only.
2. `develop`: Integration staging branch.
3. Feature branches:
   - `feature/auth`
   - `feature/farmer`
   - `feature/agency`
   - `feature/driver`
   - `feature/admin`
   - `feature/tracking`
   - `feature/pod`
   - `feature/incident`
   - `feature/review`
   - `feature/finance`
