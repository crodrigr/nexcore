package com.nexore.auth.application.service;

import com.nexore.auth.application.dto.request.ChangePasswordRequest;
import com.nexore.auth.application.dto.request.PasswordResetConfirmRequest;
import com.nexore.auth.application.dto.request.PasswordResetRequest;
import com.nexore.auth.application.dto.response.MessageResponse;
import com.nexore.auth.domain.exception.*;
import com.nexore.auth.domain.model.PasswordReset;
import com.nexore.auth.domain.model.User;
import com.nexore.auth.domain.repository.PasswordResetRepository;
import com.nexore.auth.domain.repository.TenantRepository;
import com.nexore.auth.domain.repository.UserRepository;
import com.nexore.auth.domain.service.EmailService;
import com.nexore.auth.domain.service.OtpService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.servlet.http.HttpServletRequest;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class PasswordService {
    
    private final UserRepository userRepository;
    private final TenantRepository tenantRepository;
    private final PasswordResetRepository passwordResetRepository;
    private final EmailService emailService;
    private final OtpService otpService;
    private final HttpServletRequest httpRequest;
    
    @Value("${nexcore.auth.password-reset.expiry-minutes}")
    private int expiryMinutes;
    
    @Value("${nexcore.auth.password-reset.max-requests-per-hour}")
    private int maxRequestsPerHour;
    
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final int BCrypt_COST = 12;
    
    /**
     * Solicitar reset de contraseña
     */
    @Transactional
    public MessageResponse requestPasswordReset(PasswordResetRequest request) {
        String ipAddress = getClientIp();
        
        // Validar tenant
        tenantRepository.findById(request.getTenantId())
                .orElseThrow(() -> new TenantNotFoundException(request.getTenantId(), "Tenant not found"));
        
        // Buscar usuario por email
        User user = userRepository.findByTenantIdAndEmail(request.getTenantId(), request.getEmail())
                .orElse(null);
        
        // Por seguridad, siempre devolver el mismo mensaje aunque el usuario no exista
        if (user == null) {
            log.info("Password reset requested for non-existent email {} in tenant {}", 
                    request.getEmail(), request.getTenantId());
            return MessageResponse.builder()
                    .message("If the email exists, a password reset link has been sent")
                    .build();
        }
        
        // Verificar límite de solicitudes
        long recentRequests = passwordResetRepository.countResetRequestsByUserSinceLastHour(user.getId());
        if (recentRequests >= maxRequestsPerHour) {
            log.warn("Too many password reset requests for user {}", user.getId());
            throw new TooManyPasswordResetAttemptsException(
                    "Too many password reset requests. Please try again later");
        }
        
        // Invalidar todos los tokens anteriores del usuario
        passwordResetRepository.invalidateAllByUserId(user.getId());
        
        // Generar token aleatorio (URL-safe)
        String resetToken = generateResetToken();
        String tokenHash = otpService.hashOtp(resetToken);  // SHA-256
        
        // Crear registro de password reset
        PasswordReset passwordReset = PasswordReset.builder()
                .id(UUID.randomUUID())
                .userId(user.getId())
                .tenantId(user.getTenantId())
                .tokenHash(tokenHash)
                .ipAddress(ipAddress)
                .createdAt(Instant.now())
                .expiresAt(Instant.now().plus(Duration.ofMinutes(expiryMinutes)))
                .build();
        
        passwordResetRepository.save(passwordReset);
        
        // Enviar email con el token
        try {
            emailService.sendPasswordResetEmail(user.getEmail(), user.getUsername(), resetToken);
        } catch (Exception e) {
            log.error("Failed to send password reset email to user {}", user.getEmail(), e);
            throw new EmailSendingException("Failed to send password reset email", e);
        }
        
        log.info("Password reset requested for user {} from IP {}", user.getUsername(), ipAddress);
        
        return MessageResponse.builder()
                .message("If the email exists, a password reset link has been sent")
                .build();
    }
    
    /**
     * Confirmar reset de contraseña con token
     */
    @Transactional
    public MessageResponse confirmPasswordReset(PasswordResetConfirmRequest request) {
        // Validar que las contraseñas coincidan
        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new PasswordMismatchException("Passwords do not match");
        }
        
        // Hash del token para buscar en BD
        String tokenHash = otpService.hashOtp(request.getToken());
        
        // Buscar token
        PasswordReset passwordReset = passwordResetRepository.findByTokenHash(tokenHash)
                .orElseThrow(() -> new InvalidPasswordResetTokenException("Invalid or expired reset token"));
        
        // Verificar que no haya sido usado
        if (passwordReset.getUsedAt() != null) {
            throw new InvalidPasswordResetTokenException("Reset token has already been used");
        }
        
        // Verificar que no haya expirado
        if (passwordReset.getExpiresAt().isBefore(Instant.now())) {
            throw new InvalidPasswordResetTokenException("Reset token has expired");
        }
        
        // Obtener usuario
        User user = userRepository.findById(passwordReset.getUserId())
                .orElseThrow(() -> new InvalidCredentialsException("User not found"));
        
        // Hashear nueva contraseña
        String newPasswordHash = BCrypt.hashpw(request.getNewPassword(), BCrypt.gensalt(BCrypt_COST));
        
        // Actualizar contraseña del usuario
        user.setPasswordHash(newPasswordHash);
        user.setUpdatedAt(Instant.now());
        userRepository.save(user);
        
        // Marcar token como usado
        passwordReset.setUsedAt(Instant.now());
        passwordResetRepository.save(passwordReset);
        
        // Enviar email de confirmación
        try {
            emailService.sendPasswordChangedEmail(user.getEmail(), user.getUsername());
        } catch (Exception e) {
            log.error("Failed to send password changed email to user {}", user.getEmail(), e);
            // No lanzamos excepción, el cambio de contraseña fue exitoso
        }
        
        log.info("Password reset completed for user {}", user.getUsername());
        
        return MessageResponse.builder()
                .message("Password has been reset successfully")
                .build();
    }
    
    /**
     * Cambiar contraseña por usuario autenticado
     */
    @Transactional
    public MessageResponse changePassword(UUID userId, ChangePasswordRequest request) {
        // Validar que las contraseñas coincidan
        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new PasswordMismatchException("Passwords do not match");
        }
        
        // Obtener usuario
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new InvalidCredentialsException("User not found"));
        
        // Verificar contraseña actual
        boolean passwordMatches = BCrypt.checkpw(request.getCurrentPassword(), user.getPasswordHash());
        if (!passwordMatches) {
            throw new InvalidCredentialsException("Current password is incorrect");
        }
        
        // Hashear nueva contraseña
        String newPasswordHash = BCrypt.hashpw(request.getNewPassword(), BCrypt.gensalt(BCrypt_COST));
        
        // Actualizar contraseña
        user.setPasswordHash(newPasswordHash);
        user.setUpdatedAt(Instant.now());
        userRepository.save(user);
        
        // Enviar email de confirmación
        try {
            emailService.sendPasswordChangedEmail(user.getEmail(), user.getUsername());
        } catch (Exception e) {
            log.error("Failed to send password changed email to user {}", user.getEmail(), e);
        }
        
        log.info("Password changed for user {}", user.getUsername());
        
        return MessageResponse.builder()
                .message("Password has been changed successfully")
                .build();
    }
    
    // Helper methods
    
    private String generateResetToken() {
        byte[] randomBytes = new byte[32];
        SECURE_RANDOM.nextBytes(randomBytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes);
    }
    
    private String getClientIp() {
        String xForwardedFor = httpRequest.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        return httpRequest.getRemoteAddr();
    }
}
