package com.farm2route.notification.controller;

import com.farm2route.common.response.ApiResponse;
import com.farm2route.notification.dto.NotificationDto;
import com.farm2route.notification.service.NotificationService;
import com.farm2route.security.UserPrincipal;
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
@Tag(name = "Notifications Module", description = "Endpoints for managing in-app notifications")
@SecurityRequirement(name = "BearerAuth")
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Get User Notifications", description = "Retrieves paged history of notifications for the authenticated user")
    public ResponseEntity<ApiResponse<Page<NotificationDto>>> getNotifications(
            @AuthenticationPrincipal UserPrincipal principal,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable,
            HttpServletRequest request) {
        Page<NotificationDto> notifications = notificationService.getHistory(principal.getId(), pageable);
        return ResponseEntity.ok(ApiResponse.ok(notifications, "Notifications retrieved successfully", request.getRequestURI()));
    }

    @GetMapping("/unread-count")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Get Unread Count", description = "Retrieves unread notification count for the authenticated user")
    public ResponseEntity<ApiResponse<Map<String, Long>>> getUnreadCount(
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest request) {
        long count = notificationService.getUnreadCount(principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(Map.of("unreadCount", count), "Unread notification count retrieved successfully", request.getRequestURI()));
    }

    @PatchMapping("/{id}/read")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Mark Notification as Read", description = "Marks a notification as read for the authenticated user")
    public ResponseEntity<ApiResponse<NotificationDto>> markAsRead(
            @PathVariable("id") UUID id,
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest request) {
        NotificationDto updated = notificationService.markAsRead(id, principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(updated, "Notification marked as read", request.getRequestURI()));
    }
}
