package com.nexore.auth.application.service;

import com.nexore.auth.application.dto.request.LoginRequest;
import com.nexore.auth.application.dto.request.VerifyOtpRequest;
import com.nexore.auth.application.dto.response.ChallengeResponse;
import com.nexore.auth.application.dto.response.SessionResponse;
import com.nexore.auth.domain.exception.*;
import com.nexore.auth.domain.model.*;
import com.nexore.auth.domain.repository.*;
import com.nexore.auth.domain.service.*;
import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.servlet.http.HttpServletRequest;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final TenantRepository tenantRepository;
    private final UserRepository userRepository;
    private final SessionRepository sessionRepository;
    private final LoginAttemptRepository loginAttemptRepository;
    private final TokenService tokenService;
    private final OtpService otpService;
    private final BruteForceProtection bruteForceProtection;
    private final EmailService emailService;
    private final NexcoreCoreClient nexcoreCoreClient;
    private final HttpServletRequest httpRequest;

    @Value("${nexcore.auth.jwt.access-expiry-seconds}")
    private int accessExpirySeconds;

    @Value("${nexcore.auth.jwt.refresh-expiry-days}")
    private int refreshExpiryDays;

    @Value("${nexcore.auth.jwt.challenge-expiry-seconds}")
    private int challengeExpirySeconds;

    @Transactional
    public ChallengeResponse login(LoginRequest request) {
        String ipAddress = getClientIp();
        
        // DEBUG: Log request details
        log.info("🔍 LOGIN REQUEST - TenantId: {}, Username: {}, Password: '{}', IP: {}", 
                request.getTenantId(), 
                request.getUsername(), 
                request.getPassword(),
                ipAddress);

        Tenant tenant = tenantRepository.findById(request.getTenantId())
                .orElseThrow(() -> new TenantNotFoundException(request.getTenantId(), "Tenant not found"));
        
        log.info("✅ Tenant found - ID: {}, Name: {}, Active: {}", tenant.getId(), tenant.getName(), tenant.getActive());

        if (!tenant.getActive()) {
            throw new TenantInactiveException(request.getTenantId(), "Tenant is inactive");
        }

        User user = userRepository.findByTenantIdAndUsername(request.getTenantId(), request.getUsername())
                .orElse(null);
        
        if (user == null) {
            log.warn("❌ User NOT found - TenantId: {}, Username: {}", request.getTenantId(), request.getUsername());
        } else {
            log.info("✅ User found - ID: {}, Username: {}, Email: {}, Active: {}, Suspended: {}, PasswordHash: {}", 
                    user.getId(), 
                    user.getUsername(), 
                    user.getEmail(),
                    user.getActive(), 
                    user.getSuspended(),
                    user.getPasswordHash() != null ? user.getPasswordHash().substring(0, 20) + "..." : "NULL");
        }

        try {
            bruteForceProtection.checkRateLimit(user != null ? user.getId() : null, ipAddress);
        } catch (BruteForceProtection.TooManyAttemptsException e) {
            log.warn("Rate limit exceeded for IP: {} and user: {}", ipAddress, request.getUsername());
            recordFailedAttempt(user != null ? user.getId() : null, request.getTenantId(), request.getUsername(), ipAddress, "CREDENTIALS");
            throw e;
        }

        if (user == null) {
            recordFailedAttempt(null, request.getTenantId(), request.getUsername(), ipAddress, "CREDENTIALS");
            bruteForceProtection.recordFailedAttempt(null, ipAddress);
            throw new InvalidCredentialsException("Invalid username or password");
        }

        if (user.getSuspended()) {
            recordFailedAttempt(user.getId(), user.getTenantId(), user.getUsername(), ipAddress, "CREDENTIALS");
            throw new UserSuspendedException(user.getId(), "User is suspended");
        }

        if (!user.getActive()) {
            recordFailedAttempt(user.getId(), user.getTenantId(), user.getUsername(), ipAddress, "CREDENTIALS");
            throw new InvalidCredentialsException("User is inactive");
        }

        boolean passwordMatches = BCrypt.checkpw(request.getPassword(), user.getPasswordHash());
        log.info("🔐 Password validation - Matches: {}, Input password: '{}', Stored hash: '{}'", 
                passwordMatches, 
                request.getPassword(),
                user.getPasswordHash().substring(0, 30) + "...");
        
        if (!passwordMatches) {
            recordFailedAttempt(user.getId(), user.getTenantId(), user.getUsername(), ipAddress, "CREDENTIALS");
            bruteForceProtection.recordFailedAttempt(user.getId(), ipAddress);
            throw new InvalidCredentialsException("Invalid username or password");
        }

        OtpCode otpCode = otpService.createLoginOtp(user.getId(), request.getTenantId(), user.getUsername());

        try {
            emailService.sendOtpEmail(user.getEmail(), user.getUsername(), otpCode);
        } catch (Exception e) {
            log.error("Failed to send OTP email to user {}", user.getEmail(), e);
            throw new EmailSendingException("Failed to send OTP email", e);
        }

        String challengeToken = tokenService.generateChallengeToken(user.getId(), request.getTenantId(), otpCode.getId());

        log.info("Login challenge issued for user {} from IP {}", user.getUsername(), ipAddress);

        return ChallengeResponse.builder()
                .challengeToken(challengeToken)
                .message("OTP sent to your email")
                .expiresIn(challengeExpirySeconds)
                .build();
    }

    @Transactional
    public SessionResponse verifyOtp(VerifyOtpRequest request) {
        String ipAddress = getClientIp();
        String userAgent = getUserAgent();

        Claims claims;
        try {
            claims = tokenService.validateToken(request.getChallengeToken());
        } catch (Exception e) {
            throw new InvalidOtpException("Invalid or expired challenge token");
        }

        UUID userId = UUID.fromString(claims.getSubject());
        UUID tenantId = UUID.fromString(claims.get("tid", String.class));

        String otpCodeIdStr = claims.get("otpCodeId", String.class);
        if (otpCodeIdStr == null) {
            throw new InvalidOtpException("Challenge token does not contain OTP code ID");
        }
        UUID otpCodeId = UUID.fromString(otpCodeIdStr);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new InvalidCredentialsException("User not found"));

        try {
            otpService.validateOtp(otpCodeId, request.getCode());
        } catch (OtpService.OtpNotFoundException | OtpService.OtpExpiredException | OtpService.TooManyAttemptsException e) {
            recordFailedAttempt(userId, tenantId, user.getUsername(), ipAddress, "OTP");
            throw new InvalidOtpException(e.getMessage(), e);
        }

        String refreshToken = tokenService.generateRefreshToken();
        String refreshTokenHash = otpService.hashOtp(refreshToken);

        Session session = Session.builder()
                .id(UUID.randomUUID())
                .userId(userId)
                .tenantId(tenantId)
                .refreshTokenHash(refreshTokenHash)
                .ipAddress(ipAddress)
                .userAgent(userAgent)
                .createdAt(Instant.now())
                .expiresAt(Instant.now().plus(Duration.ofDays(refreshExpiryDays)))
                .build();

        sessionRepository.save(session);

        String accessToken = tokenService.generateAccessToken(user.getId(), tenantId, session.getId(), null);

        Object userProfile;
        try {
            userProfile = nexcoreCoreClient.getUserProfile(accessToken);
        } catch (Exception e) {
            log.error("Failed to fetch user profile from nexcore-core", e);
            userProfile = null;
        }

        recordSuccessfulAttempt(user, ipAddress);
        bruteForceProtection.resetAttempts(userId, ipAddress);

        log.info("User {} logged in successfully from IP {}", user.getUsername(), ipAddress);

        return SessionResponse.builder()
                .token(accessToken)
                .refreshToken(refreshToken)
                .expiresIn(accessExpirySeconds)
                .profile(userProfile)
                .build();
    }

    @Transactional
    public SessionResponse refreshToken(String refreshToken) {
        String refreshTokenHash = otpService.hashOtp(refreshToken);

        Session session = sessionRepository.findByRefreshTokenHash(refreshTokenHash)
                .orElseThrow(() -> new InvalidCredentialsException("Invalid refresh token"));

        if (session.getRevokedAt() != null) {
            throw new InvalidCredentialsException("Session has been revoked");
        }

        if (session.getExpiresAt().isBefore(Instant.now())) {
            throw new InvalidCredentialsException("Session has expired");
        }

        User user = userRepository.findById(session.getUserId())
                .orElseThrow(() -> new InvalidCredentialsException("User not found"));

        String accessToken = tokenService.generateAccessToken(
                user.getId(), session.getTenantId(), session.getId(), null);

        Object userProfile;
        try {
            userProfile = nexcoreCoreClient.getUserProfile(accessToken);
        } catch (Exception e) {
            log.error("Failed to fetch user profile from nexcore-core", e);
            userProfile = null;
        }

        log.info("Access token refreshed for user {} session {}", user.getUsername(), session.getId());

        return SessionResponse.builder()
                .token(accessToken)
                .refreshToken(refreshToken)
                .expiresIn(accessExpirySeconds)
                .profile(userProfile)
                .build();
    }

    @Transactional
    public void logout(UUID sessionId) {
        sessionRepository.revokeById(sessionId);
        log.info("Session {} revoked", sessionId);
    }

    @Transactional
    public void logoutAllOtherSessions(UUID userId, UUID currentSessionId) {
        sessionRepository.revokeAllByUserIdExcept(userId, currentSessionId);
        log.info("All sessions revoked for user {} except {}", userId, currentSessionId);
    }

    private void recordFailedAttempt(UUID userId, UUID tenantId, String username, String ipAddress, String stage) {
        LoginAttempt attempt = LoginAttempt.builder()
                .id(UUID.randomUUID())
                .userId(userId)
                .tenantId(tenantId)
                .username(username)
                .success(false)
                .stage(stage)
                .ipAddress(ipAddress)
                .attemptedAt(Instant.now())
                .build();
        loginAttemptRepository.save(attempt);
    }

    private void recordSuccessfulAttempt(User user, String ipAddress) {
        LoginAttempt attempt = LoginAttempt.builder()
                .id(UUID.randomUUID())
                .userId(user.getId())
                .tenantId(user.getTenantId())
                .username(user.getUsername())
                .success(true)
                .stage("OTP")
                .ipAddress(ipAddress)
                .attemptedAt(Instant.now())
                .build();
        loginAttemptRepository.save(attempt);
    }

    private String getClientIp() {
        String xForwardedFor = httpRequest.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        return httpRequest.getRemoteAddr();
    }

    private String getUserAgent() {
        String ua = httpRequest.getHeader("User-Agent");
        return ua != null ? ua : "Unknown";
    }
}
