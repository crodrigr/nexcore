package com.nexore.core.module.tenant.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity(name = "UserRole")
@Table(
    name = "user_roles",
    schema = "nxc_tenant",
    uniqueConstraints = @UniqueConstraint(columnNames = {"tenant_id", "user_id", "role_id"})
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserRoleJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "role_id", nullable = false)
    private UUID roleId;

    @Column(name = "assigned_at", nullable = false)
    private OffsetDateTime assignedAt;

    @Column(name = "assigned_by")
    private UUID assignedBy;

    @Column(name = "expires_at")
    private OffsetDateTime expiresAt;

    @PrePersist
    void prePersist() {
        if (assignedAt == null) assignedAt = OffsetDateTime.now();
    }
}
