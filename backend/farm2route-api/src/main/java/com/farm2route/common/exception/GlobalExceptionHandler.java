package com.farm2route.common.exception;

import com.farm2route.common.filter.RequestCorrelationFilter;
import com.farm2route.common.response.ErrorResponse;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ServiceUnavailableException.class)
    public ResponseEntity<ErrorResponse> handleServiceUnavailableException(ServiceUnavailableException ex, HttpServletRequest request) {
        String requestId = RequestCorrelationFilter.getCorrelationId();
        log.error("Service unavailable error [requestId: {}]: {}", requestId, ex.getMessage());

        ErrorResponse errorResponse = ErrorResponse.builder()
                .success(false)
                .error("ServiceUnavailable")
                .message("Authentication service temporarily unavailable")
                .status(HttpStatus.SERVICE_UNAVAILABLE.value())
                .path(request.getRequestURI())
                .timestamp(Instant.now().toString())
                .build();

        return new ResponseEntity<>(errorResponse, HttpStatus.SERVICE_UNAVAILABLE);
    }

    @ExceptionHandler({AuthenticationException.class, InvalidRefreshTokenException.class})
    public ResponseEntity<ErrorResponse> handleAuthenticationException(RuntimeException ex, HttpServletRequest request) {
        String requestId = RequestCorrelationFilter.getCorrelationId();
        log.warn("Authentication failed [requestId: {}]: {}", requestId, ex.getMessage());

        ErrorResponse errorResponse = ErrorResponse.builder()
                .success(false)
                .error("AuthenticationError")
                .message(ex.getMessage())
                .status(HttpStatus.UNAUTHORIZED.value())
                .path(request.getRequestURI())
                .timestamp(Instant.now().toString())
                .build();

        return new ResponseEntity<>(errorResponse, HttpStatus.UNAUTHORIZED);
    }

    @ExceptionHandler(AccountLockedException.class)
    public ResponseEntity<ErrorResponse> handleAccountLockedException(AccountLockedException ex, HttpServletRequest request) {
        String requestId = RequestCorrelationFilter.getCorrelationId();
        log.warn("Account locked [requestId: {}]: {}", requestId, ex.getMessage());

        ErrorResponse errorResponse = ErrorResponse.builder()
                .success(false)
                .error("AccountLocked")
                .message(ex.getMessage())
                .status(HttpStatus.FORBIDDEN.value())
                .path(request.getRequestURI())
                .timestamp(Instant.now().toString())
                .build();

        return new ResponseEntity<>(errorResponse, HttpStatus.FORBIDDEN);
    }

    @ExceptionHandler({AuthorizationException.class, AccessDeniedException.class})
    public ResponseEntity<ErrorResponse> handleAccessDeniedException(Exception ex, HttpServletRequest request) {
        String requestId = RequestCorrelationFilter.getCorrelationId();
        log.warn("Access denied [requestId: {}]: {}", requestId, ex.getMessage());

        ErrorResponse errorResponse = ErrorResponse.builder()
                .success(false)
                .error("AccessDenied")
                .message("You do not have required permissions to access this resource")
                .status(HttpStatus.FORBIDDEN.value())
                .path(request.getRequestURI())
                .timestamp(Instant.now().toString())
                .build();

        return new ResponseEntity<>(errorResponse, HttpStatus.FORBIDDEN);
    }

    @ExceptionHandler(RateLimitExceededException.class)
    public ResponseEntity<ErrorResponse> handleRateLimitExceededException(RateLimitExceededException ex, HttpServletRequest request) {
        String requestId = RequestCorrelationFilter.getCorrelationId();
        log.warn("Rate limit exceeded [requestId: {}]: {}", requestId, ex.getMessage());

        ErrorResponse errorResponse = ErrorResponse.builder()
                .success(false)
                .error("RateLimitExceeded")
                .message(ex.getMessage())
                .status(HttpStatus.TOO_MANY_REQUESTS.value())
                .path(request.getRequestURI())
                .timestamp(Instant.now().toString())
                .build();

        return new ResponseEntity<>(errorResponse, HttpStatus.TOO_MANY_REQUESTS);
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleResourceNotFoundException(ResourceNotFoundException ex, HttpServletRequest request) {
        ErrorResponse errorResponse = ErrorResponse.builder()
                .success(false)
                .error("NotFound")
                .message(ex.getMessage())
                .status(HttpStatus.NOT_FOUND.value())
                .path(request.getRequestURI())
                .timestamp(Instant.now().toString())
                .build();

        return new ResponseEntity<>(errorResponse, HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(ConflictException.class)
    public ResponseEntity<ErrorResponse> handleConflictException(ConflictException ex, HttpServletRequest request) {
        ErrorResponse errorResponse = ErrorResponse.builder()
                .success(false)
                .error("Conflict")
                .message(ex.getMessage())
                .status(HttpStatus.CONFLICT.value())
                .path(request.getRequestURI())
                .timestamp(Instant.now().toString())
                .build();

        return new ResponseEntity<>(errorResponse, HttpStatus.CONFLICT);
    }

    @ExceptionHandler({InvalidOtpException.class, ExpiredOtpException.class, IllegalArgumentException.class})
    public ResponseEntity<ErrorResponse> handleBadRequestExceptions(RuntimeException ex, HttpServletRequest request) {
        ErrorResponse errorResponse = ErrorResponse.builder()
                .success(false)
                .error("BadRequest")
                .message(ex.getMessage())
                .status(HttpStatus.BAD_REQUEST.value())
                .path(request.getRequestURI())
                .timestamp(Instant.now().toString())
                .build();

        return new ResponseEntity<>(errorResponse, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationExceptions(MethodArgumentNotValidException ex, HttpServletRequest request) {
        Map<String, String> validationErrors = new HashMap<>();
        for (FieldError fieldError : ex.getBindingResult().getFieldErrors()) {
            validationErrors.put(fieldError.getField(), fieldError.getDefaultMessage());
        }

        ErrorResponse errorResponse = ErrorResponse.builder()
                .success(false)
                .error("ValidationError")
                .message("Request payload validation failed")
                .status(HttpStatus.BAD_REQUEST.value())
                .path(request.getRequestURI())
                .validationErrors(validationErrors)
                .timestamp(Instant.now().toString())
                .build();

        return new ResponseEntity<>(errorResponse, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGenericException(Exception ex, HttpServletRequest request) {
        String requestId = RequestCorrelationFilter.getCorrelationId();
        log.error("Unhandled exception [requestId: {}] at {}: {}", requestId, request.getRequestURI(), ex.getMessage(), ex);

        ErrorResponse errorResponse = ErrorResponse.builder()
                .success(false)
                .error("InternalServerError")
                .message("An unexpected error occurred. Please try again later.")
                .status(HttpStatus.INTERNAL_SERVER_ERROR.value())
                .path(request.getRequestURI())
                .timestamp(Instant.now().toString())
                .build();

        return new ResponseEntity<>(errorResponse, HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
