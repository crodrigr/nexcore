# NexCore — Specifications and Acceptance Criteria
## Service: `nexcore-auth-service`
**Version:** 0.1 (Exploration)
**Type:** Independent microservice
**Suggested port:** 8081
**Own database:** `nxc_auth` (schema shared with nexcore-core via Postgres)
**Date:** 2026-05

---

## 1. Context and Purpose

`nexcore-auth-service` is the microservice responsible for the entire authentication and credential management cycle for users of any application built on NexCore. It is designed as an independent service from the core to allow autonomous scaling, deployment, and maintenance.

### 1.1 Scope of this document

This spec covers three functional flows:

| # | Flow | Description |
|---|---|---|
| F-01 | **Login with 2FA via email** | The user enters credentials; if correct, receives an OTP code by email; upon validation, obtains their UI profile |
| F-02 | **Password recovery** | The user requests a reset link by email; uses it to set a new password |
| F-03 | **Password change** | The authenticated user changes their current password for a new one |

### 1.2 Domain Dependencies

```
nexcore-auth-service → nxc_tenant.users          (identity, status, email)
                     → nxc_tenant.user_roles     (roles assigned to the user)
                     → nxc_auth.login_attempts   (login attempts log)
                     → nxc_auth.otp_codes        (transient 2FA codes)
                     → nxc_auth.refresh_tokens   (refresh tokens)
                     → nxc_auth.sessions         (active sessions)
                     → nxc_auth.password_resets  (recovery tokens)
nexcore-auth-service → nexcore-core (HTTP)        (GET /api/v1/me/profile after successful login)
nexcore-auth-service → SMTP / email provider      (sending OTP and reset links)
```

### 1.3 Relationship with nexcore-core

After a successful login (2FA completed), `nexcore-auth-service` calls `nexcore-core GET /api/v1/me/profile` to obtain the UI profile and includes it in the client response. The `token` field of the profile will be the JWT issued by this service.

### 1.4 Mail infrastructure (SMTP/Postfix)

- Sending OTP, recovery links, and confirmations is done via **SMTP** using a Postfix server (development or production).
- SMTP configuration is defined in environment/config files (`application.yml`), never in source code.
- Uses `spring-boot-starter-mail` (JavaMailSender) for sending.
- Email templates can be Thymeleaf (HTML) or plain text.
- No external email providers are used unless explicitly configured.

---

## 2. Domain Models (exploration)

### 2.1 Session

Represents an active user session.

| Field | Type | Description |
|---|---|---|
| `id` | UUID | Session identifier |
| `userId` | UUID | Authenticated user |
| `tenantId` | UUID | User's tenant |
| `accessToken` | String | Short-lived JWT (e.g. 15 min) |
| `refreshToken` | String | Refresh token (e.g. 7 days) |
| `createdAt` | Timestamp | Session start |
| `expiresAt` | Timestamp | Refresh token expiration |
| `ipAddress` | String | Client IP at login |
| `userAgent` | String | Client User-Agent |

### 2.2 OtpCode

One-time code sent by email for 2FA.

| Field | Type | Description |
|---|---|---|
| `id` | UUID | Identifier |
| `userId` | UUID | Owner user |
| `tenantId` | UUID | Tenant |
| `code` | String | 6-digit numeric code (hashed in DB) |
| `purpose` | Enum | `LOGIN_2FA` \| `PASSWORD_RESET` |
| `expiresAt` | Timestamp | Expiration (e.g. 10 minutes) |
| `usedAt` | Timestamp | When it was used. `null` if still valid |
| `attempts` | Integer | Failed code entry attempts |

### 2.3 LoginAttempt

Log of each authentication attempt for brute-force protection.

| Field | Type | Description |
|---|---|---|
| `id` | UUID | Identifier |
| `userId` | UUID | User (may be `null` if username does not exist) |
| `tenantId` | UUID | Tenant |
| `username` | String | Attempted username |
| `success` | Boolean | Whether the attempt was successful |
| `stage` | Enum | `CREDENTIALS` \| `OTP` |
| `ipAddress` | String | Client IP |
| `attemptedAt` | Timestamp | Attempt time |

### 2.4 PasswordReset

Password recovery token.

| Field | Type | Description |
|---|---|---|
| `id` | UUID | Identifier |
| `userId` | UUID | Owner user |
| `token` | String | URL-safe token (hashed in DB) |
| `expiresAt` | Timestamp | Expiration (e.g. 30 minutes) |
| `usedAt` | Timestamp | When used. `null` if still valid |
| `ipAddress` | String | IP from which it was requested |

---

## 3. Functional Flows

---

### F-01 — Login with 2FA via email

#### 3.1.1 Flow Description

