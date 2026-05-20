package com.nexore.core.module.tenant.application.dto.request;

import com.nexore.core.module.tenant.domain.model.TenantMode;
import com.nexore.core.module.tenant.domain.model.TenantPlan;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class TenantCreateRequest {

    @NotBlank
    @Size(max = 100)
    @Pattern(regexp = "^[a-z0-9]+(-[a-z0-9]+)*$",
             message = "Solo letras minúsculas, números y guiones. No puede empezar ni terminar con guión.")
    private String slug;

    @NotBlank
    @Size(min = 2, max = 200)
    private String name;

    @Size(max = 300)
    private String legalName;

    @Size(max = 50)
    private String taxId;

    private TenantPlan plan;

    private TenantMode mode;

    @Size(max = 50)
    private String timezone;

    @Size(max = 10)
    private String locale;

    @Size(max = 30)
    private String dateFormat;

    @Size(max = 3)
    private String currency;
}
