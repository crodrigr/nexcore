package com.nexore.core.module.tenant.application.dto.request;

import jakarta.validation.constraints.*;
import lombok.Data;

import java.util.List;
import java.util.UUID;

@Data
public class UserCreateRequest {

    @NotBlank
    @Email
    @Size(max = 200)
    private String email;

    @NotBlank
    @Pattern(regexp = "^[a-zA-Z0-9._-]{3,100}$",
             message = "Solo letras, números, puntos, guiones y guiones bajos. Entre 3 y 100 caracteres.")
    private String username;

    @Size(max = 200)
    private String fullName;

    @Size(max = 30)
    private String phone;

    private List<UUID> roleIds;

    private boolean sendInvite = true;
}
