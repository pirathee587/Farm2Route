package com.farm2route.common.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {

    @Builder.Default
    private boolean success = true;

    private String message;

    private T data;

    @Builder.Default
    private String timestamp = Instant.now().toString();

    private String path;

    public static <T> ApiResponse<T> ok(T data, String message, String path) {
        return ApiResponse.<T>builder()
                .success(true)
                .message(message)
                .data(data)
                .timestamp(Instant.now().toString())
                .path(path)
                .build();
    }

    public static <T> ApiResponse<T> ok(T data, String message) {
        return ok(data, message, null);
    }

    public static <T> ApiResponse<T> ok(T data) {
        return ok(data, "Operation successful", null);
    }

    public static <T> ApiResponse<T> created(T data, String message, String path) {
        return ApiResponse.<T>builder()
                .success(true)
                .message(message)
                .data(data)
                .timestamp(Instant.now().toString())
                .path(path)
                .build();
    }
}
