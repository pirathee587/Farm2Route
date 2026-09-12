package com.farm2route.trip.dto;

import com.farm2route.common.enums.TripStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TripAssignmentResponse {

    private UUID assignmentId;
    private UUID bookingId;
    private UUID driverId;
    private UUID vehicleId;
    private TripStatus status;
    private Instant startedAt;
    private Instant completedAt;
    private Instant createdAt;
    private Instant updatedAt;
}
