package com.nexore.auth.infrastructure.web;

import com.nexore.auth.application.dto.response.ApiError;
import com.nexore.auth.domain.exception.*;
import com.nexore.auth.domain.service.BruteForceProtection;
import com.nexore.auth.domain.service.OtpService;
import com.nexore.auth.domain.service.TokenService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    /**
     * Validación de campos (Bean Validation)
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidationException(
            MethodArgumentNotValidException ex,
            HttpServletRequest request) {
        
        List<ApiError.FieldError> fieldErrors = ex.getBindingResult()
                .getAllErrors()
                .stream()
                .map(error -> {
                    String fieldName = error instanceof FieldError ? ((FieldError) error).getField() : error.getObjectName();
                    return ApiError.FieldError.builder()
                            .field(fieldName)
                            .message(error.getDefaultMessage())
                            .rejectedValue(error instanceof FieldError ? ((FieldError) error).getRejectedValue() : null)
                            .build();
                })
                .collect(Collectors.toList());
        
        ApiError apiError = ApiError.builder()
                .code("NXC-AUTH-0001")
                .message("Validation failed")
                .timestamp(Instant.now())
                .path(request.getRequestURI())
                .status(HttpStatus.BAD_REQUEST.value())
                .fieldErrors(fieldErrors)
                .build();
        
        log.warn("Validation error: {}", apiError);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(apiError);
    }
    
    /**
     * Credenciales inválidas
     */
    @ExceptionHandler(InvalidCredentialsException.class)
    public ResponseEntity<ApiError> handleInvalidCredentials(
            InvalidCredentialsException ex,
            HttpServletRequest request) {
        
        ApiError apiError = ApiError.builder()
                .code("NXC-AUTH-0002")
                .message(ex.getMessage())
                .timestamp(Instant.now())
                .path(request.getRequestURI())
                .status(HttpStatus.UNAUTHORIZED.value())
                .build();
        
        log.warn("Invalid credentials: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(apiError);
    }
    
    /**
     * Usuario suspendido
     */
    @ExceptionHandler(UserSuspendedException.class)
    public ResponseEntity<ApiError> handleUserSuspended(
            UserSuspendedException ex,
            HttpServletRequest request) {
        
        ApiError apiError = ApiError.builder()
                .code("NXC-AUTH-0003")
                .message(ex.getMessage())
                .timestamp(Instant.now())
                .path(request.getRequestURI())
                .status(HttpStatus.FORBIDDEN.value())
                .build();
        
        log.warn("User suspended: userId={}", ex.getUserId());
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(apiError);
    }
    
    /**
     * Tenant inactivo
     */
    @ExceptionHandler(TenantInactiveException.class)
    public ResponseEntity<ApiError> handleTenantInactive(
            TenantInactiveException ex,
            HttpServletRequest request) {
        
        ApiError apiError = ApiError.builder()
                .code("NXC-AUTH-0004")
                .message(ex.getMessage())
                .timestamp(Instant.now())
                .path(request.getRequestURI())
                .status(HttpStatus.FORBIDDEN.value())
                .build();
        
        log.warn("Tenant inactive: tenantId={}", ex.getTenantId());
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(apiError);
    }
    
    /**
     * Tenant no encontrado
     */
    @ExceptionHandler(TenantNotFoundException.class)
    public ResponseEntity<ApiError> handleTenantNotFound(
            TenantNotFoundException ex,
            HttpServletRequest request) {
        
        ApiError apiError = ApiError.builder()
                .code("NXC-AUTH-0005")
                .message(ex.getMessage())
                .timestamp(Instant.now())
                .path(request.getRequestURI())
                .status(HttpStatus.NOT_FOUND.value())
                .build();
        
        log.warn("Tenant not found: tenantId={}", ex.getTenantId());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(apiError);
    }
    
    /**
     * OTP inválido
     */
    @ExceptionHandler({InvalidOtpException.class, OtpService.OtpNotFoundException.class,
            OtpService.OtpExpiredException.class})
    public ResponseEntity<ApiError> handleInvalidOtp(
            Exception ex,
            HttpServletRequest request) {
        
        ApiError apiError = ApiError.builder()
                .code("NXC-AUTH-0006")
                .message(ex.getMessage())
                .timestamp(Instant.now())
                .path(request.getRequestURI())
                .status(HttpStatus.UNAUTHORIZED.value())
                .build();
        
        log.warn("Invalid OTP: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(apiError);
    }
    
    /**
     * Demasiados intentos de OTP
     */
    @ExceptionHandler(OtpService.TooManyAttemptsException.class)
    public ResponseEntity<ApiError> handleTooManyOtpAttempts(
            OtpService.TooManyAttemptsException ex,
            HttpServletRequest request) {
        
        ApiError apiError = ApiError.builder()
                .code("NXC-AUTH-0007")
                .message(ex.getMessage())
                .timestamp(Instant.now())
                .path(request.getRequestURI())
                .status(HttpStatus.TOO_MANY_REQUESTS.value())
                .build();
        
        log.warn("Too many OTP attempts");
        return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(apiError);
    }
    
    /**
     * Protección contra fuerza bruta
     */
    @ExceptionHandler(BruteForceProtection.TooManyAttemptsException.class)
    public ResponseEntity<ApiError> handleBruteForce(
            BruteForceProtection.TooManyAttemptsException ex,
            HttpServletRequest request) {
        
        ApiError apiError = ApiError.builder()
                .code("NXC-AUTH-0008")
                .message(ex.getMessage())
                .timestamp(Instant.now())
                .path(request.getRequestURI())
                .status(HttpStatus.TOO_MANY_REQUESTS.value())
                .build();
        
        log.warn("Brute force protection triggered");
        return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(apiError);
    }
    
    /**
     * Token JWT inválido
     */
    @ExceptionHandler(TokenService.InvalidTokenException.class)
    public ResponseEntity<ApiError> handleInvalidToken(
            TokenService.InvalidTokenException ex,
            HttpServletRequest request) {
        
        ApiError apiError = ApiError.builder()
                .code("NXC-AUTH-0009")
                .message(ex.getMessage())
                .timestamp(Instant.now())
                .path(request.getRequestURI())
                .status(HttpStatus.UNAUTHORIZED.value())
                .build();
        
        log.warn("Invalid token: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(apiError);
    }
    
    /**
     * Token JWT expirado
     */
    @ExceptionHandler(TokenService.TokenExpiredException.class)
    public ResponseEntity<ApiError> handleExpiredToken(
            TokenService.TokenExpiredException ex,
            HttpServletRequest request) {
        
        ApiError apiError = ApiError.builder()
                .code("NXC-AUTH-0010")
                .message(ex.getMessage())
                .timestamp(Instant.now())
                .path(request.getRequestURI())
                .status(HttpStatus.UNAUTHORIZED.value())
                .build();
        
        log.warn("Token expired: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(apiError);
    }
    
    /**
     * Error al enviar email
     */
    @ExceptionHandler(EmailSendingException.class)
    public ResponseEntity<ApiError> handleEmailSending(
            EmailSendingException ex,
            HttpServletRequest request) {
        
        ApiError apiError = ApiError.builder()
                .code("NXC-AUTH-0011")
                .message("Failed to send email. Please try again later")
                .timestamp(Instant.now())
                .path(request.getRequestURI())
                .status(HttpStatus.INTERNAL_SERVER_ERROR.value())
                .build();
        
        log.error("Email sending error: {}", ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(apiError);
    }
    
    /**
     * Contraseñas no coinciden
     */
    @ExceptionHandler(PasswordMismatchException.class)
    public ResponseEntity<ApiError> handlePasswordMismatch(
            PasswordMismatchException ex,
            HttpServletRequest request) {
        
        ApiError apiError = ApiError.builder()
                .code("NXC-AUTH-0012")
                .message(ex.getMessage())
                .timestamp(Instant.now())
                .path(request.getRequestURI())
                .status(HttpStatus.BAD_REQUEST.value())
                .build();
        
        log.warn("Password mismatch");
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(apiError);
    }
    
    /**
     * Token de reset de contraseña inválido
     */
    @ExceptionHandler(InvalidPasswordResetTokenException.class)
    public ResponseEntity<ApiError> handleInvalidResetToken(
            InvalidPasswordResetTokenException ex,
            HttpServletRequest request) {
        
        ApiError apiError = ApiError.builder()
                .code("NXC-AUTH-0013")
                .message(ex.getMessage())
                .timestamp(Instant.now())
                .path(request.getRequestURI())
                .status(HttpStatus.UNAUTHORIZED.value())
                .build();
        
        log.warn("Invalid password reset token");
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(apiError);
    }
    
    /**
     * Demasiados intentos de reset de contraseña
     */
    @ExceptionHandler(TooManyPasswordResetAttemptsException.class)
    public ResponseEntity<ApiError> handleTooManyResetAttempts(
            TooManyPasswordResetAttemptsException ex,
            HttpServletRequest request) {
        
        ApiError apiError = ApiError.builder()
                .code("NXC-AUTH-0014")
                .message(ex.getMessage())
                .timestamp(Instant.now())
                .path(request.getRequestURI())
                .status(HttpStatus.TOO_MANY_REQUESTS.value())
                .build();
        
        log.warn("Too many password reset attempts");
        return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(apiError);
    }
    
    /**
     * Sesión no encontrada
     */
    @ExceptionHandler(SessionNotFoundException.class)
    public ResponseEntity<ApiError> handleSessionNotFound(
            SessionNotFoundException ex,
            HttpServletRequest request) {
        
        ApiError apiError = ApiError.builder()
                .code("NXC-AUTH-0015")
                .message(ex.getMessage())
                .timestamp(Instant.now())
                .path(request.getRequestURI())
                .status(HttpStatus.NOT_FOUND.value())
                .build();
        
        log.warn("Session not found: sessionId={}", ex.getSessionId());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(apiError);
    }
    
    /**
     * Excepción genérica
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleGenericException(
            Exception ex,
            HttpServletRequest request) {
        
        ApiError apiError = ApiError.builder()
                .code("NXC-AUTH-0099")
                .message("An unexpected error occurred")
                .timestamp(Instant.now())
                .path(request.getRequestURI())
                .status(HttpStatus.INTERNAL_SERVER_ERROR.value())
                .build();
        
        log.error("Unexpected error", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(apiError);
    }
}
