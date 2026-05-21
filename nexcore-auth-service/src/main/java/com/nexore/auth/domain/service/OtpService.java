package com.nexore.auth.domain.service;

import com.nexore.auth.domain.model.OtpCode;
import com.nexore.auth.domain.repository.OtpCodeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class OtpService {
    
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    
    @Value("${nexcore.auth.otp.expiry-minutes}")
    private int otpExpiryMinutes;
    
    @Value("${nexcore.auth.otp.max-attempts}")
    private int maxAttempts;
    
    private final OtpCodeRepository otpCodeRepository;
    
    /**
     * Genera un código OTP de 6 dígitos
     */
    public String generateOtpCode() {
        int code = SECURE_RANDOM.nextInt(1_000_000);
        return String.format("%06d", code);
    }
    
    /**
     * Hashea el código OTP con SHA-256
     */
    public String hashOtp(String code) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(code.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(hash);
        } catch (NoSuchAlgorithmException e) {
            log.error("SHA-256 algorithm not available", e);
            throw new OtpHashingException("Failed to hash OTP code", e);
        }
    }
    
    /**
     * Crea y guarda un OTP para login 2FA
     */
    @Transactional
    public OtpCode createLoginOtp(UUID userId, UUID tenantId) {
        // Invalidar OTPs anteriores del usuario para login
        otpCodeRepository.invalidateActiveOtpsByUserAndPurpose(userId, "LOGIN_2FA");
        
        String code = generateOtpCode();
        String codeHash = hashOtp(code);
        
        OtpCode otpCode = OtpCode.builder()
                .id(UUID.randomUUID())
                .userId(userId)
                .tenantId(tenantId)
                .codeHash(codeHash)
                .purpose("LOGIN_2FA")
                .expiresAt(Instant.now().plus(Duration.ofMinutes(otpExpiryMinutes)))
                .attempts(0)
                .createdAt(Instant.now())
                .plainCode(code)  // Solo para enviar por email
                .build();
        
        otpCodeRepository.save(otpCode);
        
        log.info("OTP created for user {} with purpose LOGIN_2FA", userId);
        return otpCode;
    }
    
    /**
     * Valida un código OTP usando timing-safe comparison
     */
    @Transactional
    public void validateOtp(UUID otpCodeId, String providedCode) {
        OtpCode otpCode = otpCodeRepository.findById(otpCodeId)
                .orElseThrow(() -> new OtpNotFoundException("OTP code not found"));
        
        // Verificar si ya fue usado
        if (otpCode.getUsedAt() != null) {
            throw new OtpNotFoundException("OTP code has already been used");
        }
        
        // Verificar expiración
        if (Instant.now().isAfter(otpCode.getExpiresAt())) {
            throw new OtpExpiredException("OTP code has expired");
        }
        
        // Verificar intentos
        if (otpCode.getAttempts() >= maxAttempts) {
            throw new TooManyAttemptsException("Too many failed OTP attempts");
        }
        
        // Timing-safe comparison
        String providedHash = hashOtp(providedCode);
        boolean isValid = MessageDigest.isEqual(
                providedHash.getBytes(StandardCharsets.UTF_8),
                otpCode.getCodeHash().getBytes(StandardCharsets.UTF_8)
        );
        
        if (isValid) {
            // Marcar como usado
            otpCode.setUsedAt(Instant.now());
            otpCodeRepository.save(otpCode);
            log.info("OTP validated successfully for user {}", otpCode.getUserId());
        } else {
            // Incrementar intentos
            otpCode.setAttempts(otpCode.getAttempts() + 1);
            otpCodeRepository.save(otpCode);
            log.warn("Invalid OTP attempt for user {}, attempt {}/{}", 
                    otpCode.getUserId(), otpCode.getAttempts(), maxAttempts);
            throw new OtpNotFoundException("Invalid OTP code");
        }
    }
    
    // Excepciones internas
    
    public static class OtpNotFoundException extends RuntimeException {
        public OtpNotFoundException(String message) {
            super(message);
        }
    }
    
    public static class OtpExpiredException extends RuntimeException {
        public OtpExpiredException(String message) {
            super(message);
        }
    }
    
    public static class TooManyAttemptsException extends RuntimeException {
        public TooManyAttemptsException(String message) {
            super(message);
        }
    }
    
    public static class OtpHashingException extends RuntimeException {
        public OtpHashingException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
