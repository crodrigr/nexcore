# NexCore — Guía para crear un módulo en nexcore-core

Cuando el usuario pida crear un nuevo módulo o feature en el backend (`nexcore-core`),
sigue **exactamente** la arquitectura hexagonal establecida en los módulos `tenant` y `menu`.
Nunca inventes estructuras nuevas; extiende las existentes.

---

## 1. Estructura de paquetes

Cada módulo vive en `com.nexore.core.module.<nombre_modulo>` y se divide en tres capas:

```
module/<nombre>/
├── application/
│   ├── dto/
│   │   ├── request/       ← DTOs de entrada (validados con jakarta.validation)
│   │   └── response/      ← DTOs de salida
│   ├── mapper/            ← Mappers domain ↔ DTO (manual, @Component, sin MapStruct)
│   └── service/           ← Casos de uso (@Service, @Transactional)
├── domain/
│   ├── model/             ← Entidades de dominio (POJO con Lombok @Builder)
│   └── repository/        ← Interfaces de repositorio (sin Spring)
└── infrastructure/
    ├── persistence/
    │   ├── entity/        ← JPA entities (@Entity, @Table con schema)
    │   ├── jpa/           ← SpringData interfaces (extends JpaRepository)
    │   ├── mapper/        ← Mappers entity ↔ domain (@Component)
    │   └── Jpa<X>RepositoryAdapter.java  ← implementa la interfaz de dominio
    └── web/
        ├── <X>Controller.java
        └── GlobalExceptionHandler.java  ← solo si es el primer módulo del paquete
```

---

## 2. Modelo de dominio

```java
package com.nexore.core.module.<nombre>.domain.model;

import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class <Entidad> {
    private UUID id;
    private UUID tenantId;       // casi siempre presente (multi-tenant)
    private String name;
    // ... campos de negocio ...
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;
    private OffsetDateTime deletedAt;  // soft delete
    private int version;               // optimistic locking
}
```

**Reglas:**
- POJO puro — sin anotaciones JPA ni Spring.
- Usar `OffsetDateTime` para fechas (no `LocalDateTime`).
- `deletedAt` para soft-delete; nunca borrar físicamente registros de negocio.
- `int version` para optimistic locking cuando haya concurrencia.

---

## 3. Interfaz de repositorio (dominio)

```java
package com.nexore.core.module.<nombre>.domain.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface <Entidad>Repository {
    <Entidad> save(<Entidad> entity);
    Optional<<Entidad>> findById(UUID id);
    Optional<<Entidad>> findByTenantIdAndId(UUID tenantId, UUID id);
    List<<Entidad>> findAllByTenantId(UUID tenantId, int page, int size);
    long countByTenantId(UUID tenantId);
    boolean existsByTenantIdAndName(UUID tenantId, String name);
}
```

---

## 4. JPA Entity

```java
package com.nexore.core.module.<nombre>.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcType;
import org.hibernate.dialect.type.PostgreSQLEnumJdbcType;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity(name = "<Entidad>")
@Table(name = "<tabla>", schema = "nxc_<schema>")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class <Entidad>JpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(name = "tenant_id", nullable = false, updatable = false)
    private UUID tenantId;

    @Column(nullable = false, length = 200)
    private String name;

    // Para enums PostgreSQL nativos:
    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(nullable = false, columnDefinition = "nxc_<schema>.<tipo_enum>")
    private <TipoEnum> status;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @Column(name = "deleted_at")
    private OffsetDateTime deletedAt;

    @Version
    @Column(nullable = false)
    private int version;

    @PrePersist
    void prePersist() {
        OffsetDateTime now = OffsetDateTime.now();
        if (createdAt == null) createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
```

---

## 5. SpringData JPA Repository

