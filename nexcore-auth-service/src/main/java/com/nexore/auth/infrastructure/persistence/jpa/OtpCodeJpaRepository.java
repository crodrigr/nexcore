package com.nexore.auth.infrastructure.persistence.jpa;

import com.nexore.auth.infrastructure.persistence.entity.OtpCodeEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OtpCodeJpaRepository extends JpaRepository<OtpCodeEntity, UUID> {
    
    @Query("SELECT o FROM OtpCodeEntity o WHERE o.userId = :userId AND o.purpose = :purpose " +
           "AND o.usedAt IS NULL AND o.expiresAt > :now ORDER BY o.createdAt DESC")
    Optional<OtpCodeEntity> findActiveOtpByUserAndPurpose(@Param("userId") UUID userId, 
                                                            @Param("purpose") String purpose,
                                                            @Param("now") Instant now);
    
    @Modifying
    @Query("UPDATE OtpCodeEntity o SET o.usedAt = :now WHERE o.userId = :userId AND o.purpose = :purpose AND o.usedAt IS NULL")
    void invalidateActiveOtpsByUserAndPurpose(@Param("userId") UUID userId, 
                                                @Param("purpose") String purpose,
                                                @Param("now") Instant now);
}
