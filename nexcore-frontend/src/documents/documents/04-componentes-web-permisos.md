# 04 - Componentes Web y Permisos — NexCore

## Conceptos del Sistema de Permisos

NexCore implementa un sistema de permisos basado en **componentes web**, con tres niveles de acceso:

| Nivel | Comportamiento en UI |
|-------|----------------------|
| `execute` | Se muestra y el usuario puede interactuar con él |
| `view` | Se muestra pero desactivado (solo lectura) |
| `hidden` | No se muestra |

### Tipos de componentes

**Componente de menú** — Representa una opción de navegación visible en alguna zona de la aplicación (`sidebar`, `profile`, `navbar`, `footer`). Se registra en `nxc_menu.components` y también en `nxc_menu.menu_items`.

- Si el ítem de menú es de tipo `ITEM` → enlace simple, sin hijos.
- Si el ítem de menú es de tipo `GROUP` → agrupa hijos. Sus submenús son **elements** del componente padre en `nxc_menu.component_elements`. Esto permite aplicar permisos individuales a cada hijo vía `nxc_menu.element_permissions`.

**Componente web (no menú)** — Representa cualquier módulo de UI que no es un menú: una tabla, una sección de página, un panel de configuración, etc. Se registra solo en `nxc_menu.components`. Puede tener elements (botones, tabs, campos) en `nxc_menu.component_elements` para permisos más granulares.

### Cómo fluyen los permisos

```
Login → /api/v1/me/profile
         ├── menus[]           → qué ítems de navegación se muestran y con qué acceso
         └── permissions[]     → acceso a componentes web y sus elements
```

Ejemplo de respuesta real del perfil (usuario con rol EDITOR):

```json
{
  "menus": [
    {
      "access": "execute",
      "children": [],
      "icon": "dashboard",
      "icon_type": "tabler",
      "id": "5f91d75e-29b3-4596-a106-8c60235d46e9",
      "item_type": "ITEM",
      "location": "sidebar",
      "name": "Dashboard",
      "order_index": 10,
      "route": "/dashboard",
      "title": "Dashboard"
    },
    {
      "access": "execute",
      "children": [
        { "access": "execute", "name": "Profile",  "location": "profile", "order_index": 10, "route": "/profile" },
        { "access": "hidden",  "name": "Settings", "location": "profile", "order_index": 20, "route": "/settings" },
        { "access": "execute", "name": "Logout",   "location": "profile", "order_index": 30, "route": "/auth/login" }
      ],
      "icon": "user-circle",
      "icon_type": "tabler",
      "id": "82b9620d-6f06-43e0-8b9d-e6fd3f073a8e",
      "item_type": "GROUP",
      "location": "profile",
      "name": "ProfileMenu",
      "order_index": 10,
      "route": null,
      "title": "Profile Menu"
    },
    {
      "access": "hidden",
      "children": [
        { "access": "hidden", "name": "User",     "location": "sidebar", "route": "/users" },
        { "access": "hidden", "name": "Permisos", "location": "sidebar", "route": "/permissions" }
      ],
      "icon": "shield",
      "icon_type": "tabler",
      "item_type": "GROUP",
      "location": "sidebar",
      "name": "Admin",
      "order_index": 20,
      "route": null,
      "title": "Administración"
    }
  ],
  "permissions": [
    {
      "access": "hidden",
      "component": "admin-panel",
      "elements": [
        { "access": "hidden", "element_key": "permissions" },
        { "access": "hidden", "element_key": "user" }
      ],
      "route": null
    },
    {
      "access": "execute",
      "component": "crm",
      "elements": [],
      "route": "/crm"
    },
    {
      "access": "execute",
      "component": "profile-menu",
      "elements": [
        { "access": "execute", "element_key": "logout" },
        { "access": "execute", "element_key": "profile" },
        { "access": "hidden",  "element_key": "settings" }
      ],
      "route": null
    }
  ]
}
```

**Puntos clave:**
- `menus` controla la **navegación visible**. El campo `location` determina dónde se renderiza (`sidebar`, `profile`, `navbar`, `footer`). El frontend hace el match automáticamente con la respuesta del login.
- `permissions` controla el **acceso a componentes web** y sus elements. El frontend consume esto para mostrar/ocultar botones, secciones y otros elementos de UI.
- Los hijos de un GROUP (`children`) también aparecen en `permissions[].elements` del componente padre, lo que permite permisos granulares por hijo.

---

## Tablas involucradas (schema `nxc_menu`)

| Tabla | Propósito |
|-------|-----------|
| `nxc_menu.components` | Registro de todos los componentes (menú y no-menú) |
| `nxc_menu.menu_items` | Árbol de navegación; apunta a un `component_id` |
| `nxc_menu.component_permissions` | Permiso de un rol sobre un componente completo |
| `nxc_menu.component_elements` | Elements granulares dentro de un componente |
| `nxc_menu.element_permissions` | Permiso de un rol sobre un element específico |

