package com.nexore.auth.infrastructure.persistence.adapter;

import com.nexore.auth.domain.model.OtpCode;
import com.nexore.auth.domain.repository.OtpCodeRepository;
import com.nexore.auth.infrastructure.persistence.jpa.OtpCodeJpaRepository;
import com.nexore.auth.infrastructure.persistence.mapper.EntityMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class OtpCodeRepositoryAdapter implements OtpCodeRepository {
    
    private final OtpCodeJpaRepository jpaRepository;
    private final EntityMapper mapper;
    
    @Override
    @Transactional
    public OtpCode save(OtpCode otpCode) {
        return mapper.toDomain(jpaRepository.save(mapper.toEntity(otpCode)));
    }
    
    @Override
    public Optional<OtpCode> findById(UUID id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }
    
    @Override
    public Optional<OtpCode> findActiveOtpByUserAndPurpose(UUID userId, String purpose) {
        return jpaRepository.findActiveOtpByUserAndPurpose(userId, purpose, Instant.now())
                .map(mapper::toDomain);
    }
    
    @Override
    @Transactional
    public void invalidateActiveOtpsByUserAndPurpose(UUID userId, String purpose) {
        jpaRepository.invalidateActiveOtpsByUserAndPurpose(userId, purpose, Instant.now());
    }
}
