package com.nexore.auth.infrastructure.config.security;

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

/**
 * Interceptor para nexcore-auth-service.
 *
 * Los endpoints de auth NO tienen X-Actor-Id/X-Tenant-Id (son pre-autenticación),
 * así que el chequeo se hace por whitelist: ¿existe alguna política ALLOW para
 * service='auth' que cubra este método + path?
 *
 * Todos los endpoints protegidos del auth-service tienen role_name='*'
 * (cualquier usuario autenticado puede llamarlos). La autenticación real
 * (validación del refresh token / JWT) la hace el código de aplicación.
 *
 * Los endpoints públicos se excluyen en WebConfig.addInterceptors().
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AuthApiPolicyInterceptor implements HandlerInterceptor {

    private final RoleApiPolicyCacheService cacheService;
    private final PathPatternParser patternParser = new PathPatternParser();

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) throws IOException {

        String method = request.getMethod();
        String path   = request.getRequestURI();

        List<RoleApiPolicyDto> policies = cacheService.getPolicies();

        if (!isAllowed(method, path, policies)) {
            log.warn("Auth policy denied: {} {}", method, path);
            deny(response, HttpServletResponse.SC_FORBIDDEN, "Access denied");
            return false;
        }

        return true;
    }

    // ── Evaluación (whitelist por wildcard '*') ─────────────────────

    private boolean isAllowed(String method, String path, List<RoleApiPolicyDto> policies) {
        PathContainer pathContainer = PathContainer.parsePath(path);

        for (RoleApiPolicyDto policy : policies) {
            if (!methodMatches(policy.getHttpMethod(), method))      continue;
            if (!pathMatches(policy.getPathPattern(), pathContainer)) continue;

            boolean allowed = "ALLOW".equals(policy.getEffect());
            log.debug("Auth policy match: {} {} → {}", method, path, policy.getEffect());
            return allowed;
        }

        return false; // fail-closed
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

    private void deny(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write("{\"status\":" + status + ",\"error\":\"" + message + "\"}");
    }
}
