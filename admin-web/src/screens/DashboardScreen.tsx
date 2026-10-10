import React, { useState, useEffect } from 'react';
import { Header } from '../components/Header';
import { Sidebar, TabKey } from '../components/Sidebar';
import { OverviewTab } from '../components/tabs/OverviewTab';
import { VerificationsTab } from '../components/tabs/VerificationsTab';
import { RidesTab } from '../components/tabs/RidesTab';
import { BookingsTab } from '../components/tabs/BookingsTab';
import { ReportsTab } from '../components/tabs/ReportsTab';
import { UsersTab } from '../components/tabs/UsersTab';
import { SettingsTab } from '../components/tabs/SettingsTab';
import { MonetizationTab } from '../components/tabs/MonetizationTab';
import { AuditLogsTab } from '../components/tabs/AuditLogsTab';
import { PlatformSettingsTab } from '../components/tabs/PlatformSettingsTab';
import { AdminStats } from '../types/admin';
import { adminApi } from '../services/api';

export const DashboardScreen: React.FC = () => {
  const [activeTab, setActiveTab] = useState<TabKey>('overview');
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [refreshing, setRefreshing] = useState(false);
  const [dbConnected, setDbConnected] = useState(true);

  const fetchStats = async () => {
    setRefreshing(true);
    try {
      const data = await adminApi.getStats();
      setStats(data);
      const isConnected = data.systemHealth?.database === 'connected' || data.databaseConnected === true;
      setDbConnected(isConnected);
    } catch {
      setDbConnected(false);
    } finally {
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchStats();
    const timer = setInterval(fetchStats, 30000);
    return () => clearInterval(timer);
  }, []);

  return (
    <div className="min-h-screen bg-surface flex flex-col font-sans">
      <Header
        dbConnected={dbConnected}
        refreshing={refreshing}
        onRefresh={fetchStats}
      />

      <div className="flex flex-1 overflow-hidden">
        <Sidebar
          activeTab={activeTab}
          onSelectTab={setActiveTab}
          pendingVerificationsCount={stats?.pendingVerifications}
          pendingReportsCount={stats?.safetyReports?.pending}
        />

        <main className="flex-1 overflow-y-auto p-6 sm:p-8">
          <div className="max-w-7xl mx-auto">
            {activeTab === 'overview' && (
              <OverviewTab stats={stats} onNavigateTab={setActiveTab} />
            )}
            {activeTab === 'verifications' && <VerificationsTab />}
            {activeTab === 'rides' && <RidesTab />}
            {activeTab === 'bookings' && <BookingsTab />}
            {activeTab === 'reports' && <ReportsTab />}
            {activeTab === 'users' && <UsersTab />}
            {activeTab === 'monetization' && <MonetizationTab />}
            {activeTab === 'audit' && <AuditLogsTab />}
            {activeTab === 'platform' && <PlatformSettingsTab />}
            {activeTab === 'settings' && <SettingsTab dbConnected={dbConnected} />}
          </div>
        </main>
      </div>
    </div>
  );
};
