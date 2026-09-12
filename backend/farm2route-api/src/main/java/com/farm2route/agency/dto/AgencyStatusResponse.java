package com.farm2route.agency.dto;

import com.farm2route.agency.enums.AgencyStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AgencyStatusResponse {

    private UUID agencyId;
    private String email;
    private String phoneNumber;
    private AgencyStatus status;
    private boolean emailVerified;
    private boolean phoneVerified;
    private String rejectionReason;
}
