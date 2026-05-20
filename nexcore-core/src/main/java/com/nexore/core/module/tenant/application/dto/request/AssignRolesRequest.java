package com.nexore.core.module.tenant.application.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import lombok.Data;

import java.util.List;

@Data
public class AssignRolesRequest {

    @NotEmpty
    @Valid
    private List<RoleAssignment> roles;
}
