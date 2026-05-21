package com.nexore.auth.infrastructure.web;

import com.nexore.auth.application.dto.request.LoginRequest;
import com.nexore.auth.application.dto.request.VerifyOtpRequest;
import com.nexore.auth.application.dto.response.ChallengeResponse;
import com.nexore.auth.application.dto.response.MessageResponse;
import com.nexore.auth.application.dto.response.SessionResponse;
import com.nexore.auth.application.service.AuthService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {
    
    private final AuthService authService;
    
    /**
     * POST /auth/login
     * Paso 1: Validar credenciales y enviar OTP
     */
    @PostMapping("/login")
    public ResponseEntity<ChallengeResponse> login(@Valid @RequestBody LoginRequest request) {
        log.info("Login request received for username: {} in tenant: {}", 
                request.getUsername(), request.getTenantId());
        
        ChallengeResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }
    
    /**
     * POST /auth/verify-otp
     * Paso 2: Verificar OTP y crear sesión
     */
    @PostMapping("/verify-otp")
    public ResponseEntity<SessionResponse> verifyOtp(@Valid @RequestBody VerifyOtpRequest request) {
        log.info("OTP verification request received");
        
        SessionResponse response = authService.verifyOtp(request);
        return ResponseEntity.ok(response);
    }
    
    /**
     * POST /auth/refresh
     * Refrescar access token
     */
    @PostMapping("/refresh")
    public ResponseEntity<SessionResponse> refreshToken(@RequestHeader("X-Refresh-Token") String refreshToken) {
        log.info("Token refresh request received");
        
        SessionResponse response = authService.refreshToken(refreshToken);
        return ResponseEntity.ok(response);
    }
    
    /**
     * DELETE /auth/logout
     * Cerrar sesión actual
     */
    @DeleteMapping("/logout")
    public ResponseEntity<MessageResponse> logout(@RequestParam UUID sessionId) {
        log.info("Logout request for session: {}", sessionId);
        
        authService.logout(sessionId);
        return ResponseEntity.ok(MessageResponse.builder()
                .message("Logged out successfully")
                .build());
    }
    
    /**
     * DELETE /auth/logout-all
     * Cerrar todas las sesiones excepto la actual
     */
    @DeleteMapping("/logout-all")
    public ResponseEntity<MessageResponse> logoutAll(
            @RequestParam UUID userId,
            @RequestParam UUID currentSessionId) {
        log.info("Logout all request for user: {}", userId);
        
        authService.logoutAllOtherSessions(userId, currentSessionId);
        return ResponseEntity.ok(MessageResponse.builder()
                .message("All other sessions have been logged out")
                .build());
    }
}
