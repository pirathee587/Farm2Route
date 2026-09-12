package com.farm2route.agency.dto;

import com.farm2route.agency.enums.AgencyStatus;
import com.farm2route.agency.enums.AgencyType;
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
public class AgencyResponse {

    private UUID id;
    private String agencyName;
    private String email;
    private String phoneNumber;
    private AgencyType agencyType;
    private String businessRegNumber;
    private String district;
    private String address;
    private String contactPersonName;
    private AgencyStatus status;
    private boolean emailVerified;
    private boolean phoneVerified;
    private String rejectionReason;
    private Instant rejectedAt;
    private Instant createdAt;
    private Instant updatedAt;
}
