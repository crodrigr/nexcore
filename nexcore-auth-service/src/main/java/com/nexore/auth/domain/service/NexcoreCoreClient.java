package com.nexore.auth.domain.service;

import java.util.UUID;

public interface NexcoreCoreClient {
    
    /**
     * Obtiene el perfil del usuario desde nexcore-core
     * @param accessToken Token JWT para autenticación
     * @return Perfil del usuario como Object (puede ser un Map o DTO específico)
     */
    Object getUserProfile(String accessToken);
}