```java
package com.nexore.core.module.<nombre>.infrastructure.persistence.jpa;

import com.nexore.core.module.<nombre>.infrastructure.persistence.entity.<Entidad>JpaEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

public interface SpringData<Entidad>Repository extends JpaRepository<<Entidad>JpaEntity, UUID> {
    Optional<<Entidad>JpaEntity> findByTenantIdAndIdAndDeletedAtIsNull(UUID tenantId, UUID id);
    Page<<Entidad>JpaEntity> findAllByTenantIdAndDeletedAtIsNull(UUID tenantId, Pageable pageable);
    long countByTenantIdAndDeletedAtIsNull(UUID tenantId);
    boolean existsByTenantIdAndNameIgnoreCaseAndDeletedAtIsNull(UUID tenantId, String name);
}
```

---

## 6. Adapter (implementa repositorio de dominio)

```java
package com.nexore.core.module.<nombre>.infrastructure.persistence;

import com.nexore.core.module.<nombre>.domain.model.<Entidad>;
import com.nexore.core.module.<nombre>.domain.repository.<Entidad>Repository;
import com.nexore.core.module.<nombre>.infrastructure.persistence.jpa.SpringData<Entidad>Repository;
import com.nexore.core.module.<nombre>.infrastructure.persistence.mapper.<Entidad>PersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class Jpa<Entidad>RepositoryAdapter implements <Entidad>Repository {

    private final SpringData<Entidad>Repository delegate;
    private final <Entidad>PersistenceMapper mapper;

    @Override
    public <Entidad> save(<Entidad> entity) {
        return mapper.toDomain(delegate.save(mapper.toEntity(entity)));
    }

    @Override
    public Optional<<Entidad>> findByTenantIdAndId(UUID tenantId, UUID id) {
        return delegate.findByTenantIdAndIdAndDeletedAtIsNull(tenantId, id)
                .map(mapper::toDomain);
    }

    @Override
    public List<<Entidad>> findAllByTenantId(UUID tenantId, int page, int size) {
        return delegate.findAllByTenantIdAndDeletedAtIsNull(tenantId, PageRequest.of(page, size))
                .getContent().stream().map(mapper::toDomain).toList();
    }

    @Override
    public long countByTenantId(UUID tenantId) {
        return delegate.countByTenantIdAndDeletedAtIsNull(tenantId);
    }
}
```

---

## 7. Persistence Mapper

```java
package com.nexore.core.module.<nombre>.infrastructure.persistence.mapper;

import com.nexore.core.module.<nombre>.domain.model.<Entidad>;
import com.nexore.core.module.<nombre>.infrastructure.persistence.entity.<Entidad>JpaEntity;
import org.springframework.stereotype.Component;

@Component
public class <Entidad>PersistenceMapper {

    public <Entidad> toDomain(<Entidad>JpaEntity e) {
        return <Entidad>.builder()
                .id(e.getId())
                .tenantId(e.getTenantId())
                .name(e.getName())
                .createdAt(e.getCreatedAt())
                .updatedAt(e.getUpdatedAt())
                .deletedAt(e.getDeletedAt())
                .version(e.getVersion())
                .build();
    }

    public <Entidad>JpaEntity toEntity(<Entidad> d) {
        return <Entidad>JpaEntity.builder()
                .id(d.getId())
                .tenantId(d.getTenantId())
                .name(d.getName())
                .deletedAt(d.getDeletedAt())
                .version(d.getVersion())
                .build();
    }
}
```

---

## 8. Application Service

