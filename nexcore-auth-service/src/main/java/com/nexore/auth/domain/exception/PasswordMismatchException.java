package com.nexore.auth.domain.exception;

public class PasswordMismatchException extends RuntimeException {
    
    public PasswordMismatchException(String message) {
        super(message);
    }
}
