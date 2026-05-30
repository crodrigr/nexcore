package com.nexore.core.module.tenant.infrastructure.persistence.jpa;

import com.nexore.core.module.tenant.infrastructure.persistence.entity.RoleApiPolicyJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface SpringDataRoleApiPolicyRepository extends JpaRepository<RoleApiPolicyJpaEntity, UUID> {

    List<RoleApiPolicyJpaEntity> findByServiceOrderByPriorityDesc(String service);
}
