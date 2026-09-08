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

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
@SecurityRequirement(name = "BearerAuth")
@Tag(name = "Notifications")
public class NotificationController {
    private final NotificationService notificationService;

    @GetMapping("/api/v1/agency/notifications")
    @PreAuthorize("hasRole('AGENCY')")
    public ResponseEntity<ApiResponse<List<NotificationDto>>> list(
            @AuthenticationPrincipal UserPrincipal principal, HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(notificationService.list(principal.getId()),
                "Notifications retrieved successfully", request.getRequestURI()));
    }

    @GetMapping("/api/v1/agency/notifications/unread-count")
    @PreAuthorize("hasRole('AGENCY')")
    public ResponseEntity<ApiResponse<Long>> unreadCount(
            @AuthenticationPrincipal UserPrincipal principal, HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(notificationService.unreadCount(principal.getId()),
                "Unread notification count retrieved successfully", request.getRequestURI()));
    }

    @PatchMapping("/api/v1/agency/notifications/{id}/read")
    @PreAuthorize("hasRole('AGENCY')")
    public ResponseEntity<ApiResponse<NotificationDto>> markRead(
            @AuthenticationPrincipal UserPrincipal principal, @PathVariable UUID id, HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(notificationService.markRead(principal.getId(), id),
                "Notification marked as read", request.getRequestURI()));
    }

    @GetMapping("/api/v1/notifications")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Get User Notifications")
    public ResponseEntity<ApiResponse<Page<NotificationDto>>> getNotifications(
            @AuthenticationPrincipal UserPrincipal principal,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable,
            HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(notificationService.getHistory(principal.getId(), pageable),
                "Notifications retrieved successfully", request.getRequestURI()));
    }

    @GetMapping("/api/v1/notifications/unread-count")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Long>>> getUnreadCount(
            @AuthenticationPrincipal UserPrincipal principal, HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(Map.of("unreadCount", notificationService.getUnreadCount(principal.getId())),
                "Unread notification count retrieved successfully", request.getRequestURI()));
    }

    @PatchMapping("/api/v1/notifications/{id}/read")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<NotificationDto>> markAsRead(
            @PathVariable UUID id, @AuthenticationPrincipal UserPrincipal principal, HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(notificationService.markAsRead(id, principal.getId()),
                "Notification marked as read", request.getRequestURI()));
    }
}
