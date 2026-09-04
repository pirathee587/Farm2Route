package com.farm2route.transport.controller;

import com.farm2route.common.response.ApiResponse;
import com.farm2route.transport.dto.PriceEstimationRequest;
import com.farm2route.transport.dto.PriceEstimationResponse;
import com.farm2route.transport.dto.TransportRecommendationRequest;
import com.farm2route.transport.dto.TransportRecommendationResponse;
import com.farm2route.transport.service.PriceEstimationService;
import com.farm2route.transport.service.TransportRecommendationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/v1/transport")
@RequiredArgsConstructor
@Tag(name = "Smart Transport Recommendations & Pricing", description = "Endpoints for vehicle recommendations and real-time price estimation")
@SecurityRequirement(name = "BearerAuth")
public class TransportRecommendationController {

    private final TransportRecommendationService transportRecommendationService;
    private final PriceEstimationService priceEstimationService;

    @PostMapping("/recommendations")
    @Operation(
            summary = "Get Smart Transport Recommendations",
            description = "Ranks and returns suitable vehicles based on cargo weight, distance, availability, and vehicle suitability"
    )
    public ResponseEntity<ApiResponse<TransportRecommendationResponse>> getRecommendations(
            @Valid @RequestBody TransportRecommendationRequest request) {

        log.info("Received transport recommendation request for pickup: '{}' -> destination: '{}'",
                request.getPickupLocation(), request.getDestination());

        TransportRecommendationResponse response = transportRecommendationService.getRecommendations(request);
        return ResponseEntity.ok(ApiResponse.ok(response, "Transport recommendations retrieved successfully"));
    }

    @PostMapping("/price-estimate")
    @Operation(
            summary = "Calculate Transportation Price Estimation",
            description = "Calculates an itemized transportation price estimate before booking confirmation"
    )
    public ResponseEntity<ApiResponse<PriceEstimationResponse>> estimatePrice(
            @Valid @RequestBody PriceEstimationRequest request) {

        log.info("Received price estimate request for vehicleType: {}, weight: {} kg",
                request.getVehicleType(), request.getRequiredCapacity());

        PriceEstimationResponse response = priceEstimationService.estimatePrice(request);
        return ResponseEntity.ok(ApiResponse.ok(response, "Price estimate calculated successfully"));
    }
}
