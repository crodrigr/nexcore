package com.nexore.core.module.menu.domain.repository;

import com.nexore.core.module.menu.domain.model.UserProfile;

import java.util.Optional;
import java.util.UUID;

public interface UserProfileRepository {
    Optional<UserProfile> loadProfile(UUID userId, UUID tenantId);
}
