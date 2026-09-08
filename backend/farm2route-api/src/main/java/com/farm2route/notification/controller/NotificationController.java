package com.farm2route.notification.controller;

import com.farm2route.common.response.ApiResponse;
import com.farm2route.notification.dto.NotificationDto;
import com.farm2route.notification.service.NotificationService;
import com.farm2route.security.UserPrincipal;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/agency/notifications")
@RequiredArgsConstructor
@PreAuthorize("hasRole('AGENCY')")
@SecurityRequirement(name = "BearerAuth")
@Tag(name = "Agency Notifications")
public class NotificationController {
    private final NotificationService notificationService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<NotificationDto>>> list(
            @AuthenticationPrincipal UserPrincipal principal, HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(notificationService.list(principal.getId()),
                "Notifications retrieved successfully", request.getRequestURI()));
    }

    @GetMapping("/unread-count")
    public ResponseEntity<ApiResponse<Long>> unreadCount(
            @AuthenticationPrincipal UserPrincipal principal, HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(notificationService.unreadCount(principal.getId()),
                "Unread notification count retrieved successfully", request.getRequestURI()));
    }

    @PatchMapping("/{id}/read")
    public ResponseEntity<ApiResponse<NotificationDto>> markRead(
            @AuthenticationPrincipal UserPrincipal principal, @PathVariable UUID id, HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(notificationService.markRead(principal.getId(), id),
                "Notification marked as read", request.getRequestURI()));
    }
}
