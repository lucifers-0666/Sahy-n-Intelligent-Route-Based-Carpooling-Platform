import React, { useState, useEffect } from 'react';
import { PlatformConfig } from '../../types/admin';
import { adminApi } from '../../services/api';
import {
  SlidersHorizontal,
  ShieldCheck,
  Car,
  IndianRupee,
  Radio,
  Bell,
  Leaf,
  AlertOctagon,
  MapPin,
  Power,
  RefreshCw,
  CheckCircle2,
  XCircle,
} from 'lucide-react';

interface ConfigRowProps {
  label: string;
  description: string;
  value: string | number | boolean;
  unit?: string;
  type?: 'text' | 'boolean' | 'number';
  accent?: string;
}

const ConfigRow: React.FC<ConfigRowProps> = ({ label, description, value, unit, type = 'text', accent = 'text-textMain' }) => (
  <div className="flex items-start justify-between gap-4 py-3.5 border-b border-surface-subtle last:border-0">
    <div className="flex-1 min-w-0">
      <div className="text-sm font-semibold text-textMain">{label}</div>
      <div className="text-xs text-textMuted mt-0.5">{description}</div>
    </div>
    <div className="shrink-0 text-right">
      {type === 'boolean' ? (
        <div className={`flex items-center gap-1.5 font-bold text-sm ${value ? 'text-emerald-700' : 'text-rose-700'}`}>
          {value ? <CheckCircle2 className="w-4 h-4" /> : <XCircle className="w-4 h-4" />}
          <span>{value ? 'Enabled' : 'Disabled'}</span>
        </div>
      ) : (
        <div className={`font-bold text-sm font-mono ${accent}`}>
          {String(value)}{unit ? ` ${unit}` : ''}
        </div>
      )}
    </div>
  </div>
);

interface SectionCardProps {
  icon: React.ComponentType<{ className?: string }>;
  title: string;
  subtitle: string;
  iconBg: string;
  iconColor: string;
  children: React.ReactNode;
}

const SectionCard: React.FC<SectionCardProps> = ({ icon: Icon, title, subtitle, iconBg, iconColor, children }) => (
  <div className="card p-0 overflow-hidden">
    <div className="flex items-center gap-3 p-5 border-b border-surface-subtle">
      <div className={`w-10 h-10 rounded-xl ${iconBg} flex items-center justify-center shrink-0`}>
        <Icon className={`w-5 h-5 ${iconColor}`} />
      </div>
      <div>
        <h2 className="text-sm font-bold text-textMain">{title}</h2>
        <p className="text-[11px] text-textMuted">{subtitle}</p>
      </div>
    </div>
    <div className="px-5">{children}</div>
  </div>
);

