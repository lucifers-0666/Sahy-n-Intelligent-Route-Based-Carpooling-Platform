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
} from 'lucide-react';

export type TabKey =
  | 'overview'
  | 'verifications'
  | 'rides'
  | 'bookings'
  | 'reports'
  | 'users'
  | 'monetization'
  | 'audit'
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
      badgeColor: 'bg-amber-100 text-amber-800',
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
      label: 'Bookings & Disputes',
      icon: Bookmark,
      badge: null,
      group: 'ops',
    },
    {
      key: 'reports',
      label: 'Safety Incidents',
      icon: AlertTriangle,
      badge: pendingReportsCount > 0 ? pendingReportsCount : null,
      badgeColor: 'bg-rose-100 text-rose-800',
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

  const renderGroup = (groupKey: 'ops' | 'biz' | 'admin', label: string) => {
    const items = navItems.filter((i) => i.group === groupKey);
    return (
      <div className="space-y-0.5">
        <div className="px-3 py-2 text-[10px] font-bold text-textLight uppercase tracking-widest">
          {label}
        </div>
        {items.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.key;
          return (
            <button
              type="button"
              key={item.key}
              onClick={() => onSelectTab(item.key)}
              className={`w-full flex items-center justify-between px-3 py-2.5 rounded-xl text-sm font-semibold transition-all cursor-pointer ${
                isActive
                  ? 'bg-forest text-white shadow-xs shadow-forest/20'
                  : 'text-textMain hover:bg-surface hover:text-forest'
              }`}
            >
              <div className="flex items-center space-x-2.5">
                <Icon
                  className={`w-4 h-4 shrink-0 ${
                    isActive ? 'text-forest-mint' : 'text-textMuted'
                  }`}
                />
                <span className="truncate">{item.label}</span>
              </div>

              {item.badge != null && (
                <span
                  className={`text-[10px] px-1.5 py-0.5 rounded-full font-bold shrink-0 ${
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
      <div className="p-3 space-y-4 flex-1">
        {renderGroup('ops', 'Operations')}
        {renderGroup('biz', 'Business')}
        {renderGroup('admin', 'Admin Tools')}
      </div>

      <div className="p-3 border-t border-surface-subtle shrink-0">
        <div className="p-3 bg-surface rounded-xl">
          <div className="text-xs font-bold text-forest">Sahyān Architecture</div>
          <div className="text-[10px] text-textMuted mt-0.5">
            Peer Cost-Sharing · Free OSM · Deterministic Match
          </div>
          <div className="mt-1.5 text-[10px] text-textMuted font-mono">
            Production · Node/Mongo
          </div>
        </div>
      </div>
    </aside>
  );
};
