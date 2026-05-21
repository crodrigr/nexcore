package com.nexore.auth.domain.exception;

import java.util.UUID;

public class TenantNotFoundException extends RuntimeException {
    
    private final UUID tenantId;
    
    public TenantNotFoundException(UUID tenantId, String message) {
        super(message);
        this.tenantId = tenantId;
    }
    
    public UUID getTenantId() {
        return tenantId;
    }
}
