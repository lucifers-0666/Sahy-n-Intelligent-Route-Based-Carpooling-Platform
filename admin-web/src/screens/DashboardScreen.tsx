import React, { useState, useEffect } from 'react';
import { io, Socket } from 'socket.io-client';
import { Header } from '../components/Header';
import { Sidebar, TabKey } from '../components/Sidebar';
import { OverviewTab } from '../components/tabs/OverviewTab';
import { VerificationsTab } from '../components/tabs/VerificationsTab';
import { RidesTab } from '../components/tabs/RidesTab';
import { BookingsTab } from '../components/tabs/BookingsTab';
import { DisputesTab } from '../components/tabs/DisputesTab';
import { FraudCenterTab } from '../components/tabs/FraudCenterTab';
import { ReportsTab } from '../components/tabs/ReportsTab';
import { UsersTab } from '../components/tabs/UsersTab';
import { SettingsTab } from '../components/tabs/SettingsTab';
import { MonetizationTab } from '../components/tabs/MonetizationTab';
import { AuditLogsTab } from '../components/tabs/AuditLogsTab';
import { PlatformSettingsTab } from '../components/tabs/PlatformSettingsTab';
import { SosIncidentModal } from '../components/SosIncidentModal';
import { CorridorBroadcastModal } from '../components/CorridorBroadcastModal';
import { AdminStats, SosIncident } from '../types/admin';
import { adminApi, SOCKET_URL } from '../services/api';
import { useAuth } from '../context/AuthContext';
import { isTabAuthorized, hasCapability } from '../utils/rbac';
import { ShieldAlert, X, Radio } from 'lucide-react';

const VALID_TABS: TabKey[] = [
  'overview',
  'verifications',
  'rides',
  'bookings',
  'disputes',
  'fraud',
  'reports',
  'users',
  'monetization',
  'audit',
  'platform',
  'settings',
];

const getInitialTab = (): TabKey => {
  if (typeof window !== 'undefined') {
    const hash = window.location.hash.replace('#', '') as TabKey;
    if (VALID_TABS.includes(hash)) return hash;
    const saved = localStorage.getItem('sahyan_active_tab') as TabKey;
    if (saved && VALID_TABS.includes(saved)) return saved;
  }
  return 'overview';
};

