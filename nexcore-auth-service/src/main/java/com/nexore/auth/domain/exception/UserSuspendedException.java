package com.nexore.auth.domain.exception;

import java.util.UUID;

public class UserSuspendedException extends RuntimeException {
    
    private final UUID userId;
    
    public UserSuspendedException(UUID userId, String message) {
        super(message);
        this.userId = userId;
    }
    
    public UUID getUserId() {
        return userId;
    }
}
