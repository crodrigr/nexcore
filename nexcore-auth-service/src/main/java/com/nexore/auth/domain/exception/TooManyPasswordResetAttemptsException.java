package com.nexore.auth.domain.exception;

public class TooManyPasswordResetAttemptsException extends RuntimeException {
    
    public TooManyPasswordResetAttemptsException(String message) {
        super(message);
    }
}
