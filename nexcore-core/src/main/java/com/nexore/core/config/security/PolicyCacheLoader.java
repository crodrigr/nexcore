package com.nexore.core.config.security;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class PolicyCacheLoader {

    private final RoleApiPolicyCacheService cacheService;

    @EventListener(ApplicationReadyEvent.class)
    public void loadOnStartup() {
        try {
            cacheService.refreshPolicies();
        } catch (Exception e) {
            log.error("Could not load API policies into Redis on startup — interceptor will use DB fallback: {}", e.getMessage());
        }
    }
}
