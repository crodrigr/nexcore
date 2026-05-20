package com.nexore.core.module.tenant.application.dto.response;

import com.nexore.core.module.tenant.domain.model.TenantMode;
import com.nexore.core.module.tenant.domain.model.TenantPlan;
import com.nexore.core.module.tenant.domain.model.TenantStatus;
import lombok.Builder;
import lombok.Data;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
public class TenantResponse {
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
}
