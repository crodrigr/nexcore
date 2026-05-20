package com.nexore.core.module.menu.application.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class ElementPermissionResponse {

    @JsonProperty("element_key")
    private final String elementKey;

    private final String access;
}