---

## Script A — Crear menú ITEM simple

Un ítem de menú simple (sin hijos) que apunta a una ruta.

### A.1 Variables — completar antes de ejecutar

```sql
-- ============================================================
-- VARIABLES — rellenar como si fuera un formulario
-- ============================================================
DO $$ DECLARE

  -- TENANT
  v_tenant_id   UUID := '00000000-0000-0000-0000-000000000002';  -- ID del tenant

  -- USUARIO que ejecuta el script
  v_created_by  UUID := '00000000-0000-0000-0001-000000000001';  -- UUID del admin

  -- COMPONENTE (se creará si no existe)
  v_module_key  TEXT := 'crm';                -- Clave única del componente (kebab-case, sin espacios)
  v_comp_name   TEXT := 'CRM';                -- Nombre legible del componente
  v_comp_route  TEXT := '/crm';               -- Ruta de la página (o NULL si no aplica)
  v_comp_desc   TEXT := 'Módulo de CRM';      -- Descripción corta
  v_is_system   BOOLEAN := FALSE;             -- TRUE solo para componentes del sistema NexCore

  -- MENÚ
  v_menu_name       TEXT    := 'CRM';         -- Identificador técnico del ítem (PascalCase)
  v_menu_title      TEXT    := 'CRM';         -- Texto que ve el usuario
  v_menu_icon       TEXT    := 'users';       -- Nombre del ícono (tabler icons)
  v_menu_icon_type  TEXT    := 'tabler';      -- Librería: tabler | material | custom
  v_menu_route      TEXT    := '/crm';        -- Ruta de navegación
  v_menu_location   TEXT    := 'sidebar';     -- sidebar | profile | navbar | footer
  v_menu_order      INTEGER := 30;            -- Orden de aparición (10, 20, 30…)
  v_default_access  TEXT    := 'HIDDEN';      -- Acceso por defecto si no hay permiso explícito

  -- ROLE al que se le asigna el permiso de componente
  v_role_name   TEXT := 'EDITOR';             -- Nombre del rol
  v_comp_access TEXT := 'EXECUTE';            -- EXECUTE | VIEW | HIDDEN

  -- Variables internas (no modificar)
  v_comp_id   UUID;
  v_role_id   UUID;

BEGIN

  -- ============================================================
  -- PASO 1: Crear o reutilizar el componente
  -- ============================================================
  SELECT id INTO v_comp_id
  FROM nxc_menu.components
  WHERE module_key = v_module_key AND tenant_id = v_tenant_id AND deleted_at IS NULL;

  IF v_comp_id IS NULL THEN
    INSERT INTO nxc_menu.components
      (tenant_id, module_key, name, route, description, is_system, created_by, created_at, updated_at, version)
    VALUES
      (v_tenant_id, v_module_key, v_comp_name, v_comp_route, v_comp_desc, v_is_system, v_created_by, NOW(), NOW(), 0)
    RETURNING id INTO v_comp_id;
    RAISE NOTICE 'Componente creado: % (%)', v_module_key, v_comp_id;
  ELSE
    RAISE NOTICE 'Componente ya existe: % (%)', v_module_key, v_comp_id;
  END IF;

  -- ============================================================
  -- PASO 2: Crear el ítem de menú
  -- ============================================================
  INSERT INTO nxc_menu.menu_items
    (tenant_id, component_id, parent_id, name, title, icon, icon_type,
     route, location, item_type, order_index, is_visible, is_system,
     default_access, created_by, created_at, updated_at, version)
  VALUES
    (v_tenant_id, v_comp_id, NULL, v_menu_name, v_menu_title, v_menu_icon, v_menu_icon_type,
     v_menu_route, v_menu_location, 'ITEM', v_menu_order, TRUE, FALSE,
     v_default_access::nxc_menu.access_level, v_created_by, NOW(), NOW(), 0);
  RAISE NOTICE 'Menú ITEM creado: %', v_menu_name;

  -- ============================================================
  -- PASO 3: Asignar permiso de componente al rol
  -- ============================================================
  SELECT id INTO v_role_id FROM nxc_tenant.roles
  WHERE name = v_role_name AND tenant_id = v_tenant_id AND deleted_at IS NULL;

  IF v_role_id IS NULL THEN
    RAISE EXCEPTION 'Rol no encontrado: %', v_role_name;
  END IF;

  INSERT INTO nxc_menu.component_permissions
    (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
  VALUES
    (v_tenant_id, v_role_id, v_comp_id, v_comp_access::nxc_menu.access_level, v_created_by, NOW(), NOW())
  ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE
    SET access = EXCLUDED.access, updated_at = NOW();
  RAISE NOTICE 'Permiso de componente asignado: % → % [%]', v_role_name, v_module_key, v_comp_access;

END $$;
```

