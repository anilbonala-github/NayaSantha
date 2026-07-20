package com.nayasantha.api.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** OpenAPI 3 doc with a Bearer JWT scheme (Vol2 §5 requires OpenAPI). */
@Configuration
public class OpenApiConfig {

    @Bean
    OpenAPI nayaSanthaOpenApi() {
        final String scheme = "bearerAuth";
        return new OpenAPI()
                .info(new Info().title("NayaSantha Customer API")
                        .version("v1")
                        .description("Dynamic customer backend (Vol2). All business data is persisted in PostgreSQL."))
                .addSecurityItem(new SecurityRequirement().addList(scheme))
                .components(new Components().addSecuritySchemes(scheme,
                        new SecurityScheme().type(SecurityScheme.Type.HTTP)
                                .scheme("bearer").bearerFormat("JWT")));
    }
}
