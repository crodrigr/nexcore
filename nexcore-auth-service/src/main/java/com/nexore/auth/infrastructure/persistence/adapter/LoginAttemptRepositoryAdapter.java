package com.nexore.auth.infrastructure.persistence.adapter;

import com.nexore.auth.domain.model.LoginAttempt;
import com.nexore.auth.domain.repository.LoginAttemptRepository;
import com.nexore.auth.infrastructure.persistence.jpa.LoginAttemptJpaRepository;
import com.nexore.auth.infrastructure.persistence.mapper.EntityMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class LoginAttemptRepositoryAdapter implements LoginAttemptRepository {
    
    private final LoginAttemptJpaRepository jpaRepository;
    private final EntityMapper mapper;
    
    @Override
    @Transactional
    public LoginAttempt save(LoginAttempt attempt) {
        return mapper.toDomain(jpaRepository.save(mapper.toEntity(attempt)));
    }
    
    @Override
    public long countFailedAttemptsSince(UUID userId, Instant since) {
        return jpaRepository.countFailedAttemptsSince(userId, since);
    }
    
    @Override
    public long countFailedAttemptsByIpSince(String ipAddress, Instant since) {
        return jpaRepository.countFailedAttemptsByIpSince(ipAddress, since);
    }
}
