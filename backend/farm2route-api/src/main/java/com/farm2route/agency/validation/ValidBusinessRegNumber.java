package com.farm2route.agency.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.*;

@Documented
@Constraint(validatedBy = ValidBusinessRegNumberValidator.class)
@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
public @interface ValidBusinessRegNumber {

    String message() default "Business registration number is required for Company and Partnership agencies";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
