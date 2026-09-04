package com.farm2route.driver.dto;

import com.farm2route.common.enums.DriverAvailability;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateDriverRequest {

    private String fullName;
    private String drivingLicenseNumber;
    private LocalDate licenseExpiryDate;
    private String nicNumber;
    private DriverAvailability availabilityStatus;
}
