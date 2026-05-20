package com.nexore.core.module.tenant.infrastructure.persistence.entity;

import com.nexore.core.module.tenant.domain.model.TenantMode;
import com.nexore.core.module.tenant.domain.model.TenantPlan;
import com.nexore.core.module.tenant.domain.model.TenantStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcType;
import org.hibernate.dialect.type.PostgreSQLEnumJdbcType;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity(name = "Tenant")
@Table(name = "tenants", schema = "nxc_tenant")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TenantJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(nullable = false, length = 100, updatable = false)
    private String slug;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(name = "legal_name", length = 300)
    private String legalName;

    @Column(name = "tax_id", length = 50)
    private String taxId;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(nullable = false, columnDefinition = "nxc_tenant.tenant_plan")
    private TenantPlan plan;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(nullable = false, columnDefinition = "nxc_tenant.tenant_mode")
    private TenantMode mode;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(nullable = false, columnDefinition = "nxc_tenant.tenant_status")
    private TenantStatus status;

    @Column(name = "logo_url", length = 500)
    private String logoUrl;

    @Column(name = "primary_color", length = 7)
    private String primaryColor;

    @Column(name = "custom_domain", length = 255)
    private String customDomain;

    @Column(nullable = false, length = 50)
    private String timezone;

    @Column(nullable = false, length = 10)
    private String locale;

    @Column(name = "date_format", nullable = false, length = 30)
    private String dateFormat;

    @Column(nullable = false, length = 3)
    private String currency;

    @Column(name = "mfa_required", nullable = false)
    private boolean mfaRequired;

    @Column(name = "session_timeout_minutes", nullable = false)
    private int sessionTimeoutMinutes;

    @Column(name = "max_login_attempts", nullable = false)
    private int maxLoginAttempts;

    @Column(name = "password_min_length", nullable = false)
    private int passwordMinLength;

    @Column(name = "password_requires_upper", nullable = false)
    private boolean passwordRequiresUpper;

    @Column(name = "password_requires_special", nullable = false)
    private boolean passwordRequiresSpecial;

    @Column(name = "password_expiry_days")
    private Integer passwordExpiryDays;

    @Column(name = "max_users")
    private Integer maxUsers;

    @Column(name = "audit_retention_days", nullable = false)
    private int auditRetentionDays;

    @Column(name = "trial_ends_at")
    private OffsetDateTime trialEndsAt;

    @Column(name = "subscription_ends_at")
    private OffsetDateTime subscriptionEndsAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

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
        if (plan == null) plan = TenantPlan.FREE;
        if (mode == null) mode = TenantMode.SAAS_SHARED;
        if (status == null) status = TenantStatus.TRIAL;
        if (timezone == null) timezone = "UTC";
        if (locale == null) locale = "es-CO";
        if (dateFormat == null) dateFormat = "DD/MM/YYYY";
        if (currency == null) currency = "COP";
        if (sessionTimeoutMinutes == 0) sessionTimeoutMinutes = 480;
        if (maxLoginAttempts == 0) maxLoginAttempts = 5;
        if (passwordMinLength == 0) passwordMinLength = 8;
        if (auditRetentionDays == 0) auditRetentionDays = 90;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
