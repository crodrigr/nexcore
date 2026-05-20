package com.nexore.core.module.tenant.application.service;

import com.nexore.core.module.tenant.application.dto.request.*;
import com.nexore.core.module.tenant.application.dto.response.*;
import com.nexore.core.module.tenant.application.exception.BusinessException;
import com.nexore.core.module.tenant.application.mapper.UserMapper;
import com.nexore.core.module.tenant.domain.model.*;
import com.nexore.core.module.tenant.domain.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.OffsetDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class UserService {

    private static final Set<String> SYSTEM_ROLE_NAMES = Set.of("TENANT_ADMIN", "EDITOR", "VIEWER");

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final UserRoleRepository userRoleRepository;
    private final UserInvitationRepository invitationRepository;
    private final TenantRepository tenantRepository;
    private final UserMapper userMapper;

    /** UC-005 — Invite user */
    @Transactional
    public UserInvitationResponse inviteUser(UUID tenantId, UserInviteRequest request, UUID actorId) {
        Tenant tenant = tenantRepository.findById(tenantId)
                .orElseThrow(BusinessException::tenantNotFound);

        if (tenant.getMaxUsers() != null) {
            long count = userRepository.countByTenantIdAndDeletedAtIsNull(tenantId);
            if (count >= tenant.getMaxUsers()) {
                throw BusinessException.userQuotaReached();
            }
        }
        if (userRepository.existsByTenantIdAndEmailAndDeletedAtIsNull(tenantId, request.getEmail())) {
            throw BusinessException.userEmailAlreadyExists(request.getEmail());
        }
        if (invitationRepository.existsPendingByTenantIdAndEmail(tenantId, request.getEmail())) {
            throw BusinessException.invitationPendingForEmail(request.getEmail());
        }
        validateRolesBelongToTenant(tenantId, request.getRoleIds());

        String rawToken = UUID.randomUUID().toString();
        UserInvitation invitation = UserInvitation.builder()
                .tenantId(tenantId)
                .email(request.getEmail())
                .tokenHash(sha256(rawToken))
                .roleIds(request.getRoleIds())
                .invitedBy(actorId)
                .expiresAt(OffsetDateTime.now().plusHours(72))
                .isRevoked(false)
                .build();

        UserInvitation saved = invitationRepository.save(invitation);
        // TODO: publish UserInvitedEvent & send email via notification service
        return toInvitationResponse(saved);
    }

    /** UC-006 — Accept invitation */
    @Transactional
    public UserResponse acceptInvitation(UUID tenantId, AcceptInvitationRequest request) {
        String tokenHash = sha256(request.getToken());
        UserInvitation invitation = invitationRepository.findByTokenHash(tokenHash)
                .orElseThrow(BusinessException::invitationInvalidOrExpired);

        if (!invitation.getTenantId().equals(tenantId)) {
            throw BusinessException.invitationInvalidOrExpired();
        }
        if (invitation.isRevoked()) {
            throw BusinessException.invitationInvalidOrExpired();
        }
        if (invitation.getAcceptedAt() != null) {
            throw BusinessException.invitationAlreadyUsed();
        }
        if (invitation.getExpiresAt().isBefore(OffsetDateTime.now())) {
            throw BusinessException.invitationInvalidOrExpired();
        }

        Tenant tenant = tenantRepository.findById(tenantId).orElseThrow(BusinessException::tenantNotFound);
        validatePasswordPolicy(request.getPassword(), tenant);

        if (userRepository.existsByTenantIdAndUsernameAndDeletedAtIsNull(tenantId, request.getUsername())) {
            throw BusinessException.usernameAlreadyExists(request.getUsername());
        }

        User user = User.builder()
                .tenantId(tenantId)
                .username(request.getUsername())
                .email(invitation.getEmail())
                .passwordHash(hashPassword(request.getPassword()))
                .fullName(request.getFullName())
                .status(UserStatus.ACTIVE)
                .emailVerified(true)
                .emailVerifiedAt(OffsetDateTime.now())
                .activatedAt(OffsetDateTime.now())
                .invitedBy(invitation.getInvitedBy())
                .invitedAt(invitation.getInvitedAt())
                .build();

        User savedUser = userRepository.save(user);

        assignRoles(tenantId, savedUser.getId(), invitation.getRoleIds(), savedUser.getId());

        invitation.setAcceptedAt(OffsetDateTime.now());
        invitation.setUserId(savedUser.getId());
        invitationRepository.save(invitation);

        return buildUserResponse(savedUser, tenantId);
    }

    /** UC-007 — Create user directly */
    @Transactional
    public UserResponse createUser(UUID tenantId, UserCreateRequest request, UUID actorId) {
        if (request.isSendInvite()) {
            UserInviteRequest invite = new UserInviteRequest();
            invite.setEmail(request.getEmail());
            invite.setRoleIds(request.getRoleIds() != null ? request.getRoleIds() : List.of());
            inviteUser(tenantId, invite, actorId);
            // Return minimal response for invite flow
            return UserResponse.builder()
                    .tenantId(tenantId)
                    .email(request.getEmail())
                    .status(UserStatus.PENDING_ACTIVATION)
                    .build();
        }

        Tenant tenant = tenantRepository.findById(tenantId).orElseThrow(BusinessException::tenantNotFound);
        if (tenant.getMaxUsers() != null) {
            if (userRepository.countByTenantIdAndDeletedAtIsNull(tenantId) >= tenant.getMaxUsers()) {
                throw BusinessException.userQuotaReached();
            }
        }
        if (userRepository.existsByTenantIdAndEmailAndDeletedAtIsNull(tenantId, request.getEmail())) {
            throw BusinessException.userEmailAlreadyExists(request.getEmail());
        }
        if (userRepository.existsByTenantIdAndUsernameAndDeletedAtIsNull(tenantId, request.getUsername())) {
            throw BusinessException.usernameAlreadyExists(request.getUsername());
        }

        String tempPassword = UUID.randomUUID().toString().substring(0, 12) + "!A1";
        User user = User.builder()
                .tenantId(tenantId)
                .username(request.getUsername())
                .email(request.getEmail())
                .passwordHash(hashPassword(tempPassword))
                .fullName(request.getFullName())
                .phone(request.getPhone())
                .status(UserStatus.PENDING_ACTIVATION)
                .createdBy(actorId)
                .build();

        User savedUser = userRepository.save(user);

        List<UUID> roleIds = request.getRoleIds();
        if (roleIds != null && !roleIds.isEmpty()) {
            validateRolesBelongToTenant(tenantId, roleIds);
            assignRoles(tenantId, savedUser.getId(), roleIds, actorId);
        }
        // TODO: publish UserCreatedEvent & send temp password email

        return buildUserResponse(savedUser, tenantId);
    }

    /** UC-008 — Get user */
    @Transactional(readOnly = true)
    public UserResponse getUser(UUID tenantId, UUID userId) {
        User user = userRepository.findByTenantIdAndId(tenantId, userId)
                .filter(u -> u.getDeletedAt() == null)
                .orElseThrow(BusinessException::userNotFound);
        return buildUserResponse(user, tenantId);
    }

    /** UC-009 — Update user */
    @Transactional
    public UserResponse updateUser(UUID tenantId, UUID userId, UserUpdateRequest request,
                                   UUID actorId, boolean isTenantAdmin) {
        User user = userRepository.findByTenantIdAndId(tenantId, userId)
                .filter(u -> u.getDeletedAt() == null)
                .orElseThrow(BusinessException::userNotFound);

        if (request.getFullName() != null) user.setFullName(request.getFullName());
        if (request.getPhone() != null) user.setPhone(request.getPhone());
        if (request.getPhotoUrl() != null) user.setPhotoUrl(request.getPhotoUrl());
        if (request.getObservaciones() != null) user.setObservaciones(request.getObservaciones());

        if (isTenantAdmin) {
            if (request.getStatus() != null) user.setStatus(request.getStatus());
            if (request.getIsTenantAdmin() != null) user.setTenantAdmin(request.getIsTenantAdmin());
        }

        user.setUpdatedBy(actorId);
        User saved = userRepository.save(user);
        return buildUserResponse(saved, tenantId);
    }

    /** UC-010 — Suspend user */
    @Transactional
    public void suspendUser(UUID tenantId, UUID userId, UUID actorId) {
        if (userId.equals(actorId)) throw BusinessException.cannotSuspendSelf();

        User user = userRepository.findByTenantIdAndId(tenantId, userId)
                .filter(u -> u.getDeletedAt() == null)
                .orElseThrow(BusinessException::userNotFound);

        if (user.isTenantAdmin() && userRepository.countActiveTenantAdmins(tenantId) <= 1) {
            throw BusinessException.cannotSuspendLastTenantAdmin();
        }

        user.setStatus(UserStatus.SUSPENDED);
        user.setUpdatedBy(actorId);
        userRepository.save(user);
        // TODO: revoke sessions, publish UserSuspendedEvent
    }

    /** UC-011 — Activate user */
    @Transactional
    public void activateUser(UUID tenantId, UUID userId, UUID actorId) {
        User user = userRepository.findByTenantIdAndId(tenantId, userId)
                .filter(u -> u.getDeletedAt() == null)
                .orElseThrow(BusinessException::userNotFound);
        user.setStatus(UserStatus.ACTIVE);
        user.setUpdatedBy(actorId);
        userRepository.save(user);
        // TODO: publish UserActivatedEvent
    }

    /** UC-012 — Soft delete user */
    @Transactional
    public void deleteUser(UUID tenantId, UUID userId, UUID actorId) {
        if (userId.equals(actorId)) throw BusinessException.cannotDeleteSelf();

        User user = userRepository.findByTenantIdAndId(tenantId, userId)
                .filter(u -> u.getDeletedAt() == null)
                .orElseThrow(BusinessException::userNotFound);

        if (user.isTenantAdmin() && userRepository.countActiveTenantAdmins(tenantId) <= 1) {
            throw BusinessException.cannotDeleteLastTenantAdmin();
        }

        user.setStatus(UserStatus.DELETED);
        user.setDeletedAt(OffsetDateTime.now());
        user.setUpdatedBy(actorId);
        userRepository.save(user);
        // TODO: revoke sessions, publish UserDeletedEvent
    }

    /** UC-013 — List users */
    @Transactional(readOnly = true)
    public PageResponse<UserResponse> listUsers(UUID tenantId, UserStatus status,
                                                 String search, int page, int size) {
        List<User> users = userRepository.findByTenantId(tenantId, status, search, page, size);
        long total = userRepository.countByTenantId(tenantId, status, search);
        List<UserResponse> content = users.stream()
                .map(u -> buildUserResponse(u, tenantId))
                .toList();
        int totalPages = (int) Math.ceil((double) total / size);
        return PageResponse.<UserResponse>builder()
                .content(content)
                .page(page)
                .size(size)
                .totalElements(total)
                .totalPages(totalPages)
                .last(page >= totalPages - 1)
                .build();
    }

    /** UC-017 — Assign roles */
    @Transactional
    public UserResponse assignRoles(UUID tenantId, UUID userId, AssignRolesRequest request, UUID actorId) {
        User user = userRepository.findByTenantIdAndId(tenantId, userId)
                .filter(u -> u.getDeletedAt() == null)
                .orElseThrow(BusinessException::userNotFound);

        List<UUID> newRoleIds = request.getRoles().stream()
                .map(ra -> ra.getRoleId())
                .toList();

        validateRolesBelongToTenant(tenantId, newRoleIds);

        // Check if removing TENANT_ADMIN from this user would leave tenant with zero admins
        Role tenantAdminRole = roleRepository.findByTenantIdAndName(tenantId, "TENANT_ADMIN").orElse(null);
        if (tenantAdminRole != null) {
            boolean hadAdminRole = userRoleRepository.findByTenantIdAndUserId(tenantId, userId).stream()
                    .anyMatch(ur -> ur.getRoleId().equals(tenantAdminRole.getId()));
            boolean willHaveAdminRole = newRoleIds.contains(tenantAdminRole.getId());
            if (hadAdminRole && !willHaveAdminRole && userRepository.countActiveTenantAdmins(tenantId) <= 1) {
                throw BusinessException.assignmentWouldRemoveLastTenantAdmin();
            }
        }

        userRoleRepository.deleteByTenantIdAndUserId(tenantId, userId);

        for (RoleAssignment ra : request.getRoles()) {
            UserRole ur = UserRole.builder()
                    .tenantId(tenantId)
                    .userId(userId)
                    .roleId(ra.getRoleId())
                    .assignedBy(actorId)
                    .expiresAt(ra.getExpiresAt())
                    .build();
            userRoleRepository.save(ur);
        }
        // TODO: publish UserRolesChangedEvent

        return buildUserResponse(user, tenantId);
    }

    /** UC-018 — Revoke invitation */
    @Transactional
    public void revokeInvitation(UUID tenantId, UUID invitationId) {
        UserInvitation inv = invitationRepository.findByTenantIdAndId(tenantId, invitationId)
                .orElseThrow(BusinessException::invitationInvalidOrExpired);
        if (inv.getAcceptedAt() != null) {
            throw BusinessException.invitationAlreadyAccepted();
        }
        inv.setRevoked(true);
        invitationRepository.save(inv);
    }

    /** UC-019 — Resend invitation */
    @Transactional
    public UserInvitationResponse resendInvitation(UUID tenantId, UUID invitationId, UUID actorId) {
        UserInvitation old = invitationRepository.findByTenantIdAndId(tenantId, invitationId)
                .orElseThrow(BusinessException::invitationInvalidOrExpired);
        if (old.getAcceptedAt() != null) {
            throw BusinessException.invitationAlreadyAccepted();
        }
        old.setRevoked(true);
        invitationRepository.save(old);

        String rawToken = UUID.randomUUID().toString();
        UserInvitation newInv = UserInvitation.builder()
                .tenantId(tenantId)
                .email(old.getEmail())
                .tokenHash(sha256(rawToken))
                .roleIds(old.getRoleIds())
                .invitedBy(actorId)
                .expiresAt(OffsetDateTime.now().plusHours(72))
                .isRevoked(false)
                .build();

        UserInvitation saved = invitationRepository.save(newInv);
        // TODO: send email, publish UserInvitedEvent
        return toInvitationResponse(saved);
    }

    /** UC-020 — Get own profile */
    @Transactional(readOnly = true)
    public UserResponse getMyProfile(UUID tenantId, UUID userId) {
        return getUser(tenantId, userId);
    }

    /** List invitations of tenant */
    @Transactional(readOnly = true)
    public List<UserInvitationResponse> listInvitations(UUID tenantId) {
        return invitationRepository.findByTenantId(tenantId).stream()
                .map(this::toInvitationResponse)
                .toList();
    }

    // ---------- private helpers ----------

    private void validateRolesBelongToTenant(UUID tenantId, List<UUID> roleIds) {
        if (roleIds == null || roleIds.isEmpty()) return;
        for (UUID roleId : roleIds) {
            roleRepository.findByTenantIdAndId(tenantId, roleId)
                    .orElseThrow(BusinessException::roleDoesNotBelongToTenant);
        }
    }

    private void assignRoles(UUID tenantId, UUID userId, List<UUID> roleIds, UUID actorId) {
        for (UUID roleId : roleIds) {
            UserRole ur = UserRole.builder()
                    .tenantId(tenantId)
                    .userId(userId)
                    .roleId(roleId)
                    .assignedBy(actorId)
                    .build();
            userRoleRepository.save(ur);
        }
    }

    private UserResponse buildUserResponse(User user, UUID tenantId) {
        List<UserRole> userRoles = userRoleRepository.findByTenantIdAndUserId(tenantId, user.getId());
        List<RoleSummary> roleSummaries = userRoles.stream()
                .map(ur -> {
                    Role role = roleRepository.findById(ur.getRoleId()).orElse(null);
                    return RoleSummary.builder()
                            .id(ur.getRoleId())
                            .name(role != null ? role.getName() : null)
                            .assignedAt(ur.getAssignedAt())
                            .expiresAt(ur.getExpiresAt())
                            .build();
                })
                .toList();
        return userMapper.toResponse(user, roleSummaries);
    }

    private void validatePasswordPolicy(String password, Tenant tenant) {
        if (password.length() < tenant.getPasswordMinLength()) {
            throw BusinessException.passwordPolicyViolation(
                    "La contraseña debe tener al menos " + tenant.getPasswordMinLength() + " caracteres.");
        }
        if (tenant.isPasswordRequiresUpper() && password.chars().noneMatch(Character::isUpperCase)) {
            throw BusinessException.passwordPolicyViolation("La contraseña debe contener al menos una mayúscula.");
        }
        if (tenant.isPasswordRequiresSpecial() && password.chars().noneMatch(c -> "!@#$%^&*()_+-=[]{}|;':\",./<>?".indexOf(c) >= 0)) {
            throw BusinessException.passwordPolicyViolation("La contraseña debe contener al menos un carácter especial.");
        }
    }

    private String hashPassword(String password) {
        // Placeholder: in production use BCryptPasswordEncoder injected as a bean
        return "$2a$12$placeholder_hash_for_" + password.hashCode();
    }

    private String sha256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder();
            for (byte b : hash) hex.append(String.format("%02x", b));
            return hex.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 no disponible", e);
        }
    }

    private UserInvitationResponse toInvitationResponse(UserInvitation inv) {
        return UserInvitationResponse.builder()
                .id(inv.getId())
                .tenantId(inv.getTenantId())
                .email(inv.getEmail())
                .roleIds(inv.getRoleIds())
                .invitedAt(inv.getInvitedAt())
                .expiresAt(inv.getExpiresAt())
                .revoked(inv.isRevoked())
                .acceptedAt(inv.getAcceptedAt())
                .build();
    }
}
