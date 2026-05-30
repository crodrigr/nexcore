package com.nexore.core.config.security;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class RoleApiPolicyDto {
    private String roleName;
    private String httpMethod;
    private String pathPattern;
    private String effect;
    private int priority;
}
