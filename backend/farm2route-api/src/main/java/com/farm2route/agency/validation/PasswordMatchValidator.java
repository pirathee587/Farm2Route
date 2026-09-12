package com.farm2route.agency.validation;

import com.farm2route.agency.dto.AgencySignupRequest;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class PasswordMatchValidator implements ConstraintValidator<PasswordMatch, AgencySignupRequest> {

    @Override
    public boolean isValid(AgencySignupRequest request, ConstraintValidatorContext context) {
        if (request == null) {
            return true;
        }

        if (request.getPassword() == null || request.getConfirmPassword() == null) {
            return true; // Let @NotBlank handle null checks
        }

        boolean matched = request.getPassword().equals(request.getConfirmPassword());
        if (!matched) {
            context.disableDefaultConstraintViolation();
            context.buildConstraintViolationWithTemplate(context.getDefaultConstraintMessageTemplate())
                    .addPropertyNode("confirmPassword")
                    .addConstraintViolation();
        }

        return matched;
    }
}
