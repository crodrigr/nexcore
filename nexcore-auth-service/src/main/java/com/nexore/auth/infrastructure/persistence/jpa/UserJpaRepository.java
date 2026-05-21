package com.nexore.auth.infrastructure.persistence.jpa;

import com.nexore.auth.infrastructure.persistence.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserJpaRepository extends JpaRepository<UserEntity, UUID> {
    
    Optional<UserEntity> findByTenantIdAndUsername(UUID tenantId, String username);
    
    Optional<UserEntity> findByTenantIdAndEmail(UUID tenantId, String email);
}
