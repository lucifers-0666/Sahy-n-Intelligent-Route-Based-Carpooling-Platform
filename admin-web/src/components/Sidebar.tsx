import React from 'react';
import {
  LayoutDashboard,
  FileCheck,
  Car,
  Bookmark,
  AlertTriangle,
  Users,
  Settings,
  IndianRupee,
  ScrollText,
  SlidersHorizontal,
  Scale,
  ShieldAlert,
  LifeBuoy,
  Activity,
  Radio,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { isTabAuthorized } from '../utils/rbac';

export type TabKey =
  | 'overview'
  | 'verifications'
  | 'rides'
  | 'bookings'
  | 'disputes'
  | 'fraud'
  | 'reports'
  | 'tickets'
  | 'users'
  | 'monetization'
  | 'audit'
  | 'operational'
  | 'platform'
  | 'settings';

interface SidebarProps {
  activeTab: TabKey;
  onSelectTab: (tab: TabKey) => void;
  pendingVerificationsCount?: number;
  pendingReportsCount?: number;
}

interface NavItem {
  key: TabKey;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  badge?: number | null;
  badgeColor?: string;
  group: 'ops' | 'biz' | 'admin';
}

export const Sidebar: React.FC<SidebarProps> = ({
  activeTab,
  onSelectTab,
  pendingVerificationsCount = 0,
  pendingReportsCount = 0,
}) => {
  const navItems: NavItem[] = [
    // Operations group
    {
      key: 'overview',
      label: 'Overview',
      icon: LayoutDashboard,
      badge: null,
      group: 'ops',
    },
    {
      key: 'verifications',
      label: 'Driver Verifications',
      icon: FileCheck,
      badge: pendingVerificationsCount > 0 ? pendingVerificationsCount : null,
      badgeColor: 'bg-amber-100 text-amber-900 border border-amber-300',
      group: 'ops',
    },
    {
      key: 'rides',
      label: 'Ride Moderation',
      icon: Car,
      badge: null,
      group: 'ops',
    },
    {
      key: 'bookings',
      label: 'Bookings',
      icon: Bookmark,
      badge: null,
      group: 'ops',
    },
    {
      key: 'disputes',
      label: 'Dispute Cases',
      icon: Scale,
      badge: null,
      group: 'ops',
    },
    {
      key: 'fraud',
      label: 'Fraud & Risk',
      icon: ShieldAlert,
      badge: null,
      group: 'ops',
    },
    {
      key: 'reports',
      label: 'Safety Incidents',
      icon: AlertTriangle,
      badge: pendingReportsCount > 0 ? pendingReportsCount : null,
      badgeColor: 'bg-rose-100 text-rose-900 border border-rose-300',
      group: 'ops',
    },
    {
      key: 'tickets',
      label: 'Support Tickets',
      icon: LifeBuoy,
      badge: null,
      group: 'ops',
    },
    {
      key: 'users',
      label: 'User Directory',
      icon: Users,
      badge: null,
      group: 'ops',
    },

    // Business group
    {
      key: 'monetization',
      label: 'Revenue & Activity',
      icon: IndianRupee,
      badge: null,
      group: 'biz',
    },

    // Admin group
    {
      key: 'audit',
      label: 'Audit Logs',
      icon: ScrollText,
      badge: null,
      group: 'admin',
    },
    {
      key: 'operational',
      label: 'Telematics & Subsystems',
      icon: Activity,
      badge: null,
      group: 'admin',
    },
    {
      key: 'platform',
      label: 'Platform Settings',
      icon: SlidersHorizontal,
      badge: null,
      group: 'admin',
    },
    {
      key: 'settings',
      label: 'System Health',
      icon: Settings,
      badge: null,
      group: 'admin',
    },
  ];

  const { user } = useAuth();
  const visibleNavItems = navItems.filter((item) => isTabAuthorized(item.key, user?.role));

  const renderGroup = (groupKey: 'ops' | 'biz' | 'admin', label: string) => {
    const items = visibleNavItems.filter((i) => i.group === groupKey);
    if (items.length === 0) return null;
    return (
      <div className="space-y-1">
        <div className="px-3 pt-3 pb-1.5 text-[10px] font-extrabold text-textLight uppercase tracking-wider flex items-center justify-between">
          <span>{label}</span>
          <span className="h-px flex-1 bg-surface-subtle ml-2" />
        </div>
        {items.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.key;
          return (
            <button
              type="button"
              key={item.key}
              onClick={() => onSelectTab(item.key)}
              className={`w-full flex items-center justify-between px-3 py-2.5 rounded-xl text-xs sm:text-sm font-semibold transition-all duration-200 cursor-pointer group relative ${
                isActive
                  ? 'bg-gradient-to-r from-forest to-forest-dark text-white shadow-md shadow-forest/20'
                  : 'text-textMain hover:bg-surface hover:text-forest'
              }`}
            >
              {/* Active left indicator bar */}
              {isActive && (
                <span className="absolute left-0 top-2 bottom-2 w-1 bg-forest-mint rounded-r-full" />
              )}

              <div className="flex items-center space-x-2.5">
                <div
                  className={`w-7 h-7 rounded-lg flex items-center justify-center shrink-0 transition-colors ${
                    isActive
                      ? 'bg-white/15 text-forest-mint'
                      : 'bg-surface text-textMuted group-hover:bg-forest-light group-hover:text-forest'
                  }`}
                >
                  <Icon className="w-4 h-4" />
                </div>
                <span className="truncate tracking-tight">{item.label}</span>
              </div>

              {item.badge != null && (
                <span
                  className={`text-[10px] px-2 py-0.5 rounded-full font-extrabold shrink-0 shadow-2xs ${
                    isActive ? 'bg-white/20 text-white' : item.badgeColor
                  }`}
                >
                  {item.badge}
                </span>
              )}
            </button>
          );
        })}
      </div>
    );
  };

  return (
    <aside className="w-64 bg-white border-r border-surface-subtle flex flex-col shrink-0 h-full overflow-y-auto select-none">
      <div className="p-3 space-y-2 flex-1">
        {renderGroup('ops', 'Operations')}
        {renderGroup('biz', 'Business & Growth')}
        {renderGroup('admin', 'Infrastructure & Settings')}
      </div>

      {/* Footer architecture status badge */}
      <div className="p-3 border-t border-surface-subtle shrink-0">
        <div className="p-3 rounded-2xl bg-gradient-to-br from-surface to-surface-subtle/50 border border-surface-subtle">
          <div className="flex items-center justify-between">
            <span className="text-xs font-extrabold text-forest tracking-tight">Sahyān Grid</span>
            <span className="flex items-center space-x-1 text-[10px] font-bold text-emerald-700 bg-emerald-100/70 px-1.5 py-0.5 rounded-full">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              <span>v1.0.0</span>
            </span>
          </div>
          <div className="text-[10px] text-textMuted mt-1 leading-snug">
            Deterministic Route Engine · Free OSM & Nominatim Geocoding
          </div>
          <div className="mt-2 pt-2 border-t border-surface-subtle/80 flex items-center justify-between text-[10px] text-textLight font-mono">
            <span>Cluster Ping</span>
            <span className="text-emerald-700 font-bold">18ms</span>
          </div>
        </div>
      </div>
    </aside>
  );
};
