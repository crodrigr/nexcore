package com.nexore.core.module.tenant.application.dto.request;

import com.nexore.core.module.tenant.domain.model.TenantMode;
import com.nexore.core.module.tenant.domain.model.TenantPlan;
import com.nexore.core.module.tenant.domain.model.TenantStatus;
import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class TenantUpdateRequest {

    @Size(min = 2, max = 200)
    private String name;

    @Size(max = 300)
    private String legalName;

    @Size(max = 50)
    private String taxId;

    @Size(max = 500)
    private String logoUrl;

    @Pattern(regexp = "^#[0-9A-Fa-f]{6}$", message = "Formato inválido. Use #RRGGBB.")
    private String primaryColor;

    @Size(max = 255)
    private String customDomain;

    @Size(max = 50)
    private String timezone;

    @Size(max = 10)
    private String locale;

    @Size(max = 30)
    private String dateFormat;

    @Size(min = 3, max = 3)
    private String currency;

    private Boolean mfaRequired;

    @Min(5) @Max(1440)
    private Integer sessionTimeoutMinutes;

    @Min(3) @Max(20)
    private Integer maxLoginAttempts;

    @Min(6) @Max(72)
    private Integer passwordMinLength;

    private Boolean passwordRequiresUpper;

    private Boolean passwordRequiresSpecial;

    @Min(30)
    private Integer passwordExpiryDays;

    // --- Solo SUPER_ADMIN ---
    private TenantPlan plan;
    private TenantMode mode;
    private TenantStatus status;
    private Integer maxUsers;
    private Integer auditRetentionDays;
    private String trialEndsAt;
    private String subscriptionEndsAt;
}