export const DashboardScreen: React.FC = () => {
  const { user } = useAuth();
  const canManageSos = hasCapability(user?.role, 'MANAGE_SOS_INCIDENTS');

  const [activeTab, setActiveTabState] = useState<TabKey>(() => {
    const initial = getInitialTab();
    return isTabAuthorized(initial, user?.role) ? initial : 'overview';
  });

  const setActiveTab = (tab: TabKey) => {
    const target = isTabAuthorized(tab, user?.role) ? tab : 'overview';
    setActiveTabState(target);
    if (typeof window !== 'undefined') {
      window.location.hash = target;
      localStorage.setItem('sahyan_active_tab', target);
    }
  };

  useEffect(() => {
    if (!isTabAuthorized(activeTab, user?.role)) {
      setActiveTab('overview');
    }
  }, [activeTab, user?.role]);

  useEffect(() => {
    const handleHash = () => {
      const hash = window.location.hash.replace('#', '') as TabKey;
      if (VALID_TABS.includes(hash)) {
        if (isTabAuthorized(hash, user?.role)) {
          setActiveTabState(hash);
          localStorage.setItem('sahyan_active_tab', hash);
        } else {
          setActiveTabState('overview');
          window.location.hash = 'overview';
          localStorage.setItem('sahyan_active_tab', 'overview');
        }
      }
    };
    window.addEventListener('hashchange', handleHash);
    return () => window.removeEventListener('hashchange', handleHash);
  }, [user?.role]);

  const [stats, setStats] = useState<AdminStats | null>(null);
  const [refreshing, setRefreshing] = useState(false);
  const [dbConnected, setDbConnected] = useState(true);

  // Real-time Emergency SOS incident state
  const [socket, setSocket] = useState<Socket | null>(null);
  const [activeIncident, setActiveIncident] = useState<SosIncident | null>(null);
  const [incidentModalOpen, setIncidentModalOpen] = useState(false);
  const [unreadAlerts, setUnreadAlerts] = useState<SosIncident[]>([]);
  const [broadcastModalOpen, setBroadcastModalOpen] = useState(false);

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

  // Connect to Socket.IO server & join admin_emergency_channel only if authorized
  useEffect(() => {
    if (!canManageSos) return;

    const token = localStorage.getItem('sahyan_admin_token');
    const s = io(SOCKET_URL, {
      auth: { token },
      transports: ['websocket', 'polling'],
      reconnectionAttempts: 5,
    });

    s.on('connect', () => {
      s.emit('join_admin_channel');
    });

    s.on('admin_emergency_alert', (incident: SosIncident) => {
      setUnreadAlerts((prev) => [incident, ...prev]);
      setActiveIncident(incident);
      setIncidentModalOpen(true);
      fetchStats();
    });

    s.on('incident_updated', ({ incidentId, status }: { incidentId: string; status: string }) => {
      if (status === 'resolved') {
        setUnreadAlerts((prev) => prev.filter((a) => a.incidentId !== incidentId));
      }
      fetchStats();
    });

    setSocket(s);

    return () => {
      s.disconnect();
    };
  }, [canManageSos]);

  const triggerMockSos = () => {
    const mockIncident: SosIncident = {
      incidentId: `mock_${Date.now()}`,
      timestamp: new Date().toISOString(),
      passenger: {
        id: 'user_pax_01',
        name: 'Aarav Patel',
        phone: '+91 98765 43210',
        email: 'aarav.patel@corridor.in',
        emergencyContacts: [
          { name: 'Dr. Ramesh Patel', phone: '+91 98250 11223', relationship: 'Father', isPrimary: true },
          { name: 'Pooja Patel', phone: '+91 94260 55443', relationship: 'Sister' },
        ],
      },
      driver: {
        id: 'driver_dl_09',
        name: 'Vikramjit Singh',
        phone: '+91 99099 88776',
      },
      ride: {
        id: 'ride_ahm_gdn_44',
        origin: { name: 'Ahmedabad ISBT Geeta Mandir' },
        destination: { name: 'Gandhinagar InfoCity Tech Park' },
        status: 'active',
      },
      location: {
        latitude: 23.0845,
        longitude: 72.5921,
        address: 'SG Highway KM 24, near Vaishnodevi Circle',
      },
      status: 'open',
      severity: 'critical',
    };

    setUnreadAlerts((prev) => [mockIncident, ...prev]);
    setActiveIncident(mockIncident);
    setIncidentModalOpen(true);
  };

  return (
    <div className="h-screen w-screen overflow-hidden bg-surface flex flex-col font-sans">
      <div className="shrink-0 z-30">
        <Header
          dbConnected={dbConnected}
          refreshing={refreshing}
          onRefresh={fetchStats}
        />
      </div>

      {/* Real-Time Emergency SOS Alert Banner (Protected: super_admin, safety_officer) */}
      {canManageSos && unreadAlerts.length > 0 && (
        <div className="shrink-0 bg-rose-700 text-white px-4 sm:px-6 py-2.5 flex items-center justify-between border-b border-rose-900 shadow-md animate-pulse z-20">
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 rounded-lg bg-white/20 flex items-center justify-center shrink-0">
              <ShieldAlert className="w-5 h-5 text-white" />
            </div>
            <div className="text-xs">
              <span className="uppercase font-black tracking-wider bg-white text-rose-800 px-2 py-0.5 rounded text-[10px] mr-2">
                ACTIVE SOS DISTRESS
              </span>
              <span className="font-bold text-white">
                {unreadAlerts[0].passenger.name} triggered in-transit distress along corridor.
              </span>
              <span className="text-rose-200 ml-2 hidden sm:inline">
                ({unreadAlerts[0].location.address})
              </span>
            </div>
          </div>
          <div className="flex items-center space-x-2">
            <button
              onClick={() => {
                setActiveIncident(unreadAlerts[0]);
                setIncidentModalOpen(true);
              }}
              className="px-3 py-1.5 bg-white text-rose-800 hover:bg-stone-100 rounded-lg text-xs font-black uppercase tracking-wider transition-all shadow-sm cursor-pointer"
            >
              Open Safety Console
            </button>
            <button
              onClick={() => setUnreadAlerts([])}
              className="text-white/80 hover:text-white p-1 cursor-pointer"
              title="Dismiss banner"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}

      <div className="flex flex-1 overflow-hidden min-h-0">
        <Sidebar
          activeTab={activeTab}
          onSelectTab={setActiveTab}
          pendingVerificationsCount={stats?.pendingVerifications}
          pendingReportsCount={stats?.safetyReports?.pending}
        />

        <main className="flex-1 overflow-y-auto p-6 sm:p-8 min-h-0 h-full">
          <div className="max-w-7xl mx-auto space-y-4">
            {/* Action buttons bar for quick reviewer inspection & safety broadcast */}
            <div className="flex items-center justify-end space-x-2">
              <button
                onClick={() => setBroadcastModalOpen(true)}
                className="inline-flex items-center space-x-1.5 px-3 py-1 rounded-full bg-forest-light hover:bg-forest text-forest hover:text-white border border-forest/20 text-[11px] font-bold transition-colors cursor-pointer shadow-2xs"
                title="Broadcast real-time emergency alert across corridors"
              >
                <Radio className="w-3 h-3 text-forest animate-pulse" />
                <span>Corridor Safety Broadcast</span>
              </button>

              {canManageSos && (
                <button
                  onClick={triggerMockSos}
                  className="inline-flex items-center space-x-1.5 px-3 py-1 rounded-full bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 text-[11px] font-bold transition-colors cursor-pointer shadow-2xs"
                  title="Simulate Mobile SOS Trigger"
                >
                  <Radio className="w-3 h-3 text-rose-600 animate-pulse" />
                  <span>Simulate Real-Time Mobile SOS Dispatch</span>
                </button>
              )}
            </div>

            {activeTab === 'overview' && (
              <OverviewTab
                stats={stats}
                onNavigateTab={setActiveTab}
                onRefresh={fetchStats}
                refreshing={refreshing}
              />
            )}
            {activeTab === 'verifications' && <VerificationsTab />}
            {activeTab === 'rides' && <RidesTab />}
            {activeTab === 'bookings' && <BookingsTab />}
            {activeTab === 'disputes' && <DisputesTab />}
            {activeTab === 'fraud' && <FraudCenterTab />}
            {activeTab === 'reports' && <ReportsTab />}
            {activeTab === 'users' && <UsersTab />}
            {activeTab === 'monetization' && <MonetizationTab />}
            {activeTab === 'audit' && <AuditLogsTab />}
            {activeTab === 'platform' && <PlatformSettingsTab />}
            {activeTab === 'settings' && <SettingsTab dbConnected={dbConnected} />}
          </div>
        </main>
      </div>

      {/* Emergency SOS Modal Console */}
      <SosIncidentModal
        incident={activeIncident}
        isOpen={incidentModalOpen}
        onClose={() => setIncidentModalOpen(false)}
        onLogPoliceCall={async (incidentId, notes) => {
          if (socket) {
            socket.emit('log_police_call', { incidentId, notes });
          }
          await adminApi.resolveReport(incidentId, 'investigating', notes || '112 Police Call Dispatched');
          fetchStats();
        }}
        onResolveIncident={async (incidentId, notes) => {
          await adminApi.resolveReport(incidentId, 'resolved', notes || 'Resolved from emergency console');
          setActiveIncident(null);
          setUnreadAlerts((prev) => prev.filter((a) => a.incidentId !== incidentId));
          fetchStats();
        }}
      />

      {/* Emergency Corridor Broadcast Dispatcher */}
      <CorridorBroadcastModal
        isOpen={broadcastModalOpen}
        onClose={() => setBroadcastModalOpen(false)}
        onSuccess={fetchStats}
      />
    </div>
  );
};
