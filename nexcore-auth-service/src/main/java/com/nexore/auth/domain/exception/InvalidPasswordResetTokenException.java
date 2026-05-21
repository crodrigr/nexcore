package com.nexore.auth.domain.exception;

public class InvalidPasswordResetTokenException extends RuntimeException {
    
    public InvalidPasswordResetTokenException(String message) {
        super(message);
    }
    
    public InvalidPasswordResetTokenException(String message, Throwable cause) {
        super(message, cause);
    }
}