### A.2 Script de eliminación (rollback)

```sql
-- ============================================================
-- ROLLBACK Script A — Menú ITEM simple
-- Ajustar variables antes de ejecutar
-- ============================================================
DO $$ DECLARE
  v_tenant_id  UUID := '00000000-0000-0000-0000-000000000002';
  v_module_key TEXT := 'crm';
  v_menu_name  TEXT := 'CRM';
  v_comp_id    UUID;
BEGIN
  SELECT id INTO v_comp_id FROM nxc_menu.components
  WHERE module_key = v_module_key AND tenant_id = v_tenant_id AND deleted_at IS NULL;

  -- Eliminar permisos de componente
  DELETE FROM nxc_menu.component_permissions WHERE component_id = v_comp_id AND tenant_id = v_tenant_id;

  -- Soft-delete del ítem de menú
  UPDATE nxc_menu.menu_items
  SET deleted_at = NOW()
  WHERE name = v_menu_name AND tenant_id = v_tenant_id AND deleted_at IS NULL;

  -- Soft-delete del componente
  UPDATE nxc_menu.components
  SET deleted_at = NOW()
  WHERE id = v_comp_id;

  RAISE NOTICE 'Rollback completado para componente %', v_module_key;
END $$;
```

---

## Script B — Crear menú GROUP con hijos (elements)

Un GROUP agrupa submenús. Cada hijo es a la vez un `menu_item` hijo y un `component_element` del componente padre, lo que permite aplicar permisos individuales por hijo.

### B.1 Variables — completar antes de ejecutar

