package com.nexore.core.module.tenant.application.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import lombok.Data;

import java.util.List;
import java.util.UUID;

@Data
public class UserInviteRequest {

    @NotBlank
    @Email
    private String email;

    @NotEmpty
    private List<UUID> roleIds;
}
