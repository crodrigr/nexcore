package com.nexore.auth.infrastructure.persistence.jpa;

import com.nexore.auth.infrastructure.persistence.entity.RoleApiPolicyEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RoleApiPolicyJpaRepository extends JpaRepository<RoleApiPolicyEntity, UUID> {

    List<RoleApiPolicyEntity> findByServiceOrderByPriorityDesc(String service);
}