```java
package com.nexore.core.module.<nombre>.application.service;

import com.nexore.core.module.<nombre>.application.dto.request.<Entidad>CreateRequest;
import com.nexore.core.module.<nombre>.application.dto.response.<Entidad>Response;
import com.nexore.core.module.<nombre>.application.mapper.<Entidad>Mapper;
import com.nexore.core.module.<nombre>.domain.model.<Entidad>;
import com.nexore.core.module.<nombre>.domain.repository.<Entidad>Repository;
import com.nexore.core.module.tenant.application.dto.response.PageResponse;
import com.nexore.core.module.tenant.application.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class <Entidad>Service {

    private final <Entidad>Repository repository;
    private final <Entidad>Mapper mapper;

    @Transactional
    public <Entidad>Response create(UUID tenantId, <Entidad>CreateRequest request) {
        if (repository.existsByTenantIdAndName(tenantId, request.getName())) {
            throw BusinessException.<moduloNameDuplicated>(request.getName());
        }
        <Entidad> entity = mapper.toEntity(request, tenantId);
        return mapper.toResponse(repository.save(entity));
    }

    @Transactional(readOnly = true)
    public <Entidad>Response getById(UUID tenantId, UUID id) {
        return repository.findByTenantIdAndId(tenantId, id)
                .filter(e -> e.getDeletedAt() == null)
                .map(mapper::toResponse)
                .orElseThrow(BusinessException::<moduloNotFound>);
    }

    @Transactional(readOnly = true)
    public PageResponse<<Entidad>Response> list(UUID tenantId, int page, int size) {
        List<<Entidad>Response> content = repository.findAllByTenantId(tenantId, page, size)
                .stream().map(mapper::toResponse).toList();
        long total = repository.countByTenantId(tenantId);
        int totalPages = total == 0 ? 1 : (int) Math.ceil((double) total / Math.max(1, size));
        return PageResponse.<Entidad>Response>builder()
                .content(content).page(page).size(size)
                .totalElements(total).totalPages(totalPages).last(page >= totalPages - 1)
                .build();
    }

    @Transactional
    public void delete(UUID tenantId, UUID id) {
        <Entidad> entity = repository.findByTenantIdAndId(tenantId, id)
                .filter(e -> e.getDeletedAt() == null)
                .orElseThrow(BusinessException::<moduloNotFound>);
        entity.setDeletedAt(java.time.OffsetDateTime.now());
        repository.save(entity);
    }
}
```

---

## 9. Application Mapper (DTO ↔ Domain)

```java
package com.nexore.core.module.<nombre>.application.mapper;

import com.nexore.core.module.<nombre>.application.dto.request.<Entidad>CreateRequest;
import com.nexore.core.module.<nombre>.application.dto.response.<Entidad>Response;
import com.nexore.core.module.<nombre>.domain.model.<Entidad>;
import org.springframework.stereotype.Component;
import java.util.UUID;

@Component
public class <Entidad>Mapper {

    public <Entidad> toEntity(<Entidad>CreateRequest req, UUID tenantId) {
        return <Entidad>.builder()
                .tenantId(tenantId)
                .name(req.getName())
                .build();
    }

    public <Entidad>Response toResponse(<Entidad> d) {
        return <Entidad>Response.builder()
                .id(d.getId())
                .tenantId(d.getTenantId())
                .name(d.getName())
                .createdAt(d.getCreatedAt())
                .build();
    }

    public void applyUpdate(<Entidad>UpdateRequest req, <Entidad> entity) {
        if (req.getName() != null) entity.setName(req.getName());
    }
}
```

---

## 10. DTOs

### Request

```java
package com.nexore.core.module.<nombre>.application.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class <Entidad>CreateRequest {
    @NotBlank @Size(min = 3, max = 200)
    private String name;

    @NotNull
    private UUID tenantId;   // si no viene en header
}
```

### Response

```java
package com.nexore.core.module.<nombre>.application.dto.response;

import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class <Entidad>Response {
    private UUID id;
    private UUID tenantId;
    private String name;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;
}
```

---

## 11. Controller REST

