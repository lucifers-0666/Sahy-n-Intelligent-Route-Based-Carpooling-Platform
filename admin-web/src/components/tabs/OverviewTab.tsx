import React from 'react';
import { AdminStats } from '../../types/admin';
import { StatCard } from '../StatCard';
import {
  Users,
  ShieldCheck,
  Navigation,
  Leaf,
  IndianRupee,
  FileClock,
  AlertOctagon,
  CheckCircle2,
  MapPin,
  TrendingUp,
} from 'lucide-react';

interface OverviewTabProps {
  stats: AdminStats | null;
  onNavigateTab: (tab: any) => void;
}

export const OverviewTab: React.FC<OverviewTabProps> = ({ stats, onNavigateTab }) => {
  return (
    <div className="space-y-6">
      {/* Welcome Banner */}
      <div className="bg-gradient-to-r from-forest-dark to-forest text-white rounded-3xl p-6 sm:p-8 shadow-sm relative overflow-hidden">
        <div className="relative z-10 max-w-2xl">
          <span className="text-xs font-bold tracking-widest text-forest-mint uppercase block">
            Operations & Fleet Oversight
          </span>
          <h1 className="text-2xl sm:text-3xl font-extrabold mt-1 tracking-tight">
            Corridor Intelligence & Safety Console
          </h1>
          <p className="text-white/80 text-sm mt-2 font-medium">
            Monitoring active intercity carpooling corridors, peer cost-sharing settlements, driver verification queues, and passenger safety incidents.
          </p>

          <div className="flex flex-wrap gap-3 mt-6">
            <button
              onClick={() => onNavigateTab('verifications')}
              className="px-4 py-2 bg-white text-forest font-bold text-xs rounded-xl shadow-xs hover:bg-forest-mint transition-colors cursor-pointer"
            >
              Review Drivers ({stats?.pendingVerifications ?? 0})
            </button>
            <button
              onClick={() => onNavigateTab('reports')}
              className="px-4 py-2 bg-white/10 hover:bg-white/20 text-white font-bold text-xs rounded-xl border border-white/20 transition-colors cursor-pointer"
            >
              Safety Reports ({stats?.safetyReports?.pending ?? 0})
            </button>
            <button
              onClick={() => onNavigateTab('rides')}
              className="px-4 py-2 bg-white/10 hover:bg-white/20 text-white font-bold text-xs rounded-xl border border-white/20 transition-colors cursor-pointer"
            >
              Active Corridors ({stats?.activeJourneys ?? stats?.activeRides ?? 0})
            </button>
          </div>
        </div>
      </div>

      {/* KPI Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          title="Community Members"
          value={stats?.totalUsers ?? '...'}
          subtitle="Registered riders and drivers"
          icon={Users}
          trend="+18% this month"
        />
        <StatCard
          title="Verified Drivers"
          value={stats?.verifiedDrivers ?? '...'}
          subtitle="Document-checked operators"
          icon={ShieldCheck}
          iconBgColor="bg-emerald-50"
          iconColor="text-emerald-700"
          trend="KYC verified"
        />
        <StatCard
          title="Active Corridors"
          value={stats?.activeJourneys ?? stats?.activeRides ?? 0}
          subtitle={stats?.scheduledRides ? `${stats.scheduledRides} scheduled upcoming` : 'Live trips & scheduled rides'}
          icon={Navigation}
          iconBgColor="bg-blue-50"
          iconColor="text-blue-700"
          trend="Real-time GPS"
        />
        <StatCard
          title="Environmental Impact"
          value={`${stats?.totalCo2SavedKg ?? stats?.totalCarbonSavedKg ?? 0} kg`}
          subtitle="Estimated CO2 emissions prevented"
          icon={Leaf}
          iconBgColor="bg-teal-50"
          iconColor="text-teal-700"
          trend="Eco-certified"
        />
      </div>

      {/* Secondary Metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <StatCard
          title="Fuel Cost Shared"
          value={`₹${stats?.totalFuelSplit ?? stats?.totalFuelSharedInr ?? 0}`}
          subtitle="Non-commercial peer contributions"
          icon={IndianRupee}
          iconBgColor="bg-amber-50"
          iconColor="text-amber-700"
        />
        <StatCard
          title="Pending Verifications"
          value={stats?.pendingVerifications ?? 0}
          subtitle="Driving licenses & RC awaiting review"
          icon={FileClock}
          iconBgColor="bg-orange-50"
          iconColor="text-orange-700"
          trendPositive={false}
          trend={stats?.pendingVerifications ? 'Action required' : 'Queue clear'}
        />
        <StatCard
          title="Safety Incident Queue"
          value={stats?.openReports ?? stats?.safetyReports?.pending ?? 0}
          subtitle="Unresolved passenger or trip reports"
          icon={AlertOctagon}
          iconBgColor="bg-rose-50"
          iconColor="text-rose-700"
          trendPositive={false}
          trend={(stats?.openReports ?? stats?.safetyReports?.pending ?? 0) > 0 ? 'High priority' : '0 open flags'}
        />
      </div>

      {/* Corridor Health and Operations Map Summary */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-2xl p-6 border border-surface-subtle shadow-xs">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-base font-bold text-textMain flex items-center space-x-2">
              <TrendingUp className="w-4 h-4 text-forest" />
              <span>Key Intercity Corridors Health</span>
            </h2>
            <span className="text-xs text-textMuted font-medium">Auto-refreshed</span>
          </div>

          <div className="space-y-3">
            {[
              { corridor: 'Ahmedabad SG Highway - Vadodara Expressway', status: 'Optimal', matchAvg: '94% Match', load: 'Heavy' },
              { corridor: 'Surat Ring Road - Mumbai Western Express', status: 'Optimal', matchAvg: '91% Match', load: 'Moderate' },
              { corridor: 'Gandhinagar InfoCity - Ahmedabad Prahladnagar', status: 'Optimal', matchAvg: '96% Match', load: 'High Demand' },
              { corridor: 'Rajkot Highway - Ahmedabad Ring Road', status: 'Stable', matchAvg: '88% Match', load: 'Normal' },
            ].map((c, i) => (
              <div key={i} className="flex items-center justify-between p-3.5 rounded-xl bg-surface border border-surface-subtle">
                <div className="flex items-center space-x-3">
                  <MapPin className="w-4 h-4 text-forest shrink-0" />
                  <div>
                    <div className="text-xs font-bold text-textMain">{c.corridor}</div>
                    <div className="text-[11px] text-textMuted">{c.load} corridor traffic</div>
                  </div>
                </div>
                <div className="text-right">
                  <span className="text-[11px] font-bold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-800 border border-emerald-200">
                    {c.matchAvg}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white rounded-2xl p-6 border border-surface-subtle shadow-xs">
          <h2 className="text-base font-bold text-textMain mb-4 flex items-center space-x-2">
            <CheckCircle2 className="w-4 h-4 text-forest" />
            <span>Platform Principles & Architecture</span>
          </h2>

          <div className="space-y-3 text-xs text-textMain">
            <div className="p-3.5 rounded-xl bg-emerald-50/70 border border-emerald-100 flex items-start space-x-3">
              <div className="w-2 h-2 rounded-full bg-forest mt-1.5 shrink-0"></div>
              <div>
                <span className="font-bold text-forest">Zero Paid Mapping Dependency:</span>
                <p className="text-textMuted mt-0.5">
                  100% powered by OpenStreetMap tiles, OSRM routing engine, and Nominatim forward/reverse geocoding. No Google Maps billing or API key quotas.
                </p>
              </div>
            </div>

            <div className="p-3.5 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start space-x-3">
              <div className="w-2 h-2 rounded-full bg-blue-600 mt-1.5 shrink-0"></div>
              <div>
                <span className="font-bold text-blue-900">Explainable 5-Factor Route Match Engine:</span>
                <p className="text-textMuted mt-0.5">
                  Deterministic geospatial scoring combining pickup deviation (25%), destination deviation (25%), route overlap (20%), time compatibility (15%), driver reliability (10%), and seat ratio (5%).
                </p>
              </div>
            </div>

            <div className="p-3.5 rounded-xl bg-amber-50/70 border border-amber-100 flex items-start space-x-3">
              <div className="w-2 h-2 rounded-full bg-amber-600 mt-1.5 shrink-0"></div>
              <div>
                <span className="font-bold text-amber-900">Non-Commercial Fuel Cost-Sharing:</span>
                <p className="text-textMuted mt-0.5">
                  Operates strictly under peer-to-peer fuel cost compensation rules with capped seat contributions, compliant with private vehicle pooling guidelines.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
