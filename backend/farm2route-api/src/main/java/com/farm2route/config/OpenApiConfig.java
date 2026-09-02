package com.farm2route.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    private static final String SECURITY_SCHEME_NAME = "BearerAuth";

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Farm2Route API Documentation")
                        .version("1.0.0")
                        .description("Industry-standard RESTful and WebSocket API for Farm2Route - Agricultural Logistics and Fleet Management Platform.")
                        .contact(new Contact()
                                .name("Farm2Route Engineering Team")
                                .email("dev@farm2route.com")
                                .url("https://farm2route.com"))
                        .license(new License()
                                .name("Proprietary")
                                .url("https://farm2route.com/terms")))
                .addSecurityItem(new SecurityRequirement().addList(SECURITY_SCHEME_NAME))
                .components(new Components()
                        .addSecuritySchemes(SECURITY_SCHEME_NAME, new SecurityScheme()
                                .name(SECURITY_SCHEME_NAME)
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("Enter your JWT Bearer token to authorize requests.")));
    }
}
