package com.farm2route.common.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.BAD_REQUEST)
public class ExpiredOtpException extends RuntimeException {
    public ExpiredOtpException(String message) {
        super(message);
    }
}
