# Especificación: Implementación de Autenticación (Login) — NexCore Frontend

Última actualización: 2026-05-23

Propósito: definir la integración frontend con el Auth Service para los flujos de login 2FA (OTP), verificación de código y recuperación de contraseña. Incluye contratos HTTP, ejemplos de request/response, consideraciones de UX, seguridad y pruebas.

---

## 1. Resumen ejecutivo

- Objetivo: implementar en el frontend los endpoints necesarios para: iniciar sesión (login 2FA), verificar OTP, solicitar reseteo de contraseña y confirmar reseteo.
- Endpoints principales (Auth Service, extraídos de Postman):
  - `POST /auth/login` — Paso 1: validar credenciales y enviar OTP.
  - `POST /auth/verify-otp` — Paso 2: verificar código OTP y obtener tokens.
  - `POST /auth/password/reset/request` — Solicitar email de reset (frontend route: `/forgot-password`).
  - `POST /auth/password/reset/confirm` — Confirmar nuevo password usando token del email.

Decisión principal: el frontend implementará un servicio `AuthService` con métodos claros para cada paso y manejadores de estado (loading, success, error) para UI.

---

## 2. Alcance

Incluye:
- Integración con los endpoints listados.
- Formulario de login (username/password) que inicia el flujo 2FA.
- Pantalla para ingresar OTP (código de 6 dígitos) y completar login.
- Página `/forgot-password` para solicitar reset y pantalla para confirmar nuevo password.
- Manejo seguro de tokens, refresh y cierre de sesión.
- Mensajes de error traducibles y tests unitarios + e2e básicos.

No incluye:
- Implementación backend de envío de emails o gestión de refresh-token en cookies. Se asume la API definida en Postman.

---

## 3. Contratos HTTP (extractos de Postman)

3.1 `POST /auth/login`
- Content-Type: `application/json`
- Body:

```json
{
  "tenantId": "<tenantId>",
  "username": "<username>",
  "password": "<password>"
}
```

- Éxito (200) ejemplo:

```json
{
  "challengeToken": "eyJhbGc...",
  "message": "OTP sent to your email",
  "expiresIn": 300
}
```

- Notas: guardar `challengeToken` temporalmente (in-memory o en un store temporal) para el paso de verificación.

3.2 `POST /auth/verify-otp`
- Content-Type: `application/json`
- Body:

```json
{
  "challengeToken": "<challengeToken>",
  "code": "123456"
}
```

- Éxito (200) ejemplo:

```json
{
  "token": "eyJhbGc...",
  "refreshToken": "a1b2c3...",
  "expiresIn": 900,
  "profile": { /* user profile */ }
}
```

- Notas: recibir `token` (access) y `refreshToken`. Preferir que backend gestione `refreshToken` en `HttpOnly` cookie; si no es posible, documentar almacenamiento seguro.

3.3 `POST /auth/password/reset/request` (frontend `/forgot-password`)
- Content-Type: `application/json`
- Body:

```json
{
  "tenantId": "<tenantId>",
  "email": "usuario@empresa.com"
}
```

- Éxito (200) ejemplo:
```json
{ "message": "Password reset email sent" }
```

3.4 `POST /auth/password/reset/confirm`
- Content-Type: `application/json`
- Body:

```json
{
  "token": "RESET_TOKEN_FROM_EMAIL",
  "newPassword": "NewPassword123!"
}
```

- Éxito (200) ejemplo:

```json
{ "message": "Password reset successfully" }
```

---

## 4. Flujos de UI

4.1 Login 2FA (flujo)
- Usuario completa `username` y `password` en `/login`.
- Llamar `AuthService.loginStep1({tenantId, username, password})` → muestra pantalla OTP y mensaje: "OTP enviado al correo".
- Usuario ingresa código OTP; llamar `AuthService.verifyOtp({challengeToken, code})`.
- Si success: almacenar tokens y redirigir a dashboard.
- Si error: mostrar error traducible (ej. "Código inválido" / "Código expirado").

UI considerations:
- Timeout visual de `expiresIn` (ej. 5 minutos) y opción "Reenviar OTP" que reintenta `loginStep1`.
- Validaciones en frontend para OTP: solo dígitos, longitud fija (6).

4.2 Forgot password
- Página `/forgot-password` con campo `email`.
- Llamar `AuthService.requestPasswordReset({tenantId, email})`.
- Mostrar mensaje confirmatorio: "Si existe una cuenta, se ha enviado un email con instrucciones" (para no filtrar usuarios).
- Página para ingresar token y nuevo password (puede ser ruta con query `?token=...` o formulario manual): llamar `AuthService.confirmPasswordReset({token, newPassword})`.

