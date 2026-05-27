package com.nexore.core.module.menu.application.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;
import java.util.UUID;

@Data
public class BatchComponentPermissionRequest {

    @NotNull
    @Size(min = 1, max = 100)
    private List<@Valid ComponentPermissionItem> permissions;

    @Data
    public static class ComponentPermissionItem {

        @NotNull
        private UUID componentId;

        @NotNull
        @Pattern(regexp = "HIDDEN|VIEW|EXECUTE", message = "must be HIDDEN, VIEW or EXECUTE")
        private String access;
    }
}
