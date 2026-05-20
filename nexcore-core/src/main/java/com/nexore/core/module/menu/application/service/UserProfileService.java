package com.nexore.core.module.menu.application.service;

import com.nexore.core.module.menu.application.dto.response.UserProfileResponse;
import com.nexore.core.module.menu.application.mapper.UserProfileMapper;
import com.nexore.core.module.menu.domain.model.UserProfile;
import com.nexore.core.module.menu.domain.repository.UserProfileRepository;
import com.nexore.core.module.tenant.application.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserProfileService {

    private final UserProfileRepository userProfileRepository;
    private final UserProfileMapper userProfileMapper;

    /** UC-MNU-001 */
    @Transactional(readOnly = true)
    public UserProfileResponse getProfile(UUID userId, UUID tenantId) {
        UserProfile profile = userProfileRepository.loadProfile(userId, tenantId)
                .orElseThrow(BusinessException::menuUserNotFound);
        return userProfileMapper.toResponse(profile);
    }
}
