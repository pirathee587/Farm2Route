package com.farm2route.transport.controller;

import com.farm2route.common.enums.VehicleType;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.transport.dto.PriceEstimationRequest;
import com.farm2route.transport.dto.PriceEstimationResponse;
import com.farm2route.transport.dto.TransportRecommendationRequest;
import com.farm2route.transport.dto.TransportRecommendationResponse;
import com.farm2route.transport.service.PriceEstimationService;
import com.farm2route.transport.service.TransportRecommendationService;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TransportRecommendationControllerTest {

    @Mock
    private TransportRecommendationService transportRecommendationService;

    @Mock
    private PriceEstimationService priceEstimationService;

    @InjectMocks
    private TransportRecommendationController controller;

    private Validator validator;

    @BeforeEach
    void setUp() {
        ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
        validator = factory.getValidator();
    }

    @Test
    @DisplayName("Should return 200 OK and recommendations on valid request")
    void shouldReturnRecommendationsSuccessfully() {
        TransportRecommendationRequest request = TransportRecommendationRequest.builder()
                .pickupLocation("Kurunegala")
                .destination("Colombo")
                .requiredCapacity(new BigDecimal("1000.00"))
                .vehicleType(VehicleType.TRUCK)
                .build();

        TransportRecommendationResponse mockResponse = TransportRecommendationResponse.builder()
                .pickupLocation("Kurunegala")
                .destination("Colombo")
                .estimatedDistanceKm(new BigDecimal("85.00"))
                .requiredCapacityKg(new BigDecimal("1000.00"))
                .totalCandidatesFound(1)
                .recommendations(List.of())
                .build();

        when(transportRecommendationService.getRecommendations(any(TransportRecommendationRequest.class)))
                .thenReturn(mockResponse);

        ResponseEntity<ApiResponse<TransportRecommendationResponse>> entity = controller.getRecommendations(request);

        assertThat(entity.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(entity.getBody()).isNotNull();
        assertThat(entity.getBody().isSuccess()).isTrue();
        assertThat(entity.getBody().getData().getEstimatedDistanceKm()).isEqualByComparingTo("85.00");
    }

    @Test
    @DisplayName("Should return 200 OK and price estimate on valid request")
    void shouldReturnPriceEstimateSuccessfully() {
        PriceEstimationRequest request = PriceEstimationRequest.builder()
                .pickupLocation("Kurunegala")
                .destination("Colombo")
                .vehicleType(VehicleType.TRUCK)
                .requiredCapacity(new BigDecimal("1000.00"))
                .build();

        PriceEstimationResponse mockResponse = PriceEstimationResponse.builder()
                .estimatedDistanceKm(new BigDecimal("85.00"))
                .vehicleType(VehicleType.TRUCK)
                .baseFare(new BigDecimal("5000.00"))
                .estimatedTotal(new BigDecimal("21000.00"))
                .build();

        when(priceEstimationService.estimatePrice(any(PriceEstimationRequest.class)))
                .thenReturn(mockResponse);

        ResponseEntity<ApiResponse<PriceEstimationResponse>> entity = controller.estimatePrice(request);

        assertThat(entity.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(entity.getBody()).isNotNull();
        assertThat(entity.getBody().isSuccess()).isTrue();
        assertThat(entity.getBody().getData().getBaseFare()).isEqualByComparingTo("5000.00");
    }

    @Test
    @DisplayName("Validation should fail on blank pickup location or non-positive capacity")
    void shouldValidateRecommendationRequestConstraints() {
        TransportRecommendationRequest invalidRequest = TransportRecommendationRequest.builder()
                .pickupLocation("") // blank
                .destination("Colombo")
                .requiredCapacity(new BigDecimal("-50.00")) // negative
                .build();

        var violations = validator.validate(invalidRequest);
        assertThat(violations).hasSize(2);
    }

    @Test
    @DisplayName("Validation should fail on missing vehicleType or blank destination for price estimation")
    void shouldValidatePriceEstimationRequestConstraints() {
        PriceEstimationRequest invalidRequest = PriceEstimationRequest.builder()
                .pickupLocation("Kurunegala")
                .destination("") // blank
                .vehicleType(null) // null
                .requiredCapacity(BigDecimal.ZERO) // non-positive
                .build();

        var violations = validator.validate(invalidRequest);
        assertThat(violations).hasSize(3);
    }
}
