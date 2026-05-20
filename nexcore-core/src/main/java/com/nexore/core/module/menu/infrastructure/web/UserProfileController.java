package com.nexore.core.module.menu.infrastructure.web;

import com.nexore.core.module.menu.application.dto.response.UserProfileResponse;
import com.nexore.core.module.menu.application.service.UserProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * GET /api/v1/me/profile — returns the full UI profile for the authenticated user.
 *
 * Auth headers (MVP phase, replaced by JWT when module-auth is implemented):
 *   X-Tenant-Id : UUID of the caller's tenant
 *   X-Actor-Id  : UUID of the caller (user)
 */
@RestController
@RequestMapping("/api/v1/me")
@RequiredArgsConstructor
public class UserProfileController {

    private final UserProfileService userProfileService;

    @GetMapping("/profile")
    public ResponseEntity<UserProfileResponse> getProfile(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId) {
        return ResponseEntity.ok(userProfileService.getProfile(actorId, tenantId));
    }
}
