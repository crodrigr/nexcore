package com.nexore.auth.infrastructure.persistence.jpa;

import com.nexore.auth.infrastructure.persistence.entity.PasswordResetEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PasswordResetJpaRepository extends JpaRepository<PasswordResetEntity, UUID> {
    
    Optional<PasswordResetEntity> findByTokenHash(String tokenHash);
    
    @Modifying
    @Query("UPDATE PasswordResetEntity p SET p.usedAt = :now WHERE p.userId = :userId AND p.usedAt IS NULL")
    void invalidateAllByUserId(@Param("userId") UUID userId, @Param("now") Instant now);
    
    @Query("SELECT COUNT(p) FROM PasswordResetEntity p WHERE p.userId = :userId AND p.createdAt >= :since")
    long countResetRequestsByUserSinceLastHour(@Param("userId") UUID userId, @Param("since") Instant since);
}
