package com.nexore.auth.infrastructure.web;

import com.nexore.auth.application.dto.request.ChangePasswordRequest;
import com.nexore.auth.application.dto.request.PasswordResetConfirmRequest;
import com.nexore.auth.application.dto.request.PasswordResetRequest;
import com.nexore.auth.application.dto.response.MessageResponse;
import com.nexore.auth.application.service.PasswordService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/auth/password")
@RequiredArgsConstructor
public class PasswordController {
    
    private final PasswordService passwordService;
    
    /**
     * POST /auth/password-reset/request
     * Solicitar reset de contraseña
     */
    @PostMapping("/reset/request")
    public ResponseEntity<MessageResponse> requestPasswordReset(@Valid @RequestBody PasswordResetRequest request) {
        log.info("Password reset requested for email: {} in tenant: {}", 
                request.getEmail(), request.getTenantId());
        
        MessageResponse response = passwordService.requestPasswordReset(request);
        return ResponseEntity.ok(response);
    }
    
    /**
     * POST /auth/password-reset/confirm
     * Confirmar reset de contraseña con token
     */
    @PostMapping("/reset/confirm")
    public ResponseEntity<MessageResponse> confirmPasswordReset(@Valid @RequestBody PasswordResetConfirmRequest request) {
        log.info("Password reset confirmation received");
        
        MessageResponse response = passwordService.confirmPasswordReset(request);
        return ResponseEntity.ok(response);
    }
    
    /**
     * PUT /auth/password
     * Cambiar contraseña (usuario autenticado)
     */
    @PutMapping
    public ResponseEntity<MessageResponse> changePassword(
            @RequestParam UUID userId,
            @Valid @RequestBody ChangePasswordRequest request) {
        log.info("Password change request for user: {}", userId);
        
        MessageResponse response = passwordService.changePassword(userId, request);
        return ResponseEntity.ok(response);
    }
}
