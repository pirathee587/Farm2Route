package com.farm2route.finance.dto;

import lombok.Builder;
import lombok.Value;

import java.math.BigDecimal;

@Value
@Builder
public class AgencyEarningsSummaryDto {
    BigDecimal grossEarnings;
    BigDecimal commission;
    BigDecimal netEarnings;
    BigDecimal withdrawn;
    BigDecimal availableBalance;
}
