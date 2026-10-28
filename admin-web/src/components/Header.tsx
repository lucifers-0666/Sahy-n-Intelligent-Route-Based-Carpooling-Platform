import React from 'react';
import { useAuth } from '../context/AuthContext';
import { ShieldCheck, LogOut, Activity, Database, RefreshCw, Search, Sparkles } from 'lucide-react';

interface HeaderProps {
  dbConnected: boolean;
  refreshing: boolean;
  onRefresh: () => void;
}

export const Header: React.FC<HeaderProps> = ({ dbConnected, refreshing, onRefresh }) => {
  const { user, logout } = useAuth();

  return (
    <header className="h-16 bg-white/85 backdrop-blur-xl border-b border-surface-subtle px-4 sm:px-6 flex items-center justify-between sticky top-0 z-30 shadow-xs select-none transition-all">
      {/* Brand & Title */}
      <div className="flex items-center space-x-3.5">
        <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-forest-dark to-forest flex items-center justify-center text-white font-extrabold text-base shadow-sm ring-2 ring-forest-mint/30 transform hover:scale-105 transition-transform">
          S
        </div>
        <div>
          <div className="flex items-center space-x-2">
            <span className="font-extrabold text-lg text-textMain tracking-tight">Sahyān</span>
            <span className="text-[10px] px-2 py-0.5 rounded-full bg-forest-light text-forest font-bold tracking-wider uppercase border border-forest-mint/50">
              Admin OS
            </span>
          </div>
          <p className="text-[11px] text-textMuted font-medium leading-none hidden sm:block">
            Intelligent Corridor Operations & Moderation Console
          </p>
        </div>
      </div>

      {/* Center: Command Palette Trigger Aesthetic + Operational Status */}
      <div className="hidden lg:flex items-center space-x-3 text-xs">
        {/* Quick Search trigger aesthetic */}
        <div className="flex items-center space-x-2 px-3 py-1.5 rounded-xl bg-surface border border-surface-subtle text-textMuted text-xs w-64 hover:border-forest-mint transition-colors cursor-pointer">
          <Search className="w-3.5 h-3.5 text-textLight" />
          <span className="flex-1 truncate text-[11px]">Search corridors, rides, users...</span>
          <kbd className="px-1.5 py-0.5 text-[9px] font-mono font-bold bg-white text-textMuted rounded border border-surface-subtle shadow-2xs">
            ⌘K
          </kbd>
        </div>

        {/* Database Status with live beacon */}
        <div className="flex items-center space-x-2 px-3 py-1.5 rounded-xl bg-emerald-50/80 border border-emerald-200/80 text-emerald-800 shadow-2xs">
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
          </span>
          <Database className="w-3.5 h-3.5 text-emerald-700" />
          <span className="font-semibold text-[11px]">
            {dbConnected ? 'MongoDB Cluster Live' : 'DB Syncing'}
          </span>
        </div>

        {/* Telematics Status */}
        <div className="flex items-center space-x-1.5 px-3 py-1.5 rounded-xl bg-blue-50/80 border border-blue-200/80 text-blue-800 shadow-2xs">
          <Activity className="w-3.5 h-3.5 text-blue-700 animate-pulse" />
          <span className="font-semibold text-[11px]">Telematics Active</span>
        </div>
      </div>

      {/* Right Controls: Sync button + User Profile + Logout */}
      <div className="flex items-center space-x-3">
        <button
          onClick={onRefresh}
          disabled={refreshing}
          className="flex items-center space-x-1.5 px-3 py-1.5 rounded-xl bg-white border border-surface-subtle text-textMain hover:border-forest-mint hover:bg-forest-light/40 transition-all cursor-pointer text-xs font-semibold shadow-2xs disabled:opacity-50 active:scale-95"
          title="Synchronize live operational data"
        >
          <RefreshCw className={`w-3.5 h-3.5 text-forest ${refreshing ? 'animate-spin' : ''}`} />
          <span className="hidden sm:inline">{refreshing ? 'Syncing...' : 'Sync Live'}</span>
        </button>

        {/* User Info */}
        <div className="flex items-center space-x-2.5 pl-2 border-l border-surface-subtle">
          <div className="relative">
            <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-forest to-emerald-600 text-white flex items-center justify-center font-bold text-xs shadow-xs ring-2 ring-forest-mint/40">
              {user?.name ? user.name[0].toUpperCase() : 'A'}
            </div>
            <span className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-500 rounded-full border-2 border-white"></span>
          </div>

          <div className="hidden sm:block text-left">
            <div className="text-xs font-bold text-textMain flex items-center space-x-1">
              <span>{user?.name || 'Super Admin'}</span>
              <ShieldCheck className="w-3.5 h-3.5 text-forest" />
            </div>
            <div className="text-[10px] text-textMuted font-medium truncate max-w-[130px]">
              {user?.email || 'admin@sahyan.app'}
            </div>
          </div>
        </div>

        <button
          onClick={logout}
          title="Sign out of Admin Console"
          className="p-2 rounded-xl text-textMuted hover:text-rose-600 hover:bg-rose-50 transition-colors cursor-pointer"
        >
          <LogOut className="w-4 h-4" />
        </button>
      </div>
    </header>
  );
};
