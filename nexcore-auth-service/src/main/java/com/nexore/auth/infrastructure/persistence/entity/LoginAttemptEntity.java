package com.nexore.auth.infrastructure.persistence.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "login_attempts", schema = "nxc_auth")
public class LoginAttemptEntity {
    
    @Id
    private UUID id;
    
    @Column(name = "user_id")
    private UUID userId;
    
    @Column(name = "tenant_id")
    private UUID tenantId;
    
    @Column(name = "username_tried", length = 100)
    private String username;
    
    @Column(name = "success", nullable = false)
    private Boolean success;
    
    @Column(name = "stage", nullable = false, length = 20)
    private String stage;
    
    @Column(name = "ip_address", nullable = false, length = 45)
    private String ipAddress;
    
    @Column(name = "attempted_at", nullable = false)
    private Instant attemptedAt;
}
