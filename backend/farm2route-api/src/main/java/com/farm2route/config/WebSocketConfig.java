package com.farm2route.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // Enable a simple memory-based message broker for prefixes like /topic and /queue
        config.enableSimpleBroker("/topic", "/queue");
        // Application destination prefix for incoming messages (@MessageMapping)
        config.setApplicationDestinationPrefixes("/app");
        // User destination prefix for private messaging
        config.setUserDestinationPrefix("/user");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // Main WebSocket STOMP endpoint for mobile & web clients
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*")
                .withSockJS();

        // Native WebSocket without SockJS fallback
        registry.addEndpoint("/ws-native")
                .setAllowedOriginPatterns("*");
    }
}
