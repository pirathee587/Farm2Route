package com.farm2route.pod.controller;

import com.farm2route.common.response.ApiResponse;
import com.farm2route.pod.dto.ConfirmPodRequest;
import com.farm2route.pod.dto.PodDto;
import com.farm2route.pod.dto.SubmitPodRequest;
import com.farm2route.pod.service.PodService;
import com.farm2route.security.CustomUserPrincipal;
import com.farm2route.security.UserPrincipal;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/v1/bookings/{bookingId}/pod")
@RequiredArgsConstructor
public class PodController {

    private final PodService podService;

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<PodDto>> submitPod(
            @PathVariable UUID bookingId,
            @Valid @RequestPart("data") SubmitPodRequest request,
            @RequestPart("signature") MultipartFile signature,
            @RequestPart("photo") MultipartFile photo,
            @AuthenticationPrincipal Object principal) throws IOException {

        UUID driverUserId = extractUserId(principal);
        PodDto podDto = podService.submit(bookingId, driverUserId, request, signature, photo);
        return ResponseEntity.ok(ApiResponse.success("Proof of Delivery submitted successfully", podDto));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PodDto>> getPod(
            @PathVariable UUID bookingId,
            @AuthenticationPrincipal Object principal) {

        UUID userId = extractUserId(principal);
        String role = extractRole(principal);

        PodDto podDto = podService.getPodByBookingId(bookingId, userId, role);
        return ResponseEntity.ok(ApiResponse.success(podDto));
    }

    @PostMapping("/confirm")
    public ResponseEntity<ApiResponse<PodDto>> confirmPod(
            @PathVariable UUID bookingId,
            @Valid @RequestBody ConfirmPodRequest request,
            @AuthenticationPrincipal Object principal) {

        UUID farmerUserId = extractUserId(principal);
        PodDto podDto = podService.confirm(bookingId, farmerUserId, request);
        return ResponseEntity.ok(ApiResponse.success("Proof of Delivery confirmation recorded", podDto));
    }

    private UUID extractUserId(Object principal) {
        if (principal instanceof UserPrincipal up) {
            return up.getId();
        } else if (principal instanceof CustomUserPrincipal cup) {
            return cup.getId();
        }
        return null;
    }

    private String extractRole(Object principal) {
        if (principal instanceof UserPrincipal up) {
            return up.getRole() != null ? up.getRole().name() : null;
        } else if (principal instanceof CustomUserPrincipal cup) {
            return cup.getAuthorities().stream()
                    .findFirst()
                    .map(a -> a.getAuthority())
                    .orElse(null);
        }
        return null;
    }
}