export const PlatformSettingsTab: React.FC = () => {
  const [config, setConfig] = useState<PlatformConfig | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastRefreshed, setLastRefreshed] = useState<Date>(new Date());

  const fetchConfig = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await adminApi.getPlatformConfig();
      setConfig(data);
      setLastRefreshed(new Date());
    } catch (e: any) {
      setError(e.message || 'Failed to load platform configuration');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchConfig();
  }, []);

  if (loading) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div className="skeleton h-8 w-64 rounded-xl" />
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="skeleton h-56 rounded-2xl" />
          ))}
        </div>
      </div>
    );
  }

  if (error || !config) {
    return (
      <div className="empty-state">
        <div className="empty-state-icon"><SlidersHorizontal className="w-6 h-6" /></div>
        <p className="text-sm font-bold text-textMain">Failed to load platform configuration</p>
        <p className="text-xs text-textMuted mt-1">{error}</p>
        <button onClick={fetchConfig} className="btn-primary mt-4">Retry</button>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="section-title flex items-center gap-2">
            <SlidersHorizontal className="w-5 h-5 text-forest" />
            Platform Settings & Configuration
          </h1>
          <p className="section-subtitle">
            Live runtime configuration read from environment variables ·
            Last refreshed {lastRefreshed.toLocaleTimeString('en-IN')}
          </p>
        </div>
        <button onClick={fetchConfig} className="btn-secondary flex items-center gap-1.5 text-xs shrink-0">
          <RefreshCw className="w-3.5 h-3.5" />
          Refresh Config
        </button>
      </div>

      {/* Maintenance Mode Banner */}
      {config.maintenanceMode && (
        <div className="p-4 bg-rose-50 border border-rose-200 rounded-2xl flex items-start gap-3">
          <AlertOctagon className="w-5 h-5 text-rose-600 mt-0.5 shrink-0" />
          <div>
            <div className="text-sm font-bold text-rose-800">Maintenance Mode is ACTIVE</div>
            <div className="text-xs text-rose-700 mt-0.5">
              The platform is currently in maintenance mode. End users may experience service interruptions.
              Set MAINTENANCE_MODE=false in your environment to restore normal operations.
            </div>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Ride Rules */}
        <SectionCard
          icon={Car}
          title="Ride & Seat Configuration"
          subtitle="Constraints applied during ride creation and booking"
          iconBg="bg-blue-50"
          iconColor="text-blue-700"
        >
          <ConfigRow
            label="Max Seats Per Ride"
            description="Maximum number of passenger seats a driver can offer"
            value={config.maxSeatsPerRide}
            unit="seats"
            type="number"
            accent="text-blue-700"
          />
          <ConfigRow
            label="Max Contribution Per Seat"
            description="Regulatory cap on the fuel cost contribution per seat"
            value={config.maxContributionPerSeat}
            unit="₹ / seat"
            type="number"
            accent="text-amber-700"
          />
          <ConfigRow
            label="Max Ride Distance"
            description="Maximum corridor distance permitted for a single ride"
            value={config.maxRideDistanceKm}
            unit="km"
            type="number"
            accent="text-blue-700"
          />
          <ConfigRow
            label="Default Carpool City"
            description="Primary city hub for ride matching and geofencing"
            value={config.defaultCarpoolCity}
            type="text"
            accent="text-forest"
          />
        </SectionCard>

        {/* Safety & Verification */}
        <SectionCard
          icon={ShieldCheck}
          title="Safety & Driver Verification"
          subtitle="KYC requirements and safety incident escalation thresholds"
          iconBg="bg-emerald-50"
          iconColor="text-emerald-700"
        >
          <ConfigRow
            label="Driver Verification Required"
            description="Whether drivers must complete KYC before posting rides"
            value={config.verificationRequired}
            type="boolean"
          />
          <ConfigRow
            label="Safety Report Auto-Escalation"
            description="Hours after which open safety reports are escalated to critical"
            value={config.safetyReportAutoEscalateHours}
            unit="hours"
            type="number"
            accent="text-rose-700"
          />
        </SectionCard>

        {/* Real-time Services */}
        <SectionCard
          icon={Radio}
          title="Real-Time Services"
          subtitle="Socket.IO telematics pipeline and push notification status"
          iconBg="bg-purple-50"
          iconColor="text-purple-700"
        >
          <ConfigRow
            label="Socket.IO Telematics"
            description="Real-time vehicle position broadcasting via Socket.IO rooms"
            value={config.socketTelematicsEnabled}
            type="boolean"
          />
          <ConfigRow
            label="Push Notifications"
            description="FCM push delivery for ride updates, booking events, and alerts"
            value={config.pushNotificationsEnabled}
            type="boolean"
          />
          <ConfigRow
            label="Platform Maintenance Mode"
            description="When enabled, surfaces maintenance notice to all clients"
            value={config.maintenanceMode}
            type="boolean"
          />
        </SectionCard>

        {/* Environmental & Billing */}
        <SectionCard
          icon={Leaf}
          title="Environmental & Billing Rules"
          subtitle="CO₂ savings calculation factor and P2P billing constraints"
          iconBg="bg-teal-50"
          iconColor="text-teal-700"
        >
          <ConfigRow
            label="CO₂ Saved Per Booking"
            description="Estimated kg of CO₂ emissions prevented per completed passenger booking"
            value={config.co2SavedKgPerBooking}
            unit="kg"
            type="number"
            accent="text-teal-700"
          />
          <ConfigRow
            label="Billing Model"
            description="Commercial transaction model used by the platform"
            value="Non-Commercial P2P"
            type="text"
            accent="text-forest"
          />
          <ConfigRow
            label="Platform Commission"
            description="Commission rate charged on passenger contributions"
            value="0%"
            type="text"
            accent="text-emerald-700"
          />
        </SectionCard>
      </div>

      {/* Config Source Note */}
      <div className="card bg-surface border-surface-subtle">
        <div className="flex items-start gap-3">
          <Power className="w-4 h-4 text-textMuted mt-0.5 shrink-0" />
          <div className="text-xs text-textMuted">
            <span className="font-bold text-textMain">Configuration Source: </span>
            All values above are read-only runtime parameters sourced from the server environment (
            <code className="font-mono bg-surface-subtle px-1 rounded">process.env</code>
            ). To change any setting, update the corresponding environment variable and restart the Node.js server.
            Future releases will support database-persisted dynamic configuration with audit-logged changes.
          </div>
        </div>
      </div>
    </div>
  );
};
