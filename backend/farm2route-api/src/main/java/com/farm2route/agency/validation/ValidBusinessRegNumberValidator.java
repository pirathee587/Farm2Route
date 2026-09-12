package com.farm2route.agency.validation;

import com.farm2route.agency.dto.AgencySignupRequest;
import com.farm2route.agency.enums.AgencyType;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class ValidBusinessRegNumberValidator implements ConstraintValidator<ValidBusinessRegNumber, AgencySignupRequest> {

    @Override
    public boolean isValid(AgencySignupRequest request, ConstraintValidatorContext context) {
        if (request == null || request.getAgencyType() == null) {
            return true;
        }

        AgencyType type = request.getAgencyType();
        if (type == AgencyType.COMPANY || type == AgencyType.PARTNERSHIP) {
            String brn = request.getBusinessRegNumber();
            if (brn == null || brn.trim().isEmpty()) {
                context.disableDefaultConstraintViolation();
                context.buildConstraintViolationWithTemplate("Business registration number is required for " + type.name())
                        .addPropertyNode("businessRegNumber")
                        .addConstraintViolation();
                return false;
            }
        }

        return true;
    }
}
