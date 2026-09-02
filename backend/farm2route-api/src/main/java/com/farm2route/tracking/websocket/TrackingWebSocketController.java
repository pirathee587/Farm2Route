package com.farm2route.tracking.websocket;

import com.farm2route.tracking.dto.GpsLocationDto;
import com.farm2route.tracking.service.TrackingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import java.util.UUID;

@Slf4j
@Controller
@RequiredArgsConstructor
public class TrackingWebSocketController {

    private final SimpMessagingTemplate messagingTemplate;
    private final TrackingService trackingService;

    /**
     * Drivers stream GPS coordinates to /app/trip/{tripId}/location
     * Subscribed farmers and agencies receive updates on /topic/trip/{tripId}
     */
    @MessageMapping("/trip/{tripId}/location")
    public void receiveGpsUpdate(@DestinationVariable UUID tripId, @Payload GpsLocationDto locationDto) {
        log.debug("Received GPS update for trip {}: lat={}, lng={}", tripId, locationDto.getLatitude(), locationDto.getLongitude());
        locationDto.setTripId(tripId);
        
        // Persist location in database
        trackingService.saveGpsLocation(locationDto);

        // Broadcast to all subscribed listeners for this active trip
        messagingTemplate.convertAndSend("/topic/trip/" + tripId, locationDto);
    }
}
