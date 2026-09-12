package com.farm2route.agency.dashboard.dto;

import com.farm2route.finance.dto.AgencyEarningsSummaryDto;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class AgencyDashboardResponse {
    BookingSummary bookingSummary;
    DriverSummary driverSummary;
    VehicleSummary vehicleSummary;
    AssignmentSummary assignmentSummary;
    MaintenanceSummary maintenanceSummary;
    AgencyEarningsSummaryDto financeSummary;

    @Value @Builder
    public static class BookingSummary {
        long total;
        long pending;
        long accepted;
        long rejected;
        long assigned;
        long delivered;
        long cancelled;
    }

    @Value @Builder
    public static class DriverSummary {
        long total;
        long approved;
        long pending;
        long available;
        long unavailable;
    }

    @Value @Builder
    public static class VehicleSummary {
        long total;
        long approved;
        long pending;
        long available;
        long underMaintenance;
    }

    @Value @Builder
    public static class AssignmentSummary {
        long assigned;
        long active;
        long completed;
        long unassignedBookings;
    }

    @Value @Builder
    public static class MaintenanceSummary {
        long inProgress;
        long scheduled;
        long overdue;
    }
}
