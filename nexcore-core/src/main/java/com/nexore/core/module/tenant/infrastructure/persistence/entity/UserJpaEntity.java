package com.nexore.core.module.tenant.infrastructure.persistence.entity;

import com.nexore.core.module.tenant.domain.model.UserStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcType;
import org.hibernate.dialect.type.PostgreSQLEnumJdbcType;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity(name = "User")
@Table(
    name = "users",
    schema = "nxc_tenant",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"tenant_id", "email"}),
        @UniqueConstraint(columnNames = {"tenant_id", "username"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(name = "tenant_id", nullable = false, updatable = false)
    private UUID tenantId;

    @Column(nullable = false, length = 100)
    private String username;

    @Column(nullable = false, length = 200)
    private String email;

    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;

    @Column(name = "full_name", length = 200)
    private String fullName;

    @Column(length = 30)
    private String phone;

    @Column(name = "photo_url", length = 500)
    private String photoUrl;

    @Column(length = 3000)
    private String observaciones;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(nullable = false, columnDefinition = "nxc_tenant.user_status")
    private UserStatus status;

    @Column(name = "is_tenant_admin", nullable = false)
    private boolean isTenantAdmin;

    @Column(name = "email_verified", nullable = false)
    private boolean emailVerified;

    @Column(name = "email_verified_at")
    private OffsetDateTime emailVerifiedAt;

    @Column(name = "totp_secret", length = 255)
    private String totpSecret;

    @Column(name = "totp_enabled", nullable = false)
    private boolean totpEnabled;

    @Column(name = "totp_backup_codes", columnDefinition = "jsonb")
    private String totpBackupCodes;

    @Column(name = "temporal_code", length = 50)
    private String temporalCode;

    @Column(name = "temporal_code_expires_at")
    private OffsetDateTime temporalCodeExpiresAt;

    @Column(name = "invited_by")
    private UUID invitedBy;

    @Column(name = "invited_at")
    private OffsetDateTime invitedAt;

    @Column(name = "activated_at")
    private OffsetDateTime activatedAt;

    @Column(name = "last_login_at")
    private OffsetDateTime lastLoginAt;

    @Column(name = "last_login_ip", length = 45)
    private String lastLoginIp;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "updated_by")
    private UUID updatedBy;

    @Column(name = "deleted_at")
    private OffsetDateTime deletedAt;

    @Version
    @Column(nullable = false)
    private int version;

    @PrePersist
    void prePersist() {
        OffsetDateTime now = OffsetDateTime.now();
        if (createdAt == null) createdAt = now;
        updatedAt = now;
        if (status == null) status = UserStatus.PENDING_ACTIVATION;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
