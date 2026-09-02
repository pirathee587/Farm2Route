package com.farm2route.smart.assignment;

import java.util.UUID;

public interface AssignmentEngine {
    /**
     * Matches and assigns the most suitable available driver and vehicle for an accepted booking
     * while checking capacity, current trip status, maintenance schedules, and route history.
     */
    AssignmentResult matchAndAssign(UUID bookingId, UUID agencyId);

    record AssignmentResult(UUID vehicleId, UUID driverId, double matchScore, String rationale) {}
}
