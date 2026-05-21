package com.nexore.auth.domain.service;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.List;
import java.util.UUID;

@Service
public class TokenService {

    private final SecretKey jwtSecretKey;
    private final long accessTokenExpirySeconds;
    private final long challengeTokenExpirySeconds;

    public TokenService(
            @Value("${nexcore.auth.jwt.secret}") String jwtSecret,
            @Value("${nexcore.auth.jwt.access-expiry-seconds:900}") long accessTokenExpiry,
            @Value("${nexcore.auth.jwt.challenge-expiry-seconds:300}") long challengeTokenExpiry
    ) {
        this.jwtSecretKey = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));
        this.accessTokenExpirySeconds = accessTokenExpiry;
        this.challengeTokenExpirySeconds = challengeTokenExpiry;
    }

    /**
     * Genera un challengeToken temporal para el flujo 2FA
     */
    public String generateChallengeToken(UUID userId, UUID tenantId, UUID otpCodeId) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(userId.toString())
                .claim("tid", tenantId.toString())
                .claim("otpCodeId", otpCodeId.toString())
                .claim("type", "CHALLENGE")
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(challengeTokenExpirySeconds)))
                .signWith(jwtSecretKey)
                .compact();
    }

    /**
     * Genera un accessToken JWT con roles y sesión
     */
    public String generateAccessToken(UUID userId, UUID tenantId, UUID sessionId, List<String> roles) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(userId.toString())
                .claim("tid", tenantId.toString())
                .claim("sid", sessionId.toString())
                .claim("roles", roles)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(accessTokenExpirySeconds)))
                .signWith(jwtSecretKey)
                .compact();
    }

    /**
     * Valida y decodifica un token JWT
     */
    public Claims validateToken(String token) {
        try {
            return Jwts.parser()
                    .verifyWith(jwtSecretKey)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
        } catch (ExpiredJwtException e) {
            throw new TokenExpiredException("Token has expired");
        } catch (JwtException e) {
            throw new InvalidTokenException("Invalid token");
        }
    }

    /**
     * Genera un refresh token opaco (UUID)
     */
    public String generateRefreshToken() {
        return UUID.randomUUID().toString();
    }
    
    // Clases de excepciones internas
    public static class TokenExpiredException extends RuntimeException {
        public TokenExpiredException(String message) {
            super(message);
        }
    }
    
    public static class InvalidTokenException extends RuntimeException {
        public InvalidTokenException(String message) {
            super(message);
        }
    }
}
