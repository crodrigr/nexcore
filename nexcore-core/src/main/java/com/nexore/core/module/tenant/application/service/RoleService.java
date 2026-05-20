package com.nexore.core.module.tenant.application.service;

import com.nexore.core.module.tenant.application.dto.request.RoleCreateRequest;
import com.nexore.core.module.tenant.application.dto.request.TenantUpdateRequest;
import com.nexore.core.module.tenant.application.dto.response.RoleResponse;
import com.nexore.core.module.tenant.application.exception.BusinessException;
import com.nexore.core.module.tenant.application.mapper.RoleMapper;
import com.nexore.core.module.tenant.domain.model.Role;
import com.nexore.core.module.tenant.domain.repository.RoleRepository;
import com.nexore.core.module.tenant.domain.repository.UserRoleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RoleService {

    private static final Set<String> SYSTEM_ROLE_NAMES = Set.of("TENANT_ADMIN", "EDITOR", "VIEWER");

    private final RoleRepository roleRepository;
    private final UserRoleRepository userRoleRepository;
    private final RoleMapper roleMapper;

    /** UC-014 — Create custom role */
    @Transactional
    public RoleResponse createRole(UUID tenantId, RoleCreateRequest request, UUID actorId) {
        if (SYSTEM_ROLE_NAMES.contains(request.getName().toUpperCase())) {
            throw BusinessException.roleNameReserved(request.getName());
        }
        if (roleRepository.existsByTenantIdAndNameAndDeletedAtIsNull(tenantId, request.getName())) {
            throw BusinessException.roleNameDuplicated(request.getName());
        }

        if (request.isDefault()) {
            clearCurrentDefault(tenantId, actorId);
        }

        Role role = Role.builder()
                .tenantId(tenantId)
                .name(request.getName())
                .description(request.getDescription())
                .isSystemRole(false)
                .isDefault(request.isDefault())
                .createdBy(actorId)
                .build();

        Role saved = roleRepository.save(role);
        long userCount = roleRepository.countActiveUsersWithRole(tenantId, saved.getId());
        return roleMapper.toResponse(saved, userCount);
    }

    /** UC-015 — Update role */
    @Transactional
    public RoleResponse updateRole(UUID tenantId, UUID roleId, RoleCreateRequest request, UUID actorId) {
        Role role = roleRepository.findByTenantIdAndId(tenantId, roleId)
                .filter(r -> r.getDeletedAt() == null)
                .orElseThrow(BusinessException::roleNotFound);

        if (role.isSystemRole() && request.getName() != null
                && !request.getName().equals(role.getName())) {
            throw BusinessException.cannotRenameSystemRole();
        }

        if (request.getName() != null && !request.getName().equals(role.getName())) {
            if (SYSTEM_ROLE_NAMES.contains(request.getName().toUpperCase())) {
                throw BusinessException.roleNameReserved(request.getName());
            }
            if (roleRepository.existsByTenantIdAndNameAndDeletedAtIsNull(tenantId, request.getName())) {
                throw BusinessException.roleNameDuplicated(request.getName());
            }
            role.setName(request.getName());
        }
        if (request.getDescription() != null) role.setDescription(request.getDescription());

        if (request.isDefault() && !role.isDefault()) {
            clearCurrentDefault(tenantId, actorId);
            role.setDefault(true);
        }

        role.setUpdatedBy(actorId);
        Role saved = roleRepository.save(role);
        long userCount = roleRepository.countActiveUsersWithRole(tenantId, saved.getId());
        return roleMapper.toResponse(saved, userCount);
    }

    /** UC-016 — Delete role */
    @Transactional
    public void deleteRole(UUID tenantId, UUID roleId) {
        Role role = roleRepository.findByTenantIdAndId(tenantId, roleId)
                .filter(r -> r.getDeletedAt() == null)
                .orElseThrow(BusinessException::roleNotFound);

        if (role.isSystemRole()) {
            throw BusinessException.cannotDeleteSystemRole();
        }

        long activeUsers = roleRepository.countActiveUsersWithRole(tenantId, roleId);
        if (activeUsers > 0) {
            throw BusinessException.roleHasActiveUsers(activeUsers);
        }

        role.setDeletedAt(OffsetDateTime.now());
        roleRepository.save(role);
        // TODO: publish RoleDeletedEvent
    }

    /** Get single role */
    @Transactional(readOnly = true)
    public RoleResponse getRole(UUID tenantId, UUID roleId) {
        Role role = roleRepository.findByTenantIdAndId(tenantId, roleId)
                .filter(r -> r.getDeletedAt() == null)
                .orElseThrow(BusinessException::roleNotFound);
        long userCount = roleRepository.countActiveUsersWithRole(tenantId, roleId);
        return roleMapper.toResponse(role, userCount);
    }

    /** List roles of tenant */
    @Transactional(readOnly = true)
    public List<RoleResponse> listRoles(UUID tenantId) {
        return roleRepository.findAllByTenantId(tenantId).stream()
                .filter(r -> r.getDeletedAt() == null)
                .map(r -> roleMapper.toResponse(r, roleRepository.countActiveUsersWithRole(tenantId, r.getId())))
                .toList();
    }

    private void clearCurrentDefault(UUID tenantId, UUID actorId) {
        roleRepository.findAllByTenantId(tenantId).stream()
                .filter(Role::isDefault)
                .forEach(r -> {
                    r.setDefault(false);
                    r.setUpdatedBy(actorId);
                    roleRepository.save(r);
                });
    }
}
