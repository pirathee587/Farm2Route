package com.farm2route.common.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.CONFLICT)
public class DuplicatePhoneException extends DuplicateResourceException {

    public DuplicatePhoneException(String message) {
        super(message);
    }
}
