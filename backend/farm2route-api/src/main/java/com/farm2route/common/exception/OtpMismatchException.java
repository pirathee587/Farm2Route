package com.farm2route.common.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.BAD_REQUEST)
public class OtpMismatchException extends InvalidOtpException {

    public OtpMismatchException(String message) {
        super(message);
    }
}
