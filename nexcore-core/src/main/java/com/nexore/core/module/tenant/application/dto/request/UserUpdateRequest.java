package com.nexore.core.module.tenant.application.dto.request;

import com.nexore.core.module.tenant.domain.model.UserStatus;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UserUpdateRequest {

    @Size(max = 200)
    private String fullName;

    @Size(max = 30)
    private String phone;

    @Size(max = 500)
    private String photoUrl;

    @Size(max = 3000)
    private String observaciones;

    // Solo TENANT_ADMIN
    private UserStatus status;
    private Boolean isTenantAdmin;
}
