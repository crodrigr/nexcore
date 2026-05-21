package com.nexore.auth.domain.exception;

import java.util.UUID;

public class TenantInactiveException extends RuntimeException {
    
    private final UUID tenantId;
    
    public TenantInactiveException(UUID tenantId, String message) {
        super(message);
        this.tenantId = tenantId;
    }
    
    public UUID getTenantId() {
        return tenantId;
    }
}
