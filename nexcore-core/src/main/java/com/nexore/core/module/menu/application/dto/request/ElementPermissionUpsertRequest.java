package com.nexore.core.module.menu.application.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class ElementPermissionUpsertRequest {

    @NotBlank
    @Pattern(regexp = "HIDDEN|VIEW|EXECUTE", message = "must be HIDDEN, VIEW or EXECUTE")
    private String access;
}
