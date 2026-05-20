package com.nexore.core.module.tenant.domain.model;

import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Tenant {

    private UUID id;
    private String slug;
    private String name;
    private String legalName;
    private String taxId;
    private TenantPlan plan;
    private TenantMode mode;
    private TenantStatus status;
    private String logoUrl;
    private String primaryColor;
    private String customDomain;
    private String timezone;
    private String locale;
    private String dateFormat;
    private String currency;
    private boolean mfaRequired;
    private int sessionTimeoutMinutes;
    private int maxLoginAttempts;
    private int passwordMinLength;
    private boolean passwordRequiresUpper;
    private boolean passwordRequiresSpecial;
    private Integer passwordExpiryDays;
    private Integer maxUsers;
    private int auditRetentionDays;
    private OffsetDateTime trialEndsAt;
    private OffsetDateTime subscriptionEndsAt;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;
    private OffsetDateTime deletedAt;
    private int version;
}
