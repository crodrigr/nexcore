package com.nexore.core.module.menu.infrastructure.persistence;

import com.nexore.core.module.menu.domain.model.ElementPermission;
import com.nexore.core.module.menu.domain.repository.ElementPermissionRepository;
import com.nexore.core.module.menu.infrastructure.persistence.jpa.PermissionCommandRepository;
import com.nexore.core.module.menu.infrastructure.persistence.mapper.PermissionPersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

@Repository
@RequiredArgsConstructor
public class JpaElementPermissionRepositoryAdapter implements ElementPermissionRepository {

    private final PermissionCommandRepository commandRepository;
    private final PermissionPersistenceMapper mapper;

    @Override
    public ElementPermission upsert(ElementPermission permission) {
        commandRepository.upsertElementPermission(
                permission.getTenantId(),
                permission.getRoleId(),
                permission.getElementId(),
                permission.getAccess().name(),
                permission.getCreatedBy(),
                permission.getUpdatedBy());
        return commandRepository.findElementPermission(
                        permission.getTenantId(), permission.getRoleId(), permission.getElementId())
                .map(mapper::toElementPermission)
                .orElseThrow(() -> new IllegalStateException("Upsert succeeded but row not found"));
    }
}
