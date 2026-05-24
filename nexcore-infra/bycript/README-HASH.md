# Generador de Hash BCrypt para NexCore

Este directorio contiene varias herramientas para generar hashes BCrypt de contraseñas.

## 🚀 Opción 1: Script Bash + PostgreSQL (MÁS SIMPLE)

Usa el contenedor PostgreSQL que ya tienes corriendo:

```bash
./generar-hash.sh "Admin123"
```

**Ventajas:**
- ✅ No requiere compilar nada
- ✅ Usa recursos que ya tienes (PostgreSQL)
- ✅ Súper rápido

---

## 🔧 Opción 2: Programa Java (JBang)

Si tienes JBang instalado:

```bash
jbang PasswordHashSimple.java "Admin123"
```

Si no tienes JBang, instálalo:
```bash
curl -Ls https://sh.jbang.dev | bash -s - app setup
```

---

## 📝 Opción 3: Programa Java Completo

### Compilar y ejecutar:

```bash
# Desde el directorio nexcore-auth-service
cd ../../nexcore-auth-service

# Opción A: Usar Gradle para compilar y ejecutar
./gradlew compileJava

# Luego copiar el JAR de spring-security-crypto y compilar
javac -cp $(find ~/.gradle -name "spring-security-crypto-*.jar" | head -1) ../nexcore-infra/database/PasswordHasher.java

# Ejecutar
java -cp "../nexcore-infra/database:$(find ~/.gradle -name "spring-security-crypto-*.jar" | head -1)" PasswordHasher hash "Admin123"
```

---

## 🌐 Opción 4: API REST del auth-service

Si el servicio está corriendo:

```bash
curl "http://localhost:8081/auth/utils/hash?password=Admin123"
```

---

## 📋 Ejemplos de Uso

### Generar hash de una contraseña:
```bash
./generar-hash.sh "Admin123"
```

### Generar hash de otra contraseña:
```bash
./generar-hash.sh "MiSuperPassword123!"
```

### Copiar directamente al portapapeles (Linux):
```bash
./generar-hash.sh "Admin123" | grep '$2a' | xclip -selection clipboard
```

---

## ✅ Contraseñas del Sistema

Aquí están los hashes ya generados para las contraseñas principales:

| Contraseña | Hash BCrypt |
|------------|-------------|
| `Admin123` | `$2a$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi` |

---

## 🔍 Verificar una Contraseña

Para verificar si una contraseña coincide con un hash:

```bash
# Usando PostgreSQL
docker exec postgres-db psql -U admin -d nexcore -c \
  "SELECT crypt('Admin123', '\$2a\$12\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi') = '\$2a\$12\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi';"
```

Si retorna `t` (true), la contraseña es correcta.

---

## 📦 Archivos en este Directorio

- `generar-hash.sh` - Script simple con PostgreSQL ⭐ **RECOMENDADO**
- `PasswordHashSimple.java` - Versión Java con JBang
- `PasswordHasher.java` - Versión Java completa
- `hash-password.sh` - Script wrapper para Java
- `schema-nexcore.sql` - Schema completo de la base de datos
- `02-migrate-base.sql` - Datos iniciales (seed data)

---

## 🆘 Solución de Problemas

### Error: "No se pudo generar el hash"

Verifica que PostgreSQL esté corriendo:
```bash
docker ps | grep postgres-db
```

Instala la extensión pgcrypto si no está:
```bash
docker exec postgres-db psql -U admin -d nexcore -c 'CREATE EXTENSION IF NOT EXISTS pgcrypto;'
```

### El hash generado no funciona en Spring Boot

- BCrypt usa cost=12 por defecto
- Los hashes BCrypt siempre empiezan con `$2a$`, `$2b$` o `$2y$`
- Spring Security acepta cualquiera de estos formatos
- Asegúrate de copiar el hash completo (60 caracteres)

---

## 📚 Documentación

- [BCrypt en Spring Security](https://docs.spring.io/spring-security/reference/features/authentication/password-storage.html#authentication-password-storage-bcrypt)
- [PostgreSQL pgcrypto](https://www.postgresql.org/docs/current/pgcrypto.html)
