package com.nexore.auth.infrastructure.config.security;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nexore.auth.infrastructure.persistence.entity.RoleApiPolicyEntity;
import com.nexore.auth.infrastructure.persistence.jpa.RoleApiPolicyJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Collections;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class RoleApiPolicyCacheService {

    private static final String      SERVICE_NAME    = "auth";
    private static final String      REDIS_KEY       = "nxc:policies:auth";
    private static final long        POLICY_TTL_SECS = 300;
    private static final ObjectMapper MAPPER         = new ObjectMapper();

    private final RedisTemplate<String, String> redisTemplate;
    private final RoleApiPolicyJpaRepository    policyRepository;

    public void refreshPolicies() {
        List<RoleApiPolicyEntity> entities = policyRepository.findByServiceOrderByPriorityDesc(SERVICE_NAME);
        List<RoleApiPolicyDto> dtos = entities.stream()
                .map(e -> new RoleApiPolicyDto(
                        e.getRoleName(), e.getHttpMethod(),
                        e.getPathPattern(), e.getEffect(), e.getPriority()))
                .toList();
        redisTemplate.opsForValue().set(REDIS_KEY, serialize(dtos), Duration.ofSeconds(POLICY_TTL_SECS));
        log.info("Loaded {} API policies for auth-service into Redis (TTL {}s)", dtos.size(), POLICY_TTL_SECS);
    }

    public List<RoleApiPolicyDto> getPolicies() {
        try {
            String json = redisTemplate.opsForValue().get(REDIS_KEY);
            if (json != null) {
                return deserialize(json);
            }
            log.warn("Auth policy cache miss, loading from DB");
            refreshPolicies();
            json = redisTemplate.opsForValue().get(REDIS_KEY);
            return json != null ? deserialize(json) : Collections.emptyList();
        } catch (Exception e) {
            log.error("Redis unavailable for auth policies, falling back to DB: {}", e.getMessage());
            return policyRepository.findByServiceOrderByPriorityDesc(SERVICE_NAME).stream()
                    .map(en -> new RoleApiPolicyDto(
                            en.getRoleName(), en.getHttpMethod(),
                            en.getPathPattern(), en.getEffect(), en.getPriority()))
                    .toList();
        }
    }

    private String serialize(Object obj) {
        try {
            return MAPPER.writeValueAsString(obj);
        } catch (Exception e) {
            throw new IllegalStateException("Cannot serialize policies to JSON", e);
        }
    }

    private List<RoleApiPolicyDto> deserialize(String json) {
        try {
            return MAPPER.readValue(json, new TypeReference<>() {});
        } catch (Exception e) {
            log.warn("Cannot deserialize auth policies from Redis");
            return Collections.emptyList();
        }
    }
}
