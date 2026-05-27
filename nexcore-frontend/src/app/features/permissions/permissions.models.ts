export type AccessLevel = 'hidden' | 'view' | 'execute';

export interface RoleOption {
  id: string;
  name: string;
}

export interface RoleElementPermission {
  elementId: string;
  elementKey: string;
  label: string;
  elementType: 'BUTTON' | 'FIELD' | 'TAB' | string;
  access: AccessLevel;
  inherited: boolean;
}

export interface RoleComponentPermission {
  componentId: string;
  moduleKey: string;
  name: string;
  route: string;
  access: AccessLevel;
  elements: RoleElementPermission[];
}

export interface RolePermissionMatrixResponse {
  roleId: string;
  roleName: string;
  tenantId: string;
  components: RoleComponentPermission[];
}

export interface ComponentPermissionState extends RoleComponentPermission {
  elements: ElementPermissionState[];
  expanded: boolean;
  dirty: boolean;
}

export interface ElementPermissionState extends RoleElementPermission {
  dirty: boolean;
}

// ── Mock data ──────────────────────────────────────────────────────────────

export const MOCK_ROLES: RoleOption[] = [
  { id: '00000000-0000-0000-0000-000000000001', name: 'TENANT_ADMIN' },
  { id: '00000000-0000-0000-0000-000000000010', name: 'EDITOR' },
  { id: '00000000-0000-0000-0000-000000000020', name: 'VIEWER' },
];

const MATRICES: Record<string, RolePermissionMatrixResponse> = {
  '00000000-0000-0000-0000-000000000001': {
    roleId: '00000000-0000-0000-0000-000000000001',
    roleName: 'TENANT_ADMIN',
    tenantId: '00000000-0000-0000-0000-000000000100',
    components: [
      {
        componentId: 'aaa00000-0000-0000-0000-000000000001',
        moduleKey: 'user-management',
        name: 'User Management',
        route: '/admin/users',
        access: 'execute',
        elements: [
          { elementId: 'eee00000-0000-0000-0000-000000000001', elementKey: 'btn-delete-user', label: 'Delete User', elementType: 'BUTTON', access: 'execute', inherited: true },
          { elementId: 'eee00000-0000-0000-0000-000000000002', elementKey: 'field-user-email', label: 'Email Address', elementType: 'FIELD', access: 'execute', inherited: true },
          { elementId: 'eee00000-0000-0000-0000-000000000003', elementKey: 'tab-activity-log', label: 'Activity Log', elementType: 'TAB', access: 'execute', inherited: true },
        ],
      },
      {
        componentId: 'aaa00000-0000-0000-0000-000000000002',
        moduleKey: 'tenant-billing',
        name: 'Tenant Billing',
        route: '/admin/tenants/billing',
        access: 'execute',
        elements: [],
      },
      {
        componentId: 'aaa00000-0000-0000-0000-000000000003',
        moduleKey: 'security-logs',
        name: 'Security Logs',
        route: '/admin/logs/security',
        access: 'execute',
        elements: [
          { elementId: 'eee00000-0000-0000-0000-000000000010', elementKey: 'btn-export-logs', label: 'Export Logs', elementType: 'BUTTON', access: 'execute', inherited: true },
        ],
      },
    ],
  },
  '00000000-0000-0000-0000-000000000010': {
    roleId: '00000000-0000-0000-0000-000000000010',
    roleName: 'EDITOR',
    tenantId: '00000000-0000-0000-0000-000000000100',
    components: [
      {
        componentId: 'aaa00000-0000-0000-0000-000000000001',
        moduleKey: 'user-management',
        name: 'User Management',
        route: '/admin/users',
        access: 'view',
        elements: [
          { elementId: 'eee00000-0000-0000-0000-000000000001', elementKey: 'btn-delete-user', label: 'Delete User', elementType: 'BUTTON', access: 'hidden', inherited: true },
          { elementId: 'eee00000-0000-0000-0000-000000000002', elementKey: 'field-user-email', label: 'Email Address', elementType: 'FIELD', access: 'view', inherited: false },
          { elementId: 'eee00000-0000-0000-0000-000000000003', elementKey: 'tab-activity-log', label: 'Activity Log', elementType: 'TAB', access: 'execute', inherited: false },
        ],
      },
      {
        componentId: 'aaa00000-0000-0000-0000-000000000002',
        moduleKey: 'tenant-billing',
        name: 'Tenant Billing',
        route: '/admin/tenants/billing',
        access: 'hidden',
        elements: [],
      },
      {
        componentId: 'aaa00000-0000-0000-0000-000000000003',
        moduleKey: 'security-logs',
        name: 'Security Logs',
        route: '/admin/logs/security',
        access: 'execute',
        elements: [
          { elementId: 'eee00000-0000-0000-0000-000000000010', elementKey: 'btn-export-logs', label: 'Export Logs', elementType: 'BUTTON', access: 'execute', inherited: true },
        ],
      },
    ],
  },
  '00000000-0000-0000-0000-000000000020': {
    roleId: '00000000-0000-0000-0000-000000000020',
    roleName: 'VIEWER',
    tenantId: '00000000-0000-0000-0000-000000000100',
    components: [
      {
        componentId: 'aaa00000-0000-0000-0000-000000000001',
        moduleKey: 'user-management',
        name: 'User Management',
        route: '/admin/users',
        access: 'view',
        elements: [
          { elementId: 'eee00000-0000-0000-0000-000000000001', elementKey: 'btn-delete-user', label: 'Delete User', elementType: 'BUTTON', access: 'hidden', inherited: false },
          { elementId: 'eee00000-0000-0000-0000-000000000002', elementKey: 'field-user-email', label: 'Email Address', elementType: 'FIELD', access: 'view', inherited: true },
          { elementId: 'eee00000-0000-0000-0000-000000000003', elementKey: 'tab-activity-log', label: 'Activity Log', elementType: 'TAB', access: 'hidden', inherited: false },
        ],
      },
      {
        componentId: 'aaa00000-0000-0000-0000-000000000002',
        moduleKey: 'tenant-billing',
        name: 'Tenant Billing',
        route: '/admin/tenants/billing',
        access: 'hidden',
        elements: [],
      },
      {
        componentId: 'aaa00000-0000-0000-0000-000000000003',
        moduleKey: 'security-logs',
        name: 'Security Logs',
        route: '/admin/logs/security',
        access: 'hidden',
        elements: [
          { elementId: 'eee00000-0000-0000-0000-000000000010', elementKey: 'btn-export-logs', label: 'Export Logs', elementType: 'BUTTON', access: 'hidden', inherited: true },
        ],
      },
    ],
  },
};

export function getMockMatrix(roleId: string): RolePermissionMatrixResponse {
  return MATRICES[roleId] ?? MATRICES['00000000-0000-0000-0000-000000000010'];
}
