package com.nexore.auth.infrastructure.persistence.adapter;

import com.nexore.auth.domain.model.PasswordReset;
import com.nexore.auth.domain.repository.PasswordResetRepository;
import com.nexore.auth.infrastructure.persistence.jpa.PasswordResetJpaRepository;
import com.nexore.auth.infrastructure.persistence.mapper.EntityMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class PasswordResetRepositoryAdapter implements PasswordResetRepository {
    
    private final PasswordResetJpaRepository jpaRepository;
    private final EntityMapper mapper;
    
    @Override
    @Transactional
    public PasswordReset save(PasswordReset passwordReset) {
        return mapper.toDomain(jpaRepository.save(mapper.toEntity(passwordReset)));
    }
    
    @Override
    public Optional<PasswordReset> findByTokenHash(String tokenHash) {
        return jpaRepository.findByTokenHash(tokenHash).map(mapper::toDomain);
    }
    
    @Override
    @Transactional
    public void invalidateAllByUserId(UUID userId) {
        jpaRepository.invalidateAllByUserId(userId, Instant.now());
    }
    
    @Override
    public long countResetRequestsByUserSinceLastHour(UUID userId) {
        Instant oneHourAgo = Instant.now().minus(Duration.ofHours(1));
        return jpaRepository.countResetRequestsByUserSinceLastHour(userId, oneHourAgo);
    }
}
