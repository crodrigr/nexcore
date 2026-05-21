package com.nexore.auth.infrastructure.persistence.mapper;

import com.nexore.auth.domain.model.*;
import com.nexore.auth.infrastructure.persistence.entity.*;
import org.springframework.stereotype.Component;

@Component
public class EntityMapper {
    
    // Session mappings
    public Session toDomain(SessionEntity entity) {
        if (entity == null) return null;
        return Session.builder()
                .id(entity.getId())
                .userId(entity.getUserId())
                .tenantId(entity.getTenantId())
                .refreshTokenHash(entity.getRefreshTokenHash())
                .ipAddress(entity.getIpAddress())
                .userAgent(entity.getUserAgent())
                .createdAt(entity.getCreatedAt())
                .expiresAt(entity.getExpiresAt())
                .revokedAt(entity.getRevokedAt())
                .build();
    }
    
    public SessionEntity toEntity(Session domain) {
        if (domain == null) return null;
        return SessionEntity.builder()
                .id(domain.getId())
                .userId(domain.getUserId())
                .tenantId(domain.getTenantId())
                .refreshTokenHash(domain.getRefreshTokenHash())
                .ipAddress(domain.getIpAddress())
                .userAgent(domain.getUserAgent())
                .createdAt(domain.getCreatedAt())
                .expiresAt(domain.getExpiresAt())
                .revokedAt(domain.getRevokedAt())
                .build();
    }
    
    // OtpCode mappings
    public OtpCode toDomain(OtpCodeEntity entity) {
        if (entity == null) return null;
        return OtpCode.builder()
                .id(entity.getId())
                .userId(entity.getUserId())
                .tenantId(entity.getTenantId())
                .codeHash(entity.getCodeHash())
                .purpose(entity.getPurpose())
                .createdAt(entity.getCreatedAt())
                .expiresAt(entity.getExpiresAt())
                .usedAt(entity.getUsedAt())
                .attempts(entity.getAttempts())
                .build();
    }
    
    public OtpCodeEntity toEntity(OtpCode domain) {
        if (domain == null) return null;
        return OtpCodeEntity.builder()
                .id(domain.getId())
                .userId(domain.getUserId())
                .tenantId(domain.getTenantId())
                .codeHash(domain.getCodeHash())
                .purpose(domain.getPurpose())
                .createdAt(domain.getCreatedAt())
                .expiresAt(domain.getExpiresAt())
                .usedAt(domain.getUsedAt())
                .attempts(domain.getAttempts())
                .build();
    }
    
    // LoginAttempt mappings
    public LoginAttempt toDomain(LoginAttemptEntity entity) {
        if (entity == null) return null;
        return LoginAttempt.builder()
                .id(entity.getId())
                .userId(entity.getUserId())
                .tenantId(entity.getTenantId())
                .username(entity.getUsername())
                .success(entity.getSuccess())
                .stage(entity.getStage())
                .ipAddress(entity.getIpAddress())
                .attemptedAt(entity.getAttemptedAt())
                .build();
    }
    
    public LoginAttemptEntity toEntity(LoginAttempt domain) {
        if (domain == null) return null;
        return LoginAttemptEntity.builder()
                .id(domain.getId())
                .userId(domain.getUserId())
                .tenantId(domain.getTenantId())
                .username(domain.getUsername())
                .success(domain.getSuccess())
                .stage(domain.getStage())
                .ipAddress(domain.getIpAddress())
                .attemptedAt(domain.getAttemptedAt())
                .build();
    }
    
    // PasswordReset mappings
    public PasswordReset toDomain(PasswordResetEntity entity) {
        if (entity == null) return null;
        return PasswordReset.builder()
            .id(entity.getId())
            .userId(entity.getUserId())
            .tenantId(entity.getTenantId())
            .tokenHash(entity.getTokenHash())
            .ipAddress(entity.getIpAddress())
            .createdAt(entity.getCreatedAt())
            .expiresAt(entity.getExpiresAt())
            .usedAt(entity.getUsedAt())
            .build();
    }
    
    public PasswordResetEntity toEntity(PasswordReset domain) {
        if (domain == null) return null;
        return PasswordResetEntity.builder()
            .id(domain.getId())
            .userId(domain.getUserId())
            .tenantId(domain.getTenantId())
            .tokenHash(domain.getTokenHash())
            .ipAddress(domain.getIpAddress())
            .createdAt(domain.getCreatedAt())
            .expiresAt(domain.getExpiresAt())
            .usedAt(domain.getUsedAt())
            .build();
    }
    
    // User mappings
    public User toDomain(UserEntity entity) {
        if (entity == null) return null;
        return User.builder()
                .id(entity.getId())
                .tenantId(entity.getTenantId())
                .username(entity.getUsername())
                .email(entity.getEmail())
                .passwordHash(entity.getPasswordHash())
                .active(entity.getActive())
                .suspended(entity.getSuspended())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }
    
    public UserEntity toEntity(User domain) {
        if (domain == null) return null;
        return UserEntity.builder()
                .id(domain.getId())
                .tenantId(domain.getTenantId())
                .username(domain.getUsername())
                .email(domain.getEmail())
                .passwordHash(domain.getPasswordHash())
                .active(domain.getActive())
                .suspended(domain.getSuspended())
                .createdAt(domain.getCreatedAt())
                .updatedAt(domain.getUpdatedAt())
                .build();
    }
    
    // Tenant mappings
    public Tenant toDomain(TenantEntity entity) {
        if (entity == null) return null;
        return Tenant.builder()
                .id(entity.getId())
                .name(entity.getName())
                .active(entity.getActive())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }
}
