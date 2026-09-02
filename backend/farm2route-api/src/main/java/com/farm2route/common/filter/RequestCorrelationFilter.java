package com.farm2route.common.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class RequestCorrelationFilter extends OncePerRequestFilter {

    public static final String HEADER_REQUEST_ID = "X-Request-ID";
    public static final String MDC_REQUEST_ID_KEY = "requestId";

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain) throws ServletException, IOException {

        String requestId = request.getHeader(HEADER_REQUEST_ID);
        if (!StringUtils.hasText(requestId)) {
            requestId = UUID.randomUUID().toString();
        } else {
            // Sanitize incoming requestId (alphanumeric and hyphens only, max 64 chars)
            requestId = requestId.replaceAll("[^a-zA-Z0-9-]", "");
            if (requestId.length() > 64) {
                requestId = requestId.substring(0, 64);
            }
        }

        MDC.put(MDC_REQUEST_ID_KEY, requestId);
        response.setHeader(HEADER_REQUEST_ID, requestId);
        request.setAttribute(HEADER_REQUEST_ID, requestId);

        try {
            filterChain.doFilter(request, response);
        } finally {
            MDC.remove(MDC_REQUEST_ID_KEY);
        }
    }

    public static String getCorrelationId() {
        String id = MDC.get(MDC_REQUEST_ID_KEY);
        return id != null ? id : UUID.randomUUID().toString();
    }
}
