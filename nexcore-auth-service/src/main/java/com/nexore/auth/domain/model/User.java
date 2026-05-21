package com.nexore.auth.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class User {
    
    private UUID id;
    private UUID tenantId;
    private String username;
    private String email;
    private String passwordHash;
    private Boolean active;
    private Boolean suspended;
    private Instant createdAt;
    private Instant updatedAt;
}
