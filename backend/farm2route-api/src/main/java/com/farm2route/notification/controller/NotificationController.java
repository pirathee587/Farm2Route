package com.farm2route.notification.controller;

import com.farm2route.common.response.ApiResponse;
import com.farm2route.notification.dto.NotificationDto;
import com.farm2route.notification.service.NotificationService;
import com.farm2route.security.CustomUserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
@Tag(name = "Notification Module", description = "Endpoints for managing in-app notifications")
@SecurityRequirement(name = "BearerAuth")
@PreAuthorize("isAuthenticated()")
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping
    @Operation(summary = "Get In-App Notifications", description = "Retrieves paginated in-app notification history for the authenticated user")
    public ResponseEntity<ApiResponse<Page<NotificationDto>>> getNotifications(
            @AuthenticationPrincipal CustomUserPrincipal principal,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable,
            HttpServletRequest request) {
        Page<NotificationDto> history = notificationService.getInAppHistory(principal.getId(), pageable);
        return ResponseEntity.ok(ApiResponse.ok(history, "Notifications retrieved successfully", request.getRequestURI()));
    }

    @GetMapping("/unread-count")
    @Operation(summary = "Get Unread Notification Count", description = "Retrieves count of unread notifications for the authenticated user")
    public ResponseEntity<ApiResponse<Map<String, Long>>> getUnreadCount(
            @AuthenticationPrincipal CustomUserPrincipal principal,
            HttpServletRequest request) {
        long count = notificationService.getUnreadCount(principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(Map.of("unreadCount", count), "Unread notification count retrieved successfully", request.getRequestURI()));
    }

    @PatchMapping("/{id}/read")
    @Operation(summary = "Mark Notification as Read", description = "Marks a specific notification as read for the authenticated user")
    public ResponseEntity<ApiResponse<NotificationDto>> markAsRead(
            @PathVariable UUID id,
            @AuthenticationPrincipal CustomUserPrincipal principal,
            HttpServletRequest request) {
        NotificationDto notification = notificationService.markAsRead(id, principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(notification, "Notification marked as read", request.getRequestURI()));
    }
}
