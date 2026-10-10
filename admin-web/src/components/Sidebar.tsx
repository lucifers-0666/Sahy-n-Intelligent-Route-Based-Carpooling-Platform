import React from 'react';
import {
  LayoutDashboard,
  FileCheck,
  Car,
  Bookmark,
  AlertTriangle,
  Users,
  Settings,
} from 'lucide-react';

export type TabKey = 'overview' | 'verifications' | 'rides' | 'bookings' | 'reports' | 'users' | 'settings';

interface SidebarProps {
  activeTab: TabKey;
  onSelectTab: (tab: TabKey) => void;
  pendingVerificationsCount?: number;
  pendingReportsCount?: number;
}

export const Sidebar: React.FC<SidebarProps> = ({
  activeTab,
  onSelectTab,
  pendingVerificationsCount = 0,
  pendingReportsCount = 0,
}) => {
  const navItems = [
    {
      key: 'overview' as TabKey,
      label: 'Overview & Metrics',
      icon: LayoutDashboard,
      badge: null,
    },
    {
      key: 'verifications' as TabKey,
      label: 'Driver Verifications',
      icon: FileCheck,
      badge: pendingVerificationsCount > 0 ? pendingVerificationsCount : null,
      badgeColor: 'bg-amber-100 text-amber-800',
    },
    {
      key: 'rides' as TabKey,
      label: 'Ride Moderation',
      icon: Car,
      badge: null,
    },
    {
      key: 'bookings' as TabKey,
      label: 'Bookings & Disputes',
      icon: Bookmark,
      badge: null,
    },
    {
      key: 'reports' as TabKey,
      label: 'Safety Incidents',
      icon: AlertTriangle,
      badge: pendingReportsCount > 0 ? pendingReportsCount : null,
      badgeColor: 'bg-rose-100 text-rose-800',
    },
    {
      key: 'users' as TabKey,
      label: 'User Directory',
      icon: Users,
      badge: null,
    },
    {
      key: 'settings' as TabKey,
      label: 'System Health',
      icon: Settings,
      badge: null,
    },
  ];

  return (
    <aside className="w-64 bg-white border-r border-surface-subtle flex flex-col shrink-0 min-h-[calc(100vh-4rem)]">
      <div className="p-4 space-y-1">
        <div className="px-3 py-2 text-[11px] font-bold text-textMuted uppercase tracking-wider">
          Management & Audits
        </div>

        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.key;

          return (
            <button
              key={item.key}
              onClick={() => onSelectTab(item.key)}
              className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl text-sm font-semibold transition-all cursor-pointer ${
                isActive
                  ? 'bg-forest text-white shadow-sm shadow-forest/20'
                  : 'text-textMain hover:bg-surface hover:text-forest'
              }`}
            >
              <div className="flex items-center space-x-3">
                <Icon className={`w-4 h-4 ${isActive ? 'text-forest-mint' : 'text-textMuted'}`} />
                <span>{item.label}</span>
              </div>

              {item.badge !== null && (
                <span
                  className={`text-xs px-2 py-0.5 rounded-full font-bold ${
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

      <div className="mt-auto p-4 border-t border-surface-subtle">
        <div className="p-3 bg-surface rounded-xl">
          <div className="text-xs font-bold text-forest">Sahyān Architecture</div>
          <div className="text-[11px] text-textMuted mt-0.5">
            Peer Cost-Sharing · Free OpenStreetMap · Deterministic Matching
          </div>
          <div className="mt-2 text-[10px] text-textMuted font-mono">
            Environment: Production Node/Mongo
          </div>
        </div>
      </div>
    </aside>
  );
};
