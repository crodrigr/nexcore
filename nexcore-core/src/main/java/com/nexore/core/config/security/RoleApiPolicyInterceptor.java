package com.nexore.core.config.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.server.PathContainer;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.util.pattern.PathPatternParser;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

@Slf4j
@Component
@RequiredArgsConstructor
public class RoleApiPolicyInterceptor implements HandlerInterceptor {

    private final RoleApiPolicyCacheService cacheService;
    private final PathPatternParser patternParser = new PathPatternParser();

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) throws IOException {

        String actorIdHeader  = request.getHeader("X-Actor-Id");
        String tenantIdHeader = request.getHeader("X-Tenant-Id");

        if (actorIdHeader == null || tenantIdHeader == null) {
            deny(response, HttpServletResponse.SC_UNAUTHORIZED, "Authentication required");
            return false;
        }

        UUID actorId;
        UUID tenantId;
        try {
            actorId  = UUID.fromString(actorIdHeader);
            tenantId = UUID.fromString(tenantIdHeader);
        } catch (IllegalArgumentException e) {
            deny(response, HttpServletResponse.SC_BAD_REQUEST, "Invalid X-Actor-Id or X-Tenant-Id");
            return false;
        }

        String method = request.getMethod();
        String path   = request.getRequestURI();

        List<String> userRoles = cacheService.getUserRoles(actorId, tenantId);
        List<RoleApiPolicyDto> policies = cacheService.getPolicies();

        if (!isAllowed(method, path, userRoles, policies)) {
            log.warn("Access denied: {} {} — actor={} roles={}", method, path, actorId, userRoles);
            deny(response, HttpServletResponse.SC_FORBIDDEN, "Access denied");
            return false;
        }

        return true;
    }

    // ── Evaluación ─────────────────────────────────────────────────

    private boolean isAllowed(String method, String path,
                              List<String> userRoles,
                              List<RoleApiPolicyDto> policies) {

        PathContainer pathContainer = PathContainer.parsePath(path);

        // Policies ya vienen ordenadas por priority DESC desde Redis (cargadas con findByServiceOrderByPriorityDesc)
        for (RoleApiPolicyDto policy : policies) {
            if (!roleMatches(policy.getRoleName(), userRoles)) continue;
            if (!methodMatches(policy.getHttpMethod(), method))  continue;
            if (!pathMatches(policy.getPathPattern(), pathContainer)) continue;

            // Primera política que coincide gana (ya ordenadas por priority DESC)
            boolean allowed = "ALLOW".equals(policy.getEffect());
            log.debug("Policy match: {} {} → {} (role={})", method, path, policy.getEffect(), policy.getRoleName());
            return allowed;
        }

        return false; // fail-closed
    }

    private boolean roleMatches(String policyRole, List<String> userRoles) {
        return "*".equals(policyRole) || userRoles.contains(policyRole);
    }

    private boolean methodMatches(String policyMethod, String requestMethod) {
        return "*".equals(policyMethod) || policyMethod.equalsIgnoreCase(requestMethod);
    }

    private boolean pathMatches(String pattern, PathContainer pathContainer) {
        try {
            return patternParser.parse(pattern).matches(pathContainer);
        } catch (Exception e) {
            return false;
        }
    }

    // ── Respuesta de error ──────────────────────────────────────────

    private void deny(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write("{\"status\":" + status + ",\"error\":\"" + message + "\"}");
    }
}
