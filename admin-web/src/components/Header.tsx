import React from 'react';
import { useAuth } from '../context/AuthContext';
import { ShieldCheck, LogOut, Activity, Database } from 'lucide-react';

interface HeaderProps {
  dbConnected: boolean;
  refreshing: boolean;
  onRefresh: () => void;
}

export const Header: React.FC<HeaderProps> = ({ dbConnected, refreshing, onRefresh }) => {
  const { user, logout } = useAuth();

  return (
    <header className="h-16 bg-white border-b border-surface-subtle px-6 flex items-center justify-between sticky top-0 z-30 shadow-xs">
      {/* Brand & Title */}
      <div className="flex items-center space-x-3">
        <div className="w-9 h-9 rounded-xl bg-forest-dark flex items-center justify-center text-white font-extrabold text-lg shadow-sm">
          S
        </div>
        <div>
          <div className="flex items-center space-x-2">
            <span className="font-extrabold text-lg text-textMain tracking-tight">Sahyān</span>
            <span className="text-xs px-2 py-0.5 rounded-full bg-forest-light text-forest font-semibold uppercase tracking-wider">
              Admin OS
            </span>
          </div>
          <p className="text-[11px] text-textMuted font-medium leading-none">
            Intelligent Corridor Operations & Moderation Console
          </p>
        </div>
      </div>

      {/* Center Operational Status */}
      <div className="hidden md:flex items-center space-x-4 text-xs">
        <div className="flex items-center space-x-1.5 px-2.5 py-1 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-800">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
          <Database className="w-3.5 h-3.5" />
          <span className="font-medium">
            {dbConnected ? 'Database Connected' : 'DB Syncing'}
          </span>
        </div>

        <div className="flex items-center space-x-1.5 px-2.5 py-1 rounded-full bg-blue-50 border border-blue-200 text-blue-800">
          <Activity className="w-3.5 h-3.5" />
          <span className="font-medium">Telematics Active</span>
        </div>

        <button
          onClick={onRefresh}
          disabled={refreshing}
          className="px-2.5 py-1 rounded-lg border border-gray-200 text-textMuted hover:text-textMain hover:bg-gray-50 transition-colors cursor-pointer text-xs font-medium"
        >
          {refreshing ? 'Syncing...' : 'Sync Live Data'}
        </button>
      </div>

      {/* User Info & Logout */}
      <div className="flex items-center space-x-4">
        <div className="flex items-center space-x-2.5">
          <div className="w-8 h-8 rounded-full bg-forest-light text-forest flex items-center justify-center font-bold text-xs border border-forest-mint">
            {user?.name ? user.name[0].toUpperCase() : 'A'}
          </div>
          <div className="hidden sm:block text-left">
            <div className="text-xs font-bold text-textMain flex items-center space-x-1">
              <span>{user?.name || 'Super Admin'}</span>
              <ShieldCheck className="w-3.5 h-3.5 text-forest" />
            </div>
            <div className="text-[11px] text-textMuted">{user?.email || 'admin@sahyan.app'}</div>
          </div>
        </div>

        <button
          onClick={logout}
          title="Sign out of Admin Console"
          className="p-2 rounded-lg text-textMuted hover:text-red-600 hover:bg-red-50 transition-colors cursor-pointer"
        >
          <LogOut className="w-4 h-4" />
        </button>
      </div>
    </header>
  );
};
