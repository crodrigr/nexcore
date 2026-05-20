package com.nexore.core.module.menu.infrastructure.persistence.projection;

import java.util.UUID;

/**
 * Maps rows from nxc_tenant.v_user_login_profile.
 * Used by UserProfileQueryRepository to load user identity and role info.
 */
public interface UserLoginProfileProjection {
    UUID getUserId();
    UUID getTenantId();
    String getUsername();
    String getEmail();
    String getFullName();
    String getPhotoUrl();
    String getStatus();
    String getTenantStatus();
    String[] getRoleNames();
    String[] getRoleIds();
}