---

## 5. Manejadores de estado y almacenamiento de tokens

- Recomendación de almacenamiento:
  - `access token`: mantener en memory (por ejemplo en `AuthStore`) y en caso de reload, recuperar vía refresh token.
  - `refresh token`: preferible usar `HttpOnly Secure SameSite` cookie configurada por backend. Si el backend devuelve `refreshToken` en body, coordinar con backend para cambiar a cookie; si no es posible, almacenar en `localStorage` solo si se entiende el riesgo (documentar y minimizar tiempo de vida).

- Manejo automático de refresh:
  - Implementar un `AuthInterceptor` que, ante 401, intente `AuthService.refresh()` una vez y retry de la request original.
  - Evitar parallel refreshes: usar cola/promise lock.

---

## 6. Errores y códigos esperados (UX)

- 400 Bad Request: request mal formado — mostrar "Datos inválidos".
- 401 Unauthorized: credenciales inválidas o token expirado — en login mostrar "Usuario o contraseña inválidos"; en verify-otp mostrar "Código inválido o expirado".
- 429 Too Many Requests: bloquear temporal y mostrar "Demasiados intentos. Intenta de nuevo más tarde.".
- 500 Server Error: mostrar mensaje genérico y permitir reintentar.

Todas las cadenas deben ser traducibles e incluidas en `assets/i18n/auth.json` (clave recomendada: `auth.login.*`, `auth.otp.*`, `auth.forgot.*`).

---

## 7. Contratos del frontend (API de `AuthService` sugerida)

Interfaces TypeScript (ejemplos):

```ts
interface LoginStep1Req { tenantId: string; username: string; password: string }
interface LoginStep1Res { challengeToken: string; message: string; expiresIn: number }

interface VerifyOtpReq { challengeToken: string; code: string }
interface VerifyOtpRes { token: string; refreshToken?: string; expiresIn: number; profile: any }

interface PasswordResetRequestReq { tenantId: string; email: string }
interface PasswordResetConfirmReq { token: string; newPassword: string }
```

AuthService métodos recomendados:
- `loginStep1(payload: LoginStep1Req): Promise<LoginStep1Res>`
- `verifyOtp(payload: VerifyOtpReq): Promise<VerifyOtpRes>`
- `requestPasswordReset(payload: PasswordResetRequestReq): Promise<void>`
- `confirmPasswordReset(payload: PasswordResetConfirmReq): Promise<void>`
- `refresh(): Promise<void>`
- `logout(sessionId?: string): Promise<void>`

---

## 8. Seguridad

- Preferir `HttpOnly` cookies para `refreshToken` y enviar `access token` en `Authorization: Bearer <token>`.
- Usar `Content-Security-Policy`, `SameSite`, `Secure` y políticas CORS apropiadas (coordinación con backend).
- Limitar intentos de login/OTP en frontend UI y mostrar reCAPTCHA si se detecta abuso (opcional).

---

## 9. Tests y QA

- Unit tests:
  - Mock `AuthService` y testear componentes de login/otp/forgot para estados (loading, success, error).
  - Testear `AuthInterceptor` con simulación de 401 y flujo de refresh.

- E2E:
  - Flujo completo login 2FA (si el entorno de test puede recibir emails, usar token de test o bypass de OTP en CI). Alternativa: stubear backend o usar endpoints de Postman con tokens fijos para e2e.
  - Flujo forgot-password (request + confirm) usando token simulado.

---

## 10. Notas de integración y próximos pasos

- Verificar con el equipo backend si pueden devolver `refreshToken` como `HttpOnly` cookie para mejorar seguridad.
- Agregar las claves i18n en `src/assets/i18n/es/auth.json` y `en/auth.json` (scaffold) con entradas mínimas: `login.title`, `login.username`, `login.password`, `otp.title`, `forgot.title`, `messages.otpSent`, `errors.invalidCredentials`, `errors.invalidOtp`.
- Implementar `AuthService` y `AuthInterceptor` y añadir tests unitarios.

---

## 11. Referencias

- Colección Postman: `nexcore-infra/postman/nexcore-collection.json` (sección "Autenticación (Auth Service)").
- Archivo de ejemplo i18n (ver `03-multilenguaje-spec.md`).

---

Si quieres, implemento el scaffold inicial de `src/assets/i18n/*/auth.json` y un boceto de `AuthService` en TypeScript. ¿Procedo con eso?