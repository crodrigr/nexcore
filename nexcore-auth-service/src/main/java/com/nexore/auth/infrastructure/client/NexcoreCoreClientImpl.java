package com.nexore.auth.infrastructure.client;

import com.nexore.auth.domain.service.NexcoreCoreClient;
import com.nexore.auth.domain.service.TokenService;
import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

@Slf4j
@Component
@RequiredArgsConstructor
public class NexcoreCoreClientImpl implements NexcoreCoreClient {
    
    private final RestTemplate restTemplate;
    private final TokenService tokenService;
    
    @Value("${nexcore.core.url}")
    private String coreUrl;
    
    @Value("${nexcore.core.endpoints.user-profile}")
    private String userProfileEndpoint;
    
    @Override
    public Object getUserProfile(String accessToken) {
        String url = coreUrl + userProfileEndpoint;
        
        // Extract userId and tenantId from JWT
        Claims claims = tokenService.validateToken(accessToken);
        String actorId = claims.getSubject();
        String tenantId = claims.get("tid", String.class);
        
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);
        headers.set("X-Actor-Id", actorId);
        headers.set("X-Tenant-Id", tenantId);
        
        HttpEntity<Void> request = new HttpEntity<>(headers);
        
        try {
            ResponseEntity<Object> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    request,
                    Object.class
            );
            
            log.info("Successfully fetched user profile from nexcore-core");
            return response.getBody();
            
        } catch (RestClientException e) {
            log.error("Failed to fetch user profile from nexcore-core: {}", e.getMessage());
            throw new RuntimeException("Failed to fetch user profile", e);
        }
    }
}
