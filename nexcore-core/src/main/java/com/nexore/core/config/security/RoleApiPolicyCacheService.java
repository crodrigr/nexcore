package com.nexore.core.config.security;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nexore.core.module.tenant.infrastructure.persistence.entity.RoleApiPolicyJpaEntity;
import com.nexore.core.module.tenant.infrastructure.persistence.jpa.SpringDataRoleApiPolicyRepository;
import com.nexore.core.module.tenant.infrastructure.persistence.jpa.SpringDataUserRoleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class RoleApiPolicyCacheService {

    private static final String POLICY_KEY_PREFIX   = "nxc:policies:";
    private static final String USER_ROLES_KEY_PREFIX = "nxc:user_roles:";

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final RedisTemplate<String, String> redisTemplate;
    private final SpringDataRoleApiPolicyRepository policyRepository;
    private final SpringDataUserRoleRepository userRoleRepository;

    @Value("${app.api-policy.service-name:core}")
    private String serviceName;

    @Value("${app.api-policy.policy-ttl-seconds:300}")
    private long policyTtlSeconds;

    @Value("${app.api-policy.user-roles-ttl-seconds:120}")
    private long userRolesTtlSeconds;

    // ── Políticas ──────────────────────────────────────────────────

    public void refreshPolicies() {
        List<RoleApiPolicyJpaEntity> entities = policyRepository.findByServiceOrderByPriorityDesc(serviceName);
        List<RoleApiPolicyDto> dtos = entities.stream()
                .map(e -> new RoleApiPolicyDto(
                        e.getRoleName(), e.getHttpMethod(),
                        e.getPathPattern(), e.getEffect(), e.getPriority()))
                .toList();
        String key = POLICY_KEY_PREFIX + serviceName;
        redisTemplate.opsForValue().set(key, serialize(dtos), Duration.ofSeconds(policyTtlSeconds));
        log.info("Loaded {} API policies for service '{}' into Redis (TTL {}s)", dtos.size(), serviceName, policyTtlSeconds);
    }

    public List<RoleApiPolicyDto> getPolicies() {
        String key = POLICY_KEY_PREFIX + serviceName;
        try {
            String json = redisTemplate.opsForValue().get(key);
            if (json != null) {
                return deserializePolicies(json);
            }
            log.warn("Policy cache miss for service '{}', loading from DB", serviceName);
            refreshPolicies();
            json = redisTemplate.opsForValue().get(key);
            return json != null ? deserializePolicies(json) : Collections.emptyList();
        } catch (Exception e) {
            log.error("Redis unavailable, falling back to DB for policies: {}", e.getMessage());
            return loadPoliciesFromDb();
        }
    }

    // ── Roles de usuario ───────────────────────────────────────────

    public List<String> getUserRoles(UUID userId, UUID tenantId) {
        String key = USER_ROLES_KEY_PREFIX + userId + ":" + tenantId;
        try {
            String json = redisTemplate.opsForValue().get(key);
            if (json != null) {
                return deserializeStrings(json);
            }
            List<String> roles = userRoleRepository.findRoleNamesByUserIdAndTenantId(userId, tenantId);
            redisTemplate.opsForValue().set(key, serialize(roles), Duration.ofSeconds(userRolesTtlSeconds));
            return roles;
        } catch (Exception e) {
            log.error("Redis unavailable, falling back to DB for user roles: {}", e.getMessage());
            return userRoleRepository.findRoleNamesByUserIdAndTenantId(userId, tenantId);
        }
    }

    // ── Helpers ────────────────────────────────────────────────────

    private List<RoleApiPolicyDto> loadPoliciesFromDb() {
        return policyRepository.findByServiceOrderByPriorityDesc(serviceName).stream()
                .map(e -> new RoleApiPolicyDto(
                        e.getRoleName(), e.getHttpMethod(),
                        e.getPathPattern(), e.getEffect(), e.getPriority()))
                .toList();
    }

    private String serialize(Object obj) {
        try {
            return MAPPER.writeValueAsString(obj);
        } catch (Exception e) {
            throw new IllegalStateException("Cannot serialize to JSON", e);
        }
    }

    private List<RoleApiPolicyDto> deserializePolicies(String json) {
        try {
            return MAPPER.readValue(json, new TypeReference<>() {});
        } catch (Exception e) {
            log.warn("Cannot deserialize policies from Redis, returning empty list");
            return Collections.emptyList();
        }
    }

    private List<String> deserializeStrings(String json) {
        try {
            return MAPPER.readValue(json, new TypeReference<>() {});
        } catch (Exception e) {
            log.warn("Cannot deserialize user roles from Redis, returning empty list");
            return Collections.emptyList();
        }
    }
}
