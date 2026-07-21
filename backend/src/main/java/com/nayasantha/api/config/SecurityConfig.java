package com.nayasantha.api.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.nayasantha.api.common.GlobalExceptionHandler.ApiError;
import com.nayasantha.api.common.ErrorCode;
import com.nayasantha.api.security.JwtAuthFilter;
import org.slf4j.MDC;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

/** Stateless JWT security (Vol2 §11). Public: auth + docs; everything else authenticated. */
@Configuration
@EnableConfigurationProperties(AppProperties.class)
public class SecurityConfig {

    private static final String[] PUBLIC = {
            "/api/v1/auth/**", "/api/v1/ping", "/api/v1/gemini-check",
            "/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html", "/actuator/health"
    };

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http, JwtAuthFilter jwtAuthFilter,
                                    ObjectMapper mapper) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .cors(cors -> cors.configurationSource(corsSource()))
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(PUBLIC).permitAll()
                .anyRequest().authenticated())
            .exceptionHandling(e -> e.authenticationEntryPoint((req, res, ex) -> {
                res.setStatus(ErrorCode.UNAUTHORIZED.status().value());
                res.setContentType(MediaType.APPLICATION_JSON_VALUE);
                mapper.writeValue(res.getWriter(), new ApiError(
                        ErrorCode.UNAUTHORIZED.name(), ErrorCode.UNAUTHORIZED.userMessage(),
                        ex.getMessage(), MDC.get("traceId")));
            }))
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    private CorsConfigurationSource corsSource() {
        CorsConfiguration c = new CorsConfiguration();
        c.setAllowedOriginPatterns(List.of("*"));   // tighten per environment before prod
        c.setAllowedMethods(List.of("GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"));
        c.setAllowedHeaders(List.of("*"));
        UrlBasedCorsConfigurationSource src = new UrlBasedCorsConfigurationSource();
        src.registerCorsConfiguration("/**", c);
        return src;
    }
}
