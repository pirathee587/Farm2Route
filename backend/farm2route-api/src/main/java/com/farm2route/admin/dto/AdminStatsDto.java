package com.farm2route.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminStatsDto {
    private long totalUsers;
    private long totalFarmers;
    private long totalAgencies;
    private long totalDrivers;
    private long pendingKycs;
    private long activeBookings;
    private long openIncidents;
}
