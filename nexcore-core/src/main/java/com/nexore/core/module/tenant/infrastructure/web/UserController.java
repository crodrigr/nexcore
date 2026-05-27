package com.nexore.core.module.tenant.infrastructure.web;

import com.nexore.core.module.tenant.application.dto.request.*;
import com.nexore.core.module.tenant.application.dto.response.*;
import com.nexore.core.module.tenant.application.service.UserService;
import com.nexore.core.module.tenant.domain.model.UserStatus;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;
import java.util.List;
import java.util.UUID;

/**
 * Endpoints REST de usuarios.
 * X-Tenant-Id  — UUID del tenant activo (temporal; será extraído del JWT).
 * X-Actor-Id   — UUID del usuario autenticado (temporal; será extraído del JWT).
 * X-Is-Tenant-Admin — flag de privilegio (temporal).
 */
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /** GET /api/v1/users */
    @GetMapping("/users")
    public ResponseEntity<PageResponse<UserResponse>> listUsers(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestParam(required = false) UserStatus status,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "fullName") String sort,
            @RequestParam(defaultValue = "asc") String dir) {
        return ResponseEntity.ok(userService.listUsers(tenantId, status, search, page, size, sort, dir));
    }

    /** POST /api/v1/users */
    @PostMapping("/users")
    public ResponseEntity<UserResponse> createUser(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId,
            @Valid @RequestBody UserCreateRequest request) {
        UserResponse response = userService.createUser(tenantId, request, actorId);
        URI location = ServletUriComponentsBuilder.fromCurrentContextPath()
                .path("/api/v1/users/{id}").buildAndExpand(response.getId()).toUri();
        return ResponseEntity.created(location).body(response);
    }

    /** GET /api/v1/users/me */
    @GetMapping("/users/me")
    public ResponseEntity<UserResponse> getMyProfile(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId) {
        return ResponseEntity.ok(userService.getMyProfile(tenantId, actorId));
    }

    /** GET /api/v1/users/{id} */
    @GetMapping("/users/{id}")
    public ResponseEntity<UserResponse> getUser(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID id) {
        return ResponseEntity.ok(userService.getUser(tenantId, id));
    }

    /** PATCH /api/v1/users/{id} */
    @PatchMapping("/users/{id}")
    public ResponseEntity<UserResponse> updateUser(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId,
            @RequestHeader(value = "X-Is-Tenant-Admin", defaultValue = "false") boolean isTenantAdmin,
            @PathVariable UUID id,
            @Valid @RequestBody UserUpdateRequest request) {
        return ResponseEntity.ok(userService.updateUser(tenantId, id, request, actorId, isTenantAdmin));
    }

    /** POST /api/v1/users/{id}/suspend */
    @PostMapping("/users/{id}/suspend")
    public ResponseEntity<Void> suspendUser(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId,
            @PathVariable UUID id) {
        userService.suspendUser(tenantId, id, actorId);
        return ResponseEntity.noContent().build();
    }

    /** POST /api/v1/users/{id}/activate */
    @PostMapping("/users/{id}/activate")
    public ResponseEntity<Void> activateUser(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId,
            @PathVariable UUID id) {
        userService.activateUser(tenantId, id, actorId);
        return ResponseEntity.noContent().build();
    }

    /** DELETE /api/v1/users/{id} */
    @DeleteMapping("/users/{id}")
    public ResponseEntity<Void> deleteUser(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId,
            @PathVariable UUID id) {
        userService.deleteUser(tenantId, id, actorId);
        return ResponseEntity.noContent().build();
    }

    /** PUT /api/v1/users/{id}/roles */
    @PutMapping("/users/{id}/roles")
    public ResponseEntity<UserResponse> assignRoles(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId,
            @PathVariable UUID id,
            @Valid @RequestBody AssignRolesRequest request) {
        return ResponseEntity.ok(userService.assignRoles(tenantId, id, request, actorId));
    }

    /** POST /api/v1/users/invite */
    @PostMapping("/users/invite")
    public ResponseEntity<UserInvitationResponse> inviteUser(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId,
            @Valid @RequestBody UserInviteRequest request) {
        UserInvitationResponse response = userService.inviteUser(tenantId, request, actorId);
        return ResponseEntity.status(201).body(response);
    }

    /** POST /api/v1/users/invitations/accept — public, no X-Tenant-Id required */
    @PostMapping("/users/invitations/accept")
    public ResponseEntity<UserResponse> acceptInvitation(
            @Valid @RequestBody AcceptInvitationRequest request) {
        return ResponseEntity.status(201).body(userService.acceptInvitation(request));
    }

    /** GET /api/v1/users/invitations */
    @GetMapping("/users/invitations")
    public ResponseEntity<List<UserInvitationResponse>> listInvitations(
            @RequestHeader("X-Tenant-Id") UUID tenantId) {
        return ResponseEntity.ok(
                userService.listInvitations(tenantId)
        );
    }

    /** POST /api/v1/users/invitations/{id}/revoke */
    @PostMapping("/users/invitations/{id}/revoke")
    public ResponseEntity<Void> revokeInvitation(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID id) {
        userService.revokeInvitation(tenantId, id);
        return ResponseEntity.noContent().build();
    }

    /** POST /api/v1/users/invitations/{id}/resend */
    @PostMapping("/users/invitations/{id}/resend")
    public ResponseEntity<UserInvitationResponse> resendInvitation(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId,
            @PathVariable UUID id) {
        return ResponseEntity.ok(userService.resendInvitation(tenantId, id, actorId));
    }
}
