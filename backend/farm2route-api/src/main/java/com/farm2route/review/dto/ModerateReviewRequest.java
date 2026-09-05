package com.farm2route.review.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ModerateReviewRequest {

    private String action; // HIDE, RESTORE, ESCALATE
    private String reason;
}
