package com.nexore.auth.infrastructure.persistence.adapter;

import com.nexore.auth.domain.model.User;
import com.nexore.auth.domain.repository.UserRepository;
import com.nexore.auth.infrastructure.persistence.jpa.UserJpaRepository;
import com.nexore.auth.infrastructure.persistence.mapper.EntityMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class UserRepositoryAdapter implements UserRepository {
    
    private final UserJpaRepository jpaRepository;
    private final EntityMapper mapper;
    
    @Override
    public Optional<User> findByTenantIdAndUsername(UUID tenantId, String username) {
        return jpaRepository.findByTenantIdAndUsername(tenantId, username).map(mapper::toDomain);
    }
    
    @Override
    public Optional<User> findByTenantIdAndEmail(UUID tenantId, String email) {
        return jpaRepository.findByTenantIdAndEmail(tenantId, email).map(mapper::toDomain);
    }
    
    @Override
    public Optional<User> findById(UUID userId) {
        return jpaRepository.findById(userId).map(mapper::toDomain);
    }
    
    @Override
    @Transactional
    public User save(User user) {
        return mapper.toDomain(jpaRepository.save(mapper.toEntity(user)));
    }
}
