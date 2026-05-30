package com.nexore.core.module.tenant.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity(name = "RoleApiPolicy")
@Table(name = "role_api_policies", schema = "nxc_tenant")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoleApiPolicyJpaEntity {

    @Id
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(name = "role_name", nullable = false, length = 100)
    private String roleName;

    @Column(name = "http_method", nullable = false, length = 10)
    private String httpMethod;

    @Column(name = "path_pattern", nullable = false, length = 500)
    private String pathPattern;

    @Column(nullable = false, length = 5)
    private String effect;

    @Column(nullable = false, length = 20)
    private String service;

    @Column(nullable = false, length = 50)
    private String module;

    @Column(nullable = false)
    private int priority;

    @Column(length = 500)
    private String description;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @Column(name = "created_by")
    private UUID createdBy;
}