```
Client                      nexcore-auth-service              nexcore-core
  │                                  │                              │
  │── POST /auth/login ─────────────>│                              │
  │   {username, password, tenantId} │                              │
  │                                  │── Validate credentials       │
  │                                  │── Generate OTP, save hash    │
  │                                  │── Send OTP by email          │
  │<── 200 {challengeToken} ─────────│                              │
  │                                  │                              │
  │── POST /auth/verify-otp ────────>│                              │
  │   {challengeToken, code}         │                              │
  │                                  │── Validate OTP               │
  │                                  │── Create session (JWT+refresh)│
  │                                  │── GET /api/v1/me/profile ───>│
  │                                  │<── UI profile ───────────────│
  │<── 200 {profile + token} ────────│                              │
```

#### 3.1.2 Step 1 — Credentials validation (`POST /auth/login`)

**Request:**
{
  "tenantId": "uuid",
  "username": "string",
  "password": "string"
}
```

**Internal process:**
1. Resolve tenant by `tenantId` → must be `ACTIVE`
2. Find user by `username` + `tenantId` in `nxc_tenant.users`

```
nexcore-auth-service → Database (tables):
  • nxc_tenant.users          (identity, status, email)
  • nxc_tenant.user_roles     (roles assigned to the user)
  • nxc_auth.login_attempts   (login attempts log)
  • nxc_auth.otp_codes        (transient 2FA codes)
  • nxc_auth.refresh_tokens   (refresh tokens)
  • nxc_auth.sessions         (active sessions)
  • nxc_auth.password_resets  (recovery tokens)

nexcore-auth-service → HTTP Services:
  • nexcore-core (GET /api/v1/me/profile after successful login)
    - Tenant and menu modules are in nexcore-core, so tenant and role tables are there.

3. Verify user is not `SUSPENDED` or `BLOCKED`
  • SMTP / email provider (sending OTP and reset links)
```
4. Verify password against stored hash (bcrypt)
5. Check failed attempts limit (anti-brute-force)
6. Generate a `challengeToken` (short-lived JWT, e.g. 5 min, no resource access)
7. Generate 6-digit OTP, hash and save in `nxc_auth.otp_codes` with TTL 10 min
8. Send code by email to user
9. Log attempt in `nxc_auth.login_attempts` (stage: CREDENTIALS, success: true)

**Successful response (200):**
```json
{
  "challengeToken": "jwt-string",
  "message": "Verification code sent to the registered email address",
  "expiresIn": 300
}
```

**Errors:**

| Code | HTTP | Condition |
|---|---|---|
| `NXC-AUTH-0001` | 401 | Invalid credentials (username or password) |
| `NXC-AUTH-0002` | 403 | User suspended or blocked |
| `NXC-AUTH-0003` | 403 | Tenant inactive |
| `NXC-AUTH-0004` | 429 | Too many failed attempts (anti-brute-force) |
| `NXC-AUTH-0005` | 503 | Email sending error (OTP not sent) |

> **Security:** On invalid credentials, always return the same generic message ("Invalid credentials"), without indicating if the user exists or not.

---

#### 3.1.3 Step 2 — OTP verification (`POST /auth/verify-otp`)

**Request:**
```json
{
  "challengeToken": "jwt-string",
  "code": "123456"
}
```

**Internal process:**
1. Validate and decode `challengeToken` (must be valid and not expired)
2. Find active OTP for user (purpose: LOGIN_2FA, not used, not expired)
3. Compare `code` with stored hash
4. Log attempt in `nxc_auth.login_attempts` (stage: OTP)
5. If correct: mark OTP as used, create session, issue access JWT and refresh token
6. Call `nexcore-core GET /api/v1/me/profile` with headers `X-Tenant-Id` and `X-Actor-Id`
7. Return full profile with `token` = access JWT

**Successful response (200):**
```json
{
  "token": "jwt-access-token",
  "refreshToken": "refresh-token-opaque",
  "expiresIn": 900,
  "profile": { /* UserProfile object from nexcore-core */ }
}
```

**Errors:**

| Code | HTTP | Condition |
|---|---|---|
| `NXC-AUTH-0006` | 401 | Invalid or expired `challengeToken` |
| `NXC-AUTH-0007` | 401 | Invalid OTP code |
| `NXC-AUTH-0008` | 401 | Expired OTP code |
| `NXC-AUTH-0009` | 429 | Too many failed OTP attempts (block after N attempts) |

---

### F-02 — Password recovery

#### 3.2.1 Step 1 — Reset request (`POST /auth/password-reset/request`)

**Request:**
```json
{
  "tenantId": "uuid",
  "email": "string"
}
```

**Internal process:**
1. Find user by `email` + `tenantId`
2. If not found: **do not reveal** — respond as if it existed
3. If found and active: generate URL-safe token, hash and save in `nxc_auth.password_resets` with TTL 30 min
4. Send email with link: `https://app.nexcore.com/reset-password?token={plain-token}`
5. Invalidate previous reset tokens for the same user

