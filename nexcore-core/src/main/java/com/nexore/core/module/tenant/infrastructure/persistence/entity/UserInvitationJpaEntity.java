package com.nexore.core.module.tenant.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Entity(name = "UserInvitation")
@Table(name = "user_invitations", schema = "nxc_tenant")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserInvitationJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(nullable = false, length = 200)
    private String email;

    @Column(name = "token_hash", nullable = false, unique = true, length = 255)
    private String tokenHash;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "role_ids", columnDefinition = "uuid[]")
    private List<UUID> roleIds;

    @Column(name = "invited_by", nullable = false)
    private UUID invitedBy;

    @Column(name = "invited_at", nullable = false)
    private OffsetDateTime invitedAt;

    @Column(name = "expires_at", nullable = false)
    private OffsetDateTime expiresAt;

    @Column(name = "accepted_at")
    private OffsetDateTime acceptedAt;

    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "is_revoked", nullable = false)
    private boolean isRevoked;

    @PrePersist
    void prePersist() {
        if (invitedAt == null) invitedAt = OffsetDateTime.now();
    }
}
