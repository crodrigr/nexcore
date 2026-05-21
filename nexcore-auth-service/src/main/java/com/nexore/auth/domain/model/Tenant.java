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
public class Tenant {
    
    private UUID id;
    private String name;
    private Boolean active;
    private Instant createdAt;
    private Instant updatedAt;
}