**Response (always 200, even if email does not exist):**
```json
{
  "message": "If the email is registered, you will receive a link to reset your password"
}
```

**Errors:**

| Code | HTTP | Condition |
|---|---|---|
| `NXC-AUTH-0010` | 429 | Too many reset requests in a short period |
| `NXC-AUTH-0011` | 503 | Email sending error |

---

#### 3.2.2 Step 2 — Reset confirmation (`POST /auth/password-reset/confirm`)

**Request:**
```json
{
  "token": "plain-token-from-email",
  "newPassword": "string",
  "confirmPassword": "string"
}
```

**Internal process:**
1. Hash received token and find in `nxc_auth.password_resets`
2. Validate not used or expired
3. Validate `newPassword == confirmPassword`
4. Validate password policy (see §7)
5. Update password hash in `nxc_tenant.users`
6. Mark token as used
7. Invalidate all active sessions for the user (forced logout)
8. Send confirmation email

**Successful response (200):**
```json
{
  "message": "Password reset successfully. Please log in."
}
```

**Errors:**

| Code | HTTP | Condition |
|---|---|---|
| `NXC-AUTH-0012` | 400 | Invalid or already used token |
| `NXC-AUTH-0013` | 400 | Expired token |
| `NXC-AUTH-0014` | 400 | Passwords do not match |
| `NXC-AUTH-0015` | 400 | Password does not meet security policy |

---

### F-03 — Password change (authenticated user)

#### 3.3.1 Description (`PUT /auth/password`)

The user already has an active session and wants to voluntarily change their password.

**Required headers:**
```
Authorization: Bearer {accessToken}
```

**Request:**
```json
{
  "currentPassword": "string",
  "newPassword": "string",
  "confirmPassword": "string"
}
```

**Internal process:**
1. Validate JWT from header
2. Verify `currentPassword` against current hash in DB
3. Validate `newPassword != currentPassword` (no reuse)
4. Validate `newPassword == confirmPassword`
5. Validate password policy (see §7)
6. Update hash in `nxc_tenant.users`
7. Invalidate all active sessions except the current one (or all, depending on config)
8. Send change notification email

**Successful response (200):**
```json
{
  "message": "Password updated successfully"
}
```

**Errors:**

| Code | HTTP | Condition |
|---|---|---|
| `NXC-AUTH-0016` | 401 | Invalid or expired token |
| `NXC-AUTH-0017` | 400 | Incorrect current password |
| `NXC-AUTH-0018` | 400 | New password is the same as current password |
| `NXC-AUTH-0019` | 400 | Passwords do not match |
| `NXC-AUTH-0020` | 400 | Password does not meet security policy |

---

## 4. Acceptance Criteria

### CA-01 — Login with 2FA

| ID | Criteria |
|---|---|
| CA-01-01 | Given an active user with correct credentials, the system sends the OTP to the registered email and returns `challengeToken` in <= 3 seconds |
| CA-01-02 | Given a valid `challengeToken` and a correct OTP, the system returns the full UI profile with a valid access JWT |
| CA-01-03 | Given an incorrect OTP, the system returns 401 and increments the failed OTP attempts counter |
| CA-01-04 | Given 5 consecutive failed OTP attempts, the system blocks the `challengeToken` and returns 429 |
| CA-01-05 | Given a correct but expired OTP (> 10 min), the system returns 401 with code `NXC-AUTH-0008` |
| CA-01-06 | Given an expired `challengeToken` (> 5 min), the system returns 401 with code `NXC-AUTH-0006` regardless of the OTP |
| CA-01-07 | Given 10 failed credential attempts from the same IP in 15 minutes, the system returns 429 |
| CA-01-08 | An OTP cannot be reused: if already consumed, the system returns 401 |
| CA-01-09 | The login endpoint always returns the same response time for existing or non-existing users (timing-safe) |
| CA-01-10 | The `challengeToken` does not grant access to any protected resource: it is invalid outside the 2FA flow |

### CA-02 — Password recovery

| ID | Criteria |
|---|---|
| CA-02-01 | The reset request response is identical whether the email exists or not (does not reveal existence) |
| CA-02-02 | The reset token expires 30 minutes after generation |
| CA-02-03 | The reset token is single-use: a second attempt with the same token returns 400 |
| CA-02-04 | Upon confirming the reset, all active sessions for the user are invalidated |
| CA-02-05 | A new reset request invalidates previous reset tokens for the same user |
| CA-02-06 | The confirmation email is sent to the user after a successful reset |
| CA-02-07 | No more than 3 reset requests per user are allowed in a 1-hour period (CA: 429) |

### CA-03 — Password change

| ID | Criteria |
|---|---|
| CA-03-01 | The change requires a valid active session (non-expired JWT) |