```sql
-- ============================================================
-- VARIABLES — rellenar como si fuera un formulario
-- ============================================================
DO $$ DECLARE

  -- TENANT y USUARIO
  v_tenant_id   UUID := '00000000-0000-0000-0000-000000000002';
  v_created_by  UUID := '00000000-0000-0000-0001-000000000001';

  -- COMPONENTE DEL GRUPO (el padre)
  v_module_key  TEXT    := 'admin-panel';
  v_comp_name   TEXT    := 'Admin Panel';
  v_comp_desc   TEXT    := 'Panel de administración con acceso a usuarios y permisos';
  v_is_system   BOOLEAN := FALSE;

  -- MENÚ GRUPO (el padre)
  v_group_name      TEXT    := 'Admin';
  v_group_title     TEXT    := 'Administración';
  v_group_icon      TEXT    := 'shield';
  v_group_icon_type TEXT    := 'tabler';
  v_group_location  TEXT    := 'sidebar';    -- sidebar | profile | navbar | footer
  v_group_order     INTEGER := 20;
  v_group_access    TEXT    := 'HIDDEN';     -- Acceso por defecto del grupo

  -- HIJOS DEL GRUPO
  -- Cada hijo: (nombre_tecnico, título_visible, ícono, ruta, order, element_key, default_access)
  -- element_key = LOWER(name), debe coincidir con LOWER(menu_item.name) para que los permisos funcionen

  -- ROLE al que se le asigna permisos
  v_role_name        TEXT := 'EDITOR';
  v_group_comp_access TEXT := 'HIDDEN';   -- Acceso al componente grupo

  -- Variables internas (no modificar)
  v_comp_id    UUID;
  v_group_id   UUID;
  v_role_id    UUID;
  v_child_id   UUID;
  v_elem_id    UUID;

BEGIN

  -- ============================================================
  -- PASO 1: Crear componente del grupo
  -- ============================================================
  SELECT id INTO v_comp_id
  FROM nxc_menu.components
  WHERE module_key = v_module_key AND tenant_id = v_tenant_id AND deleted_at IS NULL;

  IF v_comp_id IS NULL THEN
    INSERT INTO nxc_menu.components
      (tenant_id, module_key, name, route, description, is_system, created_by, created_at, updated_at, version)
    VALUES
      (v_tenant_id, v_module_key, v_comp_name, NULL, v_comp_desc, v_is_system, v_created_by, NOW(), NOW(), 0)
    RETURNING id INTO v_comp_id;
    RAISE NOTICE 'Componente grupo creado: % (%)', v_module_key, v_comp_id;
  ELSE
    RAISE NOTICE 'Componente grupo ya existe: % (%)', v_module_key, v_comp_id;
  END IF;

  -- ============================================================
  -- PASO 2: Crear el ítem de menú GROUP (el padre)
  -- ============================================================
  INSERT INTO nxc_menu.menu_items
    (tenant_id, component_id, parent_id, name, title, icon, icon_type,
     route, location, item_type, order_index, is_visible, is_system,
     default_access, created_by, created_at, updated_at, version)
  VALUES
    (v_tenant_id, v_comp_id, NULL, v_group_name, v_group_title, v_group_icon, v_group_icon_type,
     NULL, v_group_location, 'GROUP', v_group_order, TRUE, FALSE,
     v_group_access::nxc_menu.access_level, v_created_by, NOW(), NOW(), 0)
  RETURNING id INTO v_group_id;
  RAISE NOTICE 'Menú GROUP creado: % (%)', v_group_name, v_group_id;

  -- ============================================================
  -- PASO 3: Crear hijos del grupo
  -- Por cada hijo: menu_item + component_element
  --
  -- Estructura: (name, title, icon, route, order_index, default_access)
  -- ============================================================

  -- Hijo 1: User
  INSERT INTO nxc_menu.menu_items
    (tenant_id, component_id, parent_id, name, title, icon, icon_type,
     route, location, item_type, order_index, is_visible, is_system,
     default_access, created_by, created_at, updated_at, version)
  VALUES
    (v_tenant_id, v_comp_id, v_group_id,
     'User',       -- name (IMPORTANTE: LOWER(name) = element_key)
     'Usuarios',   -- title
     'users',      -- icon
     'tabler',
     '/users',     -- route
     v_group_location, 'ITEM', 10, TRUE, FALSE,
     'HIDDEN'::nxc_menu.access_level, v_created_by, NOW(), NOW(), 0)
  RETURNING id INTO v_child_id;

  INSERT INTO nxc_menu.component_elements
    (tenant_id, component_id, element_key, label, element_type, created_at, updated_at, version)
  VALUES
    (v_tenant_id, v_comp_id,
     'user',          -- element_key = LOWER('User')
     'Usuarios',
     'ITEM', NOW(), NOW(), 0)
  RETURNING id INTO v_elem_id;
  RAISE NOTICE 'Hijo "User" creado: menu_item=%, element=%', v_child_id, v_elem_id;

  -- Hijo 2: Permisos
  INSERT INTO nxc_menu.menu_items
    (tenant_id, component_id, parent_id, name, title, icon, icon_type,
     route, location, item_type, order_index, is_visible, is_system,
     default_access, created_by, created_at, updated_at, version)
  VALUES
    (v_tenant_id, v_comp_id, v_group_id,
     'Permisos',
     'Permisos',
     'lock',
     'tabler',
     '/permissions',
     v_group_location, 'ITEM', 20, TRUE, FALSE,
     'HIDDEN'::nxc_menu.access_level, v_created_by, NOW(), NOW(), 0)
  RETURNING id INTO v_child_id;

  INSERT INTO nxc_menu.component_elements
    (tenant_id, component_id, element_key, label, element_type, created_at, updated_at, version)
  VALUES
    (v_tenant_id, v_comp_id,
     'permisos',      -- element_key = LOWER('Permisos')
     'Permisos',
     'ITEM', NOW(), NOW(), 0)
  RETURNING id INTO v_elem_id;
  RAISE NOTICE 'Hijo "Permisos" creado: menu_item=%, element=%', v_child_id, v_elem_id;

  -- ============================================================
  -- PASO 4: Asignar permiso de componente al rol
  -- ============================================================
  SELECT id INTO v_role_id FROM nxc_tenant.roles
  WHERE name = v_role_name AND tenant_id = v_tenant_id AND deleted_at IS NULL;

  IF v_role_id IS NULL THEN
    RAISE EXCEPTION 'Rol no encontrado: %', v_role_name;
  END IF;

  INSERT INTO nxc_menu.component_permissions
    (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
  VALUES
    (v_tenant_id, v_role_id, v_comp_id, v_group_comp_access::nxc_menu.access_level, v_created_by, NOW(), NOW())
  ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE
    SET access = EXCLUDED.access, updated_at = NOW();

  -- ============================================================
  -- PASO 5: Asignar permisos de elements al rol
  -- ============================================================
  INSERT INTO nxc_menu.element_permissions
    (tenant_id, role_id, element_id, access, created_by, created_at, updated_at)
  SELECT
    v_tenant_id, v_role_id, ce.id,
    'HIDDEN'::nxc_menu.access_level,  -- acceso por defecto a todos los hijos
    v_created_by, NOW(), NOW()
  FROM nxc_menu.component_elements ce
  WHERE ce.component_id = v_comp_id AND ce.tenant_id = v_tenant_id AND ce.deleted_at IS NULL
  ON CONFLICT (tenant_id, role_id, element_id) DO UPDATE
    SET access = EXCLUDED.access, updated_at = NOW();

  RAISE NOTICE 'Permisos de grupo y elements asignados a rol %', v_role_name;

END $$;
```

### B.2 Script para cambiar el permiso de un hijo específico

