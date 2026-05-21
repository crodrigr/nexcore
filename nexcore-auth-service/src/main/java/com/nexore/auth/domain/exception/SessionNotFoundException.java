package com.nexore.auth.domain.exception;

import java.util.UUID;

public class SessionNotFoundException extends RuntimeException {
    
    private final UUID sessionId;
    
    public SessionNotFoundException(UUID sessionId, String message) {
        super(message);
        this.sessionId = sessionId;
    }
    
    public UUID getSessionId() {
        return sessionId;
    }
}
