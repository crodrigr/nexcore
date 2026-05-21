package com.nexore.auth.domain.repository;

import com.nexore.auth.domain.model.OtpCode;

import java.util.Optional;
import java.util.UUID;

/**
 * Repositorio para gestionar códigos OTP
 */
public interface OtpCodeRepository {
    
    OtpCode save(OtpCode otpCode);
    
    Optional<OtpCode> findById(UUID id);
    
    Optional<OtpCode> findActiveOtpByUserAndPurpose(UUID userId, String purpose);
    
    void invalidateActiveOtpsByUserAndPurpose(UUID userId, String purpose);
}