Usar después del Script B.1 para ajustar el acceso de un hijo en particular.

```sql
-- ============================================================
-- VARIABLES — cambiar acceso de un element hijo del grupo
-- ============================================================
DO $$ DECLARE
  v_tenant_id   UUID := '00000000-0000-0000-0000-000000000002';
  v_created_by  UUID := '00000000-0000-0000-0001-000000000001';
  v_module_key  TEXT := 'admin-panel';  -- Componente padre del grupo
  v_element_key TEXT := 'user';         -- LOWER(name) del hijo que quiero modificar
  v_role_name   TEXT := 'EDITOR';
  v_new_access  TEXT := 'EXECUTE';      -- EXECUTE | VIEW | HIDDEN

  v_comp_id  UUID;
  v_elem_id  UUID;
  v_role_id  UUID;
BEGIN
  SELECT id INTO v_comp_id FROM nxc_menu.components
  WHERE module_key = v_module_key AND tenant_id = v_tenant_id AND deleted_at IS NULL;

  SELECT id INTO v_elem_id FROM nxc_menu.component_elements
  WHERE component_id = v_comp_id AND element_key = v_element_key AND tenant_id = v_tenant_id AND deleted_at IS NULL;

  SELECT id INTO v_role_id FROM nxc_tenant.roles
  WHERE name = v_role_name AND tenant_id = v_tenant_id AND deleted_at IS NULL;

  INSERT INTO nxc_menu.element_permissions
    (tenant_id, role_id, element_id, access, created_by, created_at, updated_at)
  VALUES
    (v_tenant_id, v_role_id, v_elem_id, v_new_access::nxc_menu.access_level, v_created_by, NOW(), NOW())
  ON CONFLICT (tenant_id, role_id, element_id) DO UPDATE
    SET access = EXCLUDED.access, updated_at = NOW();

  RAISE NOTICE 'Element "%" del grupo "%" → acceso [%] para rol [%]',
    v_element_key, v_module_key, v_new_access, v_role_name;
END $$;
```

### B.3 Script de eliminación del GROUP (rollback)

```sql
-- ============================================================
-- ROLLBACK Script B — Menú GROUP con hijos
-- ============================================================
DO $$ DECLARE
  v_tenant_id  UUID := '00000000-0000-0000-0000-000000000002';
  v_module_key TEXT := 'admin-panel';
  v_group_name TEXT := 'Admin';
  v_comp_id    UUID;
BEGIN
  SELECT id INTO v_comp_id FROM nxc_menu.components
  WHERE module_key = v_module_key AND tenant_id = v_tenant_id AND deleted_at IS NULL;

  -- Eliminar permisos de elements
  DELETE FROM nxc_menu.element_permissions
  WHERE element_id IN (
    SELECT id FROM nxc_menu.component_elements
    WHERE component_id = v_comp_id AND tenant_id = v_tenant_id
  ) AND tenant_id = v_tenant_id;

  -- Soft-delete elements
  UPDATE nxc_menu.component_elements
  SET deleted_at = NOW()
  WHERE component_id = v_comp_id AND tenant_id = v_tenant_id AND deleted_at IS NULL;

  -- Eliminar permisos de componente
  DELETE FROM nxc_menu.component_permissions
  WHERE component_id = v_comp_id AND tenant_id = v_tenant_id;

  -- Soft-delete hijos del grupo
  UPDATE nxc_menu.menu_items
  SET deleted_at = NOW()
  WHERE parent_id IN (
    SELECT id FROM nxc_menu.menu_items
    WHERE name = v_group_name AND tenant_id = v_tenant_id AND deleted_at IS NULL
  ) AND tenant_id = v_tenant_id;

  -- Soft-delete del grupo
  UPDATE nxc_menu.menu_items
  SET deleted_at = NOW()
  WHERE name = v_group_name AND tenant_id = v_tenant_id AND deleted_at IS NULL;

  -- Soft-delete del componente
  UPDATE nxc_menu.components
  SET deleted_at = NOW()
  WHERE id = v_comp_id;

  RAISE NOTICE 'Rollback GROUP completado: %', v_group_name;
END $$;
```

---

## Script C — Crear componente web (no es menú)

Un componente que no forma parte de la navegación: una tabla de proyectos, un panel de configuración, un formulario inline, etc.

### C.1 Variables — completar antes de ejecutar

