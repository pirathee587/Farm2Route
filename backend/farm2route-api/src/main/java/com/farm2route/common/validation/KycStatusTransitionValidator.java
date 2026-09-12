package com.farm2route.common.validation;

import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.exception.BusinessRuleException;
import com.farm2route.common.exception.ForbiddenException;

public final class KycStatusTransitionValidator {

    private KycStatusTransitionValidator() {
    }

    public static void requireAgencySubmission(KycStatus requestedStatus) {
        if (requestedStatus != KycStatus.PENDING && requestedStatus != KycStatus.PENDING_APPROVAL) {
            throw new ForbiddenException("Only an administrator can approve, reject, or suspend KYC");
        }
    }

    public static void requireAdminDecision(KycStatus currentStatus, KycStatus requestedStatus) {
        if (currentStatus == null) {
            currentStatus = KycStatus.PENDING;
        }
        if (requestedStatus == null || requestedStatus == KycStatus.PENDING
                || requestedStatus == KycStatus.PENDING_APPROVAL) {
            throw new BusinessRuleException("Administrator review must choose APPROVED, REJECTED, or SUSPENDED");
        }

        boolean valid = switch (currentStatus) {
            case PENDING, PENDING_APPROVAL -> requestedStatus == KycStatus.APPROVED
                    || requestedStatus == KycStatus.REJECTED;
            case APPROVED -> requestedStatus == KycStatus.SUSPENDED;
            case SUSPENDED -> requestedStatus == KycStatus.APPROVED;
            case REJECTED -> false;
        };

        if (!valid) {
            throw new BusinessRuleException(
                    "Invalid KYC status transition: " + currentStatus + " -> " + requestedStatus);
        }
    }
}
