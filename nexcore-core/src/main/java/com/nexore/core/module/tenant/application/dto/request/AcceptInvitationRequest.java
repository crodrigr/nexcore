package com.nexore.core.module.tenant.application.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class AcceptInvitationRequest {

    @NotBlank
    private String token;

    @NotBlank
    @Pattern(regexp = "^[a-zA-Z0-9._-]{3,100}$",
             message = "Solo letras, números, puntos, guiones y guiones bajos. Entre 3 y 100 caracteres.")
    private String username;

    @NotBlank
    @Size(min = 2, max = 200)
    private String fullName;

    @NotBlank
    private String password;
}