```sql
-- ============================================================
-- VARIABLES — rellenar como si fuera un formulario
-- ============================================================
DO $$ DECLARE

  -- TENANT y USUARIO
  v_tenant_id   UUID := '00000000-0000-0000-0000-000000000002';
  v_created_by  UUID := '00000000-0000-0000-0001-000000000001';

  -- COMPONENTE
  v_module_key  TEXT    := 'projects-table';   -- Clave única (kebab-case)
  v_comp_name   TEXT    := 'Projects Table';   -- Nombre legible
  v_comp_route  TEXT    := '/projects';        -- Ruta donde vive (o NULL)
  v_comp_desc   TEXT    := 'Tabla de proyectos del módulo CRM';
  v_is_system   BOOLEAN := FALSE;

  -- ELEMENTS DEL COMPONENTE (botones, tabs, secciones, campos)
  -- Formato: (element_key, label, element_type)
  -- element_type: BUTTON | TAB | FIELD | SECTION | ACTION

  -- ROLE al que se le asigna permiso
  v_role_name        TEXT := 'EDITOR';
  v_comp_access      TEXT := 'EXECUTE';  -- EXECUTE | VIEW | HIDDEN

  -- Variables internas (no modificar)
  v_comp_id  UUID;
  v_role_id  UUID;
  v_elem_id  UUID;

BEGIN

  -- ============================================================
  -- PASO 1: Crear componente
  -- ============================================================
  SELECT id INTO v_comp_id
  FROM nxc_menu.components
  WHERE module_key = v_module_key AND tenant_id = v_tenant_id AND deleted_at IS NULL;

  IF v_comp_id IS NULL THEN
    INSERT INTO nxc_menu.components
      (tenant_id, module_key, name, route, description, is_system, created_by, created_at, updated_at, version)
    VALUES
      (v_tenant_id, v_module_key, v_comp_name, v_comp_route, v_comp_desc, v_is_system, v_created_by, NOW(), NOW(), 0)
    RETURNING id INTO v_comp_id;
    RAISE NOTICE 'Componente creado: % (%)', v_module_key, v_comp_id;
  ELSE
    RAISE NOTICE 'Componente ya existe: % (%)', v_module_key, v_comp_id;
  END IF;

  -- ============================================================
  -- PASO 2: Crear elements del componente
  -- Agregar o quitar bloques según los elementos que tenga el componente
  -- ============================================================

  -- Element: botón crear proyecto
  INSERT INTO nxc_menu.component_elements
    (tenant_id, component_id, element_key, label, element_type, created_at, updated_at, version)
  VALUES
    (v_tenant_id, v_comp_id, 'btn-create-project', 'Crear Proyecto', 'BUTTON', NOW(), NOW(), 0)
  ON CONFLICT (tenant_id, component_id, element_key) DO NOTHING
  RETURNING id INTO v_elem_id;
  RAISE NOTICE 'Element creado: btn-create-project (%)', v_elem_id;

  -- Element: botón eliminar proyecto
  INSERT INTO nxc_menu.component_elements
    (tenant_id, component_id, element_key, label, element_type, created_at, updated_at, version)
  VALUES
    (v_tenant_id, v_comp_id, 'btn-delete-project', 'Eliminar Proyecto', 'BUTTON', NOW(), NOW(), 0)
  ON CONFLICT (tenant_id, component_id, element_key) DO NOTHING;

  -- Element: tab de detalle
  INSERT INTO nxc_menu.component_elements
    (tenant_id, component_id, element_key, label, element_type, created_at, updated_at, version)
  VALUES
    (v_tenant_id, v_comp_id, 'tab-detail', 'Detalle', 'TAB', NOW(), NOW(), 0)
  ON CONFLICT (tenant_id, component_id, element_key) DO NOTHING;

  -- Element: campo de presupuesto
  INSERT INTO nxc_menu.component_elements
    (tenant_id, component_id, element_key, label, element_type, created_at, updated_at, version)
  VALUES
    (v_tenant_id, v_comp_id, 'field-budget', 'Presupuesto', 'FIELD', NOW(), NOW(), 0)
  ON CONFLICT (tenant_id, component_id, element_key) DO NOTHING;

  -- ============================================================
  -- PASO 3: Asignar permiso de componente al rol
  -- ============================================================
  SELECT id INTO v_role_id FROM nxc_tenant.roles
  WHERE name = v_role_name AND tenant_id = v_tenant_id AND deleted_at IS NULL;

  IF v_role_id IS NULL THEN
    RAISE EXCEPTION 'Rol no encontrado: %', v_role_name;
  END IF;

  INSERT INTO nxc_menu.component_permissions
    (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
  VALUES
    (v_tenant_id, v_role_id, v_comp_id, v_comp_access::nxc_menu.access_level, v_created_by, NOW(), NOW())
  ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE
    SET access = EXCLUDED.access, updated_at = NOW();
  RAISE NOTICE 'Permiso de componente: % → % [%]', v_role_name, v_module_key, v_comp_access;

  -- ============================================================
  -- PASO 4: Asignar permisos de elements al rol
  -- Ajustar acceso por element_key según necesidad
  -- ============================================================

  -- btn-create-project → EXECUTE para EDITOR
  INSERT INTO nxc_menu.element_permissions
    (tenant_id, role_id, element_id, access, created_by, created_at, updated_at)
  SELECT v_tenant_id, v_role_id, ce.id, 'EXECUTE'::nxc_menu.access_level, v_created_by, NOW(), NOW()
  FROM nxc_menu.component_elements ce
  WHERE ce.component_id = v_comp_id AND ce.element_key = 'btn-create-project' AND ce.tenant_id = v_tenant_id
  ON CONFLICT (tenant_id, role_id, element_id) DO UPDATE SET access = EXCLUDED.access, updated_at = NOW();

  -- btn-delete-project → HIDDEN para EDITOR
  INSERT INTO nxc_menu.element_permissions
    (tenant_id, role_id, element_id, access, created_by, created_at, updated_at)
  SELECT v_tenant_id, v_role_id, ce.id, 'HIDDEN'::nxc_menu.access_level, v_created_by, NOW(), NOW()
  FROM nxc_menu.component_elements ce
  WHERE ce.component_id = v_comp_id AND ce.element_key = 'btn-delete-project' AND ce.tenant_id = v_tenant_id
  ON CONFLICT (tenant_id, role_id, element_id) DO UPDATE SET access = EXCLUDED.access, updated_at = NOW();

  -- tab-detail → VIEW para EDITOR
  INSERT INTO nxc_menu.element_permissions
    (tenant_id, role_id, element_id, access, created_by, created_at, updated_at)
  SELECT v_tenant_id, v_role_id, ce.id, 'VIEW'::nxc_menu.access_level, v_created_by, NOW(), NOW()
  FROM nxc_menu.component_elements ce
  WHERE ce.component_id = v_comp_id AND ce.element_key = 'tab-detail' AND ce.tenant_id = v_tenant_id
  ON CONFLICT (tenant_id, role_id, element_id) DO UPDATE SET access = EXCLUDED.access, updated_at = NOW();

  -- field-budget → HIDDEN para EDITOR
  INSERT INTO nxc_menu.element_permissions
    (tenant_id, role_id, element_id, access, created_by, created_at, updated_at)
  SELECT v_tenant_id, v_role_id, ce.id, 'HIDDEN'::nxc_menu.access_level, v_created_by, NOW(), NOW()
  FROM nxc_menu.component_elements ce
  WHERE ce.component_id = v_comp_id AND ce.element_key = 'field-budget' AND ce.tenant_id = v_tenant_id
  ON CONFLICT (tenant_id, role_id, element_id) DO UPDATE SET access = EXCLUDED.access, updated_at = NOW();

  RAISE NOTICE 'Elements configurados para rol %', v_role_name;

END $$;
```

