package com.nexore.auth.infrastructure.persistence.jpa;

import com.nexore.auth.infrastructure.persistence.entity.SessionEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SessionJpaRepository extends JpaRepository<SessionEntity, UUID> {
    
    Optional<SessionEntity> findByRefreshTokenHash(String refreshTokenHash);
    
    @Modifying
    @Query("UPDATE SessionEntity s SET s.revokedAt = :revokedAt WHERE s.userId = :userId AND s.revokedAt IS NULL")
    void revokeAllByUserId(@Param("userId") UUID userId, @Param("revokedAt") Instant revokedAt);
    
    @Modifying
    @Query("UPDATE SessionEntity s SET s.revokedAt = :revokedAt WHERE s.userId = :userId AND s.id != :exceptSessionId AND s.revokedAt IS NULL")
    void revokeAllByUserIdExcept(@Param("userId") UUID userId, 
                                   @Param("exceptSessionId") UUID exceptSessionId,
                                   @Param("revokedAt") Instant revokedAt);
    
    @Modifying
    @Query("UPDATE SessionEntity s SET s.revokedAt = :revokedAt WHERE s.id = :sessionId AND s.revokedAt IS NULL")
    void revokeById(@Param("sessionId") UUID sessionId, @Param("revokedAt") Instant revokedAt);
}
