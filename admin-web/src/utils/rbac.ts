export type AdminRole = 'super_admin' | 'admin' | 'safety_officer' | 'support_lead';

export type AdminCapability =
  | 'MANAGE_PLATFORM_SETTINGS'
  | 'MANAGE_FORCE_REFUNDS'
  | 'MANAGE_SOS_INCIDENTS'
  | 'MANAGE_DRIVER_SUSPENSION'
  | 'VIEW_DISPUTES'
  | 'MANAGE_VERIFICATIONS'
  | 'MANAGE_RIDES'
  | 'VIEW_AUDIT_LOGS'
  | 'VIEW_SYSTEM_HEALTH';

/**
 * Authoritative role-to-capability matrix strictly mapped to backend RBAC rules.
 *
 * Backend mapping:
 * - /config PATCH: super_admin, safety_officer (and admin via super fallback)
 * - /bookings/:id/force-refund: super_admin, safety_officer (and admin via super fallback)
 * - /users/:id/suspend: super_admin, safety_officer (and admin via super fallback)
 * - Emergency SOS Console: super_admin, safety_officer (and admin)
 * - support_lead: customer support role; restricted from changing platform config, force-refunds, and driver suspensions.
 */
export const ROLE_CAPABILITIES: Record<AdminRole, readonly AdminCapability[]> = {
  super_admin: [
    'MANAGE_PLATFORM_SETTINGS',
    'MANAGE_FORCE_REFUNDS',
    'MANAGE_SOS_INCIDENTS',
    'MANAGE_DRIVER_SUSPENSION',
    'VIEW_DISPUTES',
    'MANAGE_VERIFICATIONS',
    'MANAGE_RIDES',
    'VIEW_AUDIT_LOGS',
    'VIEW_SYSTEM_HEALTH',
  ],
  admin: [
    'MANAGE_PLATFORM_SETTINGS',
    'MANAGE_FORCE_REFUNDS',
    'MANAGE_SOS_INCIDENTS',
    'MANAGE_DRIVER_SUSPENSION',
    'VIEW_DISPUTES',
    'MANAGE_VERIFICATIONS',
    'MANAGE_RIDES',
    'VIEW_AUDIT_LOGS',
    'VIEW_SYSTEM_HEALTH',
  ],
  safety_officer: [
    'MANAGE_PLATFORM_SETTINGS',
    'MANAGE_FORCE_REFUNDS',
    'MANAGE_SOS_INCIDENTS',
    'MANAGE_DRIVER_SUSPENSION',
    'VIEW_DISPUTES',
    'MANAGE_VERIFICATIONS',
    'MANAGE_RIDES',
    'VIEW_AUDIT_LOGS',
  ],
  support_lead: [
    'VIEW_DISPUTES',
    'MANAGE_VERIFICATIONS',
    'MANAGE_RIDES',
  ],
} as const;

export function hasCapability(role: string | undefined | null, capability: AdminCapability): boolean {
  if (!role) return false;
  const normalized = role.toLowerCase().trim() as AdminRole;
  const caps = ROLE_CAPABILITIES[normalized];
  if (!caps) return false;
  return caps.includes(capability);
}

export function isTabAuthorized(tabKey: string, role: string | undefined | null): boolean {
  if (!role) return false;

  switch (tabKey) {
    case 'platform':
      return hasCapability(role, 'MANAGE_PLATFORM_SETTINGS');
    case 'bookings':
      return hasCapability(role, 'VIEW_DISPUTES');
    case 'settings':
      return hasCapability(role, 'VIEW_SYSTEM_HEALTH');
    case 'audit':
      return hasCapability(role, 'VIEW_AUDIT_LOGS');
    default:
      // 'overview', 'verifications', 'rides', 'reports', 'users', 'monetization'
      return true;
  }
}