### C.2 Script de eliminación del componente web (rollback)

```sql
-- ============================================================
-- ROLLBACK Script C — Componente web (no menú)
-- ============================================================
DO $$ DECLARE
  v_tenant_id  UUID := '00000000-0000-0000-0000-000000000002';
  v_module_key TEXT := 'projects-table';
  v_comp_id    UUID;
BEGIN
  SELECT id INTO v_comp_id FROM nxc_menu.components
  WHERE module_key = v_module_key AND tenant_id = v_tenant_id AND deleted_at IS NULL;

  IF v_comp_id IS NULL THEN
    RAISE NOTICE 'Componente no encontrado: %', v_module_key;
    RETURN;
  END IF;

  -- Eliminar permisos de elements
  DELETE FROM nxc_menu.element_permissions
  WHERE element_id IN (
    SELECT id FROM nxc_menu.component_elements
    WHERE component_id = v_comp_id AND tenant_id = v_tenant_id
  ) AND tenant_id = v_tenant_id;

  -- Soft-delete elements
  UPDATE nxc_menu.component_elements
  SET deleted_at = NOW()
  WHERE component_id = v_comp_id AND tenant_id = v_tenant_id AND deleted_at IS NULL;

  -- Eliminar permisos de componente
  DELETE FROM nxc_menu.component_permissions
  WHERE component_id = v_comp_id AND tenant_id = v_tenant_id;

  -- Soft-delete componente
  UPDATE nxc_menu.components SET deleted_at = NOW() WHERE id = v_comp_id;

  RAISE NOTICE 'Rollback completado para componente %', v_module_key;
END $$;
```

---

## Script D — Consultas de verificación

Usar para validar que lo creado está correcto antes o después de ejecutar los scripts.

