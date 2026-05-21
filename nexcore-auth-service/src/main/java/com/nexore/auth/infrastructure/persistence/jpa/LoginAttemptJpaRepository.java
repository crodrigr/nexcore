package com.nexore.auth.infrastructure.persistence.jpa;

import com.nexore.auth.infrastructure.persistence.entity.LoginAttemptEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.UUID;

@Repository
public interface LoginAttemptJpaRepository extends JpaRepository<LoginAttemptEntity, UUID> {
    
    @Query("SELECT COUNT(l) FROM LoginAttemptEntity l WHERE l.userId = :userId " +
           "AND l.success = false AND l.attemptedAt >= :since")
    long countFailedAttemptsSince(@Param("userId") UUID userId, @Param("since") Instant since);
    
    @Query("SELECT COUNT(l) FROM LoginAttemptEntity l WHERE l.ipAddress = :ipAddress " +
           "AND l.success = false AND l.attemptedAt >= :since")
    long countFailedAttemptsByIpSince(@Param("ipAddress") String ipAddress, @Param("since") Instant since);
}
