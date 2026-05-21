package com.nexore.auth.infrastructure.persistence.adapter;

import com.nexore.auth.domain.model.Session;
import com.nexore.auth.domain.repository.SessionRepository;
import com.nexore.auth.infrastructure.persistence.jpa.SessionJpaRepository;
import com.nexore.auth.infrastructure.persistence.mapper.EntityMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class SessionRepositoryAdapter implements SessionRepository {
    
    private final SessionJpaRepository jpaRepository;
    private final EntityMapper mapper;
    
    @Override
    @Transactional
    public Session save(Session session) {
        return mapper.toDomain(jpaRepository.save(mapper.toEntity(session)));
    }
    
    @Override
    public Optional<Session> findById(UUID id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }
    
    @Override
    public Optional<Session> findByRefreshTokenHash(String refreshTokenHash) {
        return jpaRepository.findByRefreshTokenHash(refreshTokenHash).map(mapper::toDomain);
    }
    
    @Override
    @Transactional
    public void revokeAllByUserId(UUID userId) {
        jpaRepository.revokeAllByUserId(userId, Instant.now());
    }
    
    @Override
    @Transactional
    public void revokeAllByUserIdExcept(UUID userId, UUID exceptSessionId) {
        jpaRepository.revokeAllByUserIdExcept(userId, exceptSessionId, Instant.now());
    }
    
    @Override
    @Transactional
    public void revokeById(UUID sessionId) {
        jpaRepository.revokeById(sessionId, Instant.now());
    }
}