```java
package com.nexore.core.module.<nombre>.infrastructure.web;

import com.nexore.core.module.<nombre>.application.dto.request.<Entidad>CreateRequest;
import com.nexore.core.module.<nombre>.application.dto.response.<Entidad>Response;
import com.nexore.core.module.<nombre>.application.service.<Entidad>Service;
import com.nexore.core.module.tenant.application.dto.response.PageResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;
import java.net.URI;
import java.util.UUID;

/**
 * Auth headers (temporal — serán extraídos del JWT cuando Security esté implementado):
 *   X-Tenant-Id       : UUID del tenant activo
 *   X-Actor-Id        : UUID del usuario autenticado
 *   X-Is-Tenant-Admin : true si el caller tiene TENANT_ADMIN
 */
@RestController
@RequestMapping("/api/v1/<recurso>")
@RequiredArgsConstructor
public class <Entidad>Controller {

    private final <Entidad>Service service;

    /** GET /api/v1/<recurso> */
    @GetMapping
    public ResponseEntity<PageResponse<<Entidad>Response>> list(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(service.list(tenantId, page, size));
    }

    /** POST /api/v1/<recurso> */
    @PostMapping
    public ResponseEntity<<Entidad>Response> create(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId,
            @Valid @RequestBody <Entidad>CreateRequest request) {
        <Entidad>Response response = service.create(tenantId, request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}").buildAndExpand(response.getId()).toUri();
        return ResponseEntity.created(location).body(response);
    }

    /** GET /api/v1/<recurso>/{id} */
    @GetMapping("/{id}")
    public ResponseEntity<<Entidad>Response> getById(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID id) {
        return ResponseEntity.ok(service.getById(tenantId, id));
    }

    /** PATCH /api/v1/<recurso>/{id} */
    @PatchMapping("/{id}")
    public ResponseEntity<<Entidad>Response> update(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId,
            @PathVariable UUID id,
            @Valid @RequestBody <Entidad>UpdateRequest request) {
        return ResponseEntity.ok(service.update(tenantId, id, request));
    }

    /** DELETE /api/v1/<recurso>/{id} */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId,
            @PathVariable UUID id) {
        service.delete(tenantId, id);
        return ResponseEntity.noContent().build();
    }
}
```

---

## 12. BusinessException — añadir errores del módulo

Agregar los factory methods al `BusinessException.java` existente en
`com.nexore.core.module.tenant.application.exception`:

```java
// Códigos: NXC-<MODULO>-XXXX
// TEN=tenant, USR=user, ROL=rol, MNU=menu, CMP=component, ELM=element, PRM=permission
// Nuevo módulo: usar sigla de 3 letras propia, ej. NXC-PRJ-0001

public static BusinessException <moduloNotFound>() {
    return new BusinessException("NXC-XXX-0001", "<Entidad> not found.", HttpStatus.NOT_FOUND);
}

public static BusinessException <moduloNameDuplicated>(String name) {
    return new BusinessException("NXC-XXX-0002",
            "Name '" + name + "' already exists in this tenant.", HttpStatus.CONFLICT);
}
```

---

## 13. Convenciones generales

| Tema | Regla |
|---|---|
| Transacciones | `@Transactional` en service, `readOnly = true` para consultas |
| Paginación | Reutilizar `PageResponse<T>` de `com.nexore.core.module.tenant.application.dto.response` |
| Soft delete | Siempre `deletedAt = OffsetDateTime.now()`, nunca `delete()` físico en registros de negocio |
| Multi-tenant | Todo query incluye `tenantId` en el filtro |
| IDs | `UUID` en dominio y API; `GenerationType.UUID` en JPA |
| Fechas | `OffsetDateTime`, nunca `LocalDateTime` |
| Enums PostgreSQL | `@JdbcType(PostgreSQLEnumJdbcType.class)` + `columnDefinition = "schema.tipo"` |
| Headers auth | `X-Tenant-Id`, `X-Actor-Id`, `X-Is-Tenant-Admin` (temporales hasta JWT) |
| Respuesta 201 | Siempre devolver `Location` header con `ServletUriComponentsBuilder` |
| Respuesta 204 | DELETE / suspend / activate devuelven `ResponseEntity<Void>.noContent()` |
| PATCH vs PUT | Usar `PATCH` para actualizaciones parciales, `PUT` para reemplazo completo |
| Lombok | `@RequiredArgsConstructor` en services y controllers; `@Builder` en modelos |
| Schemas BD | Usar `nxc_tenant`, `nxc_auth`, o crear nuevo `nxc_<nombre>` si es módulo independiente |