```sql
-- ============================================================
-- D.1 Ver todos los componentes de un tenant
-- ============================================================
SELECT
  c.module_key,
  c.name,
  c.route,
  c.is_system,
  (SELECT COUNT(*) FROM nxc_menu.component_elements ce
   WHERE ce.component_id = c.id AND ce.deleted_at IS NULL) AS elements_count
FROM nxc_menu.components c
WHERE c.tenant_id = '00000000-0000-0000-0000-000000000002'
  AND c.deleted_at IS NULL
ORDER BY c.module_key;

-- ============================================================
-- D.2 Ver menús de un tenant con su jerarquía
-- ============================================================
SELECT
  CASE WHEN mi.parent_id IS NULL THEN mi.name
       ELSE '  └─ ' || mi.name
  END AS menu,
  mi.item_type,
  mi.location,
  mi.route,
  mi.order_index,
  mi.default_access,
  c.module_key AS componente
FROM nxc_menu.menu_items mi
LEFT JOIN nxc_menu.components c ON c.id = mi.component_id
WHERE mi.tenant_id = '00000000-0000-0000-0000-000000000002'
  AND mi.deleted_at IS NULL
ORDER BY COALESCE(mi.parent_id::text, mi.id::text), mi.order_index;

-- ============================================================
-- D.3 Ver permisos de un rol sobre componentes y elements
-- ============================================================
SELECT
  r.name        AS rol,
  c.module_key  AS componente,
  cp.access     AS acceso_componente,
  ce.element_key,
  ce.label,
  ep.access     AS acceso_element
FROM nxc_menu.component_permissions cp
JOIN nxc_menu.components c ON c.id = cp.component_id
JOIN nxc_tenant.roles r ON r.id = cp.role_id
LEFT JOIN nxc_menu.component_elements ce
  ON ce.component_id = c.id AND ce.tenant_id = cp.tenant_id AND ce.deleted_at IS NULL
LEFT JOIN nxc_menu.element_permissions ep
  ON ep.element_id = ce.id AND ep.role_id = cp.role_id AND ep.tenant_id = cp.tenant_id
WHERE r.name = 'EDITOR'
  AND cp.tenant_id = '00000000-0000-0000-0000-000000000002'
ORDER BY c.module_key, ce.element_key;

-- ============================================================
-- D.4 Ver qué ve el usuario en el perfil (simula el endpoint /me/profile)
-- Usa la query de diagnóstico de menu_items
-- ============================================================
WITH params AS (
  SELECT
    '00000000-0000-0000-0000-000000000002'::UUID AS tenant_id,
    'EDITOR'::TEXT AS role_name
),
role_ctx AS (
  SELECT r.id AS role_id, r.name AS role_name
  FROM nxc_tenant.roles r
  JOIN params p ON p.tenant_id = r.tenant_id
  WHERE r.name = p.role_name AND r.deleted_at IS NULL
  LIMIT 1
)
SELECT
  mi.name,
  mi.item_type,
  mi.location,
  mi.route,
  mi.order_index,
  cp.access                              AS perm_componente,
  mi.default_access                      AS perm_defecto,
  COALESCE(cp.access, mi.default_access) AS acceso_efectivo,
  parent.name                            AS padre
FROM nxc_menu.menu_items mi
CROSS JOIN role_ctx rc
LEFT JOIN nxc_menu.component_permissions cp
  ON cp.component_id = mi.component_id
  AND cp.tenant_id = mi.tenant_id
  AND cp.role_id = rc.role_id
LEFT JOIN nxc_menu.menu_items parent ON parent.id = mi.parent_id
WHERE mi.tenant_id = (SELECT tenant_id FROM params)
  AND mi.deleted_at IS NULL
  AND mi.is_visible = TRUE
ORDER BY parent.name NULLS FIRST, mi.order_index;
```

---

## Reglas y convenciones

| Regla | Detalle |
|-------|---------|
| `module_key` | Siempre kebab-case: `projects-table`, `admin-panel`, `profile-menu` |
| `element_key` | Para hijos de GROUP: `LOWER(menu_item.name)`. Para elementos de componente web: `btn-crear-proyecto`, `tab-detalle`, `field-presupuesto` |
| `element_type` | `BUTTON` \| `TAB` \| `FIELD` \| `SECTION` \| `ACTION` \| `ITEM` (para hijos de GROUP) |
| `location` | `sidebar` \| `profile` \| `navbar` \| `footer` |
| `item_type` | `ITEM` para enlace simple, `GROUP` para grupo con hijos, `DIVIDER` para separador visual |
| `default_access` | Valor que toma el menú si no hay `component_permissions` para el rol. Usar `HIDDEN` por defecto |
| Soft-delete | Nunca `DELETE` directo en producción. Usar `UPDATE SET deleted_at = NOW()` |
| ON CONFLICT | Todos los `INSERT` de permisos usan `ON CONFLICT ... DO UPDATE` para ser idempotentes |

---

**Fecha:** Mayo 2026
**Proyecto:** NexCore
**Schema:** `nxc_menu` / `nxc_tenant`
