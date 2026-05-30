package com.nexore.auth.infrastructure.config;

import com.nexore.auth.infrastructure.config.security.AuthApiPolicyInterceptor;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.Arrays;

@Configuration
@RequiredArgsConstructor
public class WebConfig implements WebMvcConfigurer {

    private final AuthApiPolicyInterceptor authApiPolicyInterceptor;

    @Value("${app.cors.allowed-origins}")
    private String allowedOrigins;

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        String[] origins = Arrays.stream(allowedOrigins.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toArray(String[]::new);

        registry.addMapping("/**")
                .allowedOrigins(origins)
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // Endpoints públicos: login, verify-otp, password reset (no requieren política)
        registry.addInterceptor(authApiPolicyInterceptor)
                .addPathPatterns("/auth/**")
                .excludePathPatterns(
                        "/auth/login",
                        "/auth/verify-otp",
                        "/auth/password/reset/request",
                        "/auth/password/reset/confirm"
                );
    }
}
