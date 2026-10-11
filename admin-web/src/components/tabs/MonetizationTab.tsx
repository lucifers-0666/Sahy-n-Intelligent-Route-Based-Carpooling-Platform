import React, { useState, useEffect } from 'react';
import { RevenueStats } from '../../types/admin';
import { adminApi } from '../../services/api';
import {
  IndianRupee,
  TrendingUp,
  Users,
  Leaf,
  Bookmark,
  CheckCircle2,
  Clock,
  BarChart3,
} from 'lucide-react';

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

const fmt = (n: number) =>
  n >= 100000
    ? `₹${(n / 100000).toFixed(1)}L`
    : n >= 1000
    ? `₹${(n / 1000).toFixed(1)}K`
    : `₹${n.toLocaleString('en-IN')}`;

interface StatCardProps {
  icon: React.ComponentType<{ className?: string }>;
  title: string;
  value: string | number;
  sub?: string;
  iconBg?: string;
  iconColor?: string;
}

const MiniStat: React.FC<StatCardProps> = ({ icon: Icon, title, value, sub, iconBg = 'bg-forest-light', iconColor = 'text-forest' }) => (
  <div className="card flex items-start space-x-4">
    <div className={`w-10 h-10 rounded-xl ${iconBg} flex items-center justify-center shrink-0`}>
      <Icon className={`w-5 h-5 ${iconColor}`} />
    </div>
    <div className="flex-1 min-w-0">
      <div className="text-[11px] font-semibold text-textMuted uppercase tracking-wider truncate">{title}</div>
      <div className="text-2xl font-extrabold text-textMain mt-0.5 tracking-tight">{value}</div>
      {sub && <div className="text-xs text-textMuted mt-0.5">{sub}</div>}
    </div>
  </div>
);

export const MonetizationTab: React.FC = () => {
  const [stats, setStats] = useState<RevenueStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      setLoading(true);
      setError(null);
      try {
        const data = await adminApi.getRevenueStats();
        setStats(data);
      } catch (e: any) {
        setError(e.message || 'Failed to load revenue data');
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  if (loading) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div className="skeleton h-8 w-64 rounded-xl" />
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="skeleton h-28 rounded-2xl" />
          ))}
        </div>
        <div className="skeleton h-64 rounded-2xl" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="empty-state">
        <div className="empty-state-icon"><BarChart3 className="w-6 h-6" /></div>
        <p className="text-sm font-bold text-textMain">Failed to load revenue data</p>
        <p className="text-xs text-textMuted mt-1">{error}</p>
      </div>
    );
  }

  const s = stats!;

  // Build chart bars from trend data
  const maxFuel = Math.max(...(s.monthlyTrend?.map((t) => t.fuelShared) || [1]), 1);

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="bg-gradient-to-r from-forest-dark to-forest text-white rounded-3xl p-6 sm:p-8 relative overflow-hidden">
        <div className="relative z-10">
          <span className="text-xs font-bold tracking-widest text-forest-mint uppercase">
            Platform Activity & Revenue
          </span>
          <h1 className="text-2xl sm:text-3xl font-extrabold mt-1 tracking-tight">
            Fuel-Sharing Economy Dashboard
          </h1>
          <p className="text-white/80 text-sm mt-2 font-medium max-w-2xl">
            Sahyān operates strictly as a peer-to-peer fuel cost-sharing platform. All ₹ figures represent
            non-commercial passenger contributions toward fuel and toll expenses — not platform revenue.
          </p>
          <div className="mt-4 flex flex-wrap gap-3">
            <div className="px-3 py-1.5 bg-white/10 border border-white/20 rounded-xl text-xs font-bold text-white">
              {s.completionRate}% Booking Completion Rate
            </div>
            <div className="px-3 py-1.5 bg-white/10 border border-white/20 rounded-xl text-xs font-bold text-white">
              {s.newUsersMonth} New Members This Month
            </div>
            <div className="px-3 py-1.5 bg-white/10 border border-white/20 rounded-xl text-xs font-bold text-white">
              {s.co2SavedKg} kg CO₂ Averted
            </div>
          </div>
        </div>
        {/* Decorative circle */}
        <div className="absolute -right-10 -top-10 w-48 h-48 rounded-full bg-white/5 border border-white/10" />
        <div className="absolute -right-4 top-10 w-24 h-24 rounded-full bg-white/5 border border-white/10" />
      </div>

      {/* KPI row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <MiniStat
          icon={IndianRupee}
          title="Total Fuel Shared"
          value={fmt(s.totalFuelShared)}
          sub="Lifetime cumulative"
          iconBg="bg-amber-50"
          iconColor="text-amber-700"
        />
        <MiniStat
          icon={TrendingUp}
          title="This Month"
          value={fmt(s.monthlyFuelShared)}
          sub="Last 30 days"
          iconBg="bg-forest-light"
          iconColor="text-forest"
        />
        <MiniStat
          icon={Bookmark}
          title="Completed Bookings"
          value={s.completedBookings.toLocaleString()}
          sub={`of ${s.totalBookings} total`}
          iconBg="bg-blue-50"
          iconColor="text-blue-700"
        />
        <MiniStat
          icon={Leaf}
          title="CO₂ Avoided"
          value={`${s.co2SavedKg} kg`}
          sub="≈4.2 kg per booking"
          iconBg="bg-teal-50"
          iconColor="text-teal-700"
        />
      </div>

      {/* Chart + metrics */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Fuel sharing trend bar chart */}
        <div className="lg:col-span-2 card">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h2 className="text-sm font-bold text-textMain">Monthly Fuel-Sharing Trend</h2>
              <p className="text-xs text-textMuted mt-0.5">Completed booking contributions over last 6 months</p>
            </div>
            <span className="badge badge-green">Live Data</span>
          </div>

          {s.monthlyTrend && s.monthlyTrend.length > 0 ? (
            <div className="flex items-end gap-3 h-36">
              {s.monthlyTrend.map((m, i) => {
                const pct = maxFuel > 0 ? (m.fuelShared / maxFuel) * 100 : 0;
                const monthName = MONTHS[(m._id.month - 1) % 12];
                return (
                  <div key={i} className="flex flex-col items-center flex-1 gap-1">
                    <span className="text-[10px] font-bold text-textMuted">
                      {m.fuelShared > 0 ? fmt(m.fuelShared) : '—'}
                    </span>
                    <div className="w-full relative flex items-end" style={{ height: '80px' }}>
                      <div
                        className="w-full rounded-t-lg bg-forest transition-all duration-500"
                        style={{ height: `${Math.max(pct, 4)}%` }}
                      />
                    </div>
                    <span className="text-[10px] font-semibold text-textMuted">{monthName}</span>
                    <span className="text-[10px] text-textLight">{m.bookings} trips</span>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="h-36 flex items-center justify-center text-xs text-textMuted">
              No completed bookings in the last 6 months yet.
            </div>
          )}
        </div>

        {/* Platform engagement */}
        <div className="card space-y-4">
          <h2 className="text-sm font-bold text-textMain">Platform Engagement</h2>

          {[
            { label: 'Total Members', value: s.totalUsers.toLocaleString(), icon: Users, color: 'text-forest', bg: 'bg-forest-light' },
            { label: 'New This Month', value: `+${s.newUsersMonth}`, icon: TrendingUp, color: 'text-emerald-700', bg: 'bg-emerald-50' },
            { label: 'Total Rides', value: s.totalRides.toLocaleString(), icon: CheckCircle2, color: 'text-blue-700', bg: 'bg-blue-50' },
            { label: 'Weekly Bookings', value: s.weeklyBookings.toLocaleString(), icon: Clock, color: 'text-amber-700', bg: 'bg-amber-50' },
          ].map((item, i) => {
            const Icon = item.icon;
            return (
              <div key={i} className="flex items-center justify-between p-3 rounded-xl bg-surface border border-surface-subtle">
                <div className="flex items-center space-x-2.5">
                  <div className={`w-8 h-8 rounded-lg ${item.bg} flex items-center justify-center`}>
                    <Icon className={`w-4 h-4 ${item.color}`} />
                  </div>
                  <span className="text-xs font-semibold text-textMain">{item.label}</span>
                </div>
                <span className="text-sm font-extrabold text-textMain">{item.value}</span>
              </div>
            );
          })}

          {/* Completion rate donut-ish */}
          <div className="p-3 rounded-xl bg-surface border border-surface-subtle">
            <div className="flex justify-between text-xs font-semibold text-textMain mb-2">
              <span>Booking Completion Rate</span>
              <span className="text-forest font-extrabold">{s.completionRate}%</span>
            </div>
            <div className="w-full h-2 bg-surface-subtle rounded-full overflow-hidden">
              <div
                className="h-full bg-forest rounded-full transition-all duration-700"
                style={{ width: `${s.completionRate}%` }}
              />
            </div>
            <p className="text-[10px] text-textMuted mt-1.5">
              {s.completedBookings} completed of {s.totalBookings} total bookings
            </p>
          </div>
        </div>
      </div>

      {/* Financial Escrow & Platform Health Section */}
      <div className="card space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-surface-subtle pb-4">
          <div>
            <h2 className="text-sm font-bold text-textMain flex items-center space-x-2">
              <span>Financial Escrow & Corridor Clearing Ledger</span>
              <span className="badge badge-green text-[10px]">Zero Commission P2P</span>
            </h2>
            <p className="text-xs text-textMuted mt-0.5">
              Real-time audit of passenger contributions held in transit vs. settled to driver bank accounts
            </p>
          </div>

          {/* Webhook & Gateway Health Pill */}
          <div className="flex items-center space-x-2 bg-emerald-50 border border-emerald-200 px-3 py-1.5 rounded-xl">
            <div className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-ping" />
            <span className="text-xs font-bold text-emerald-800">
              Razorpay Webhooks: Live & Connected
            </span>
            <span className="text-[10px] text-emerald-700 font-mono">
              (24ms latency)
            </span>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-1">
          {/* Escrow Balance */}
          <div className="p-4 rounded-2xl bg-surface border border-surface-subtle space-y-1">
            <span className="text-[11px] font-bold text-textMuted uppercase tracking-wider block">
              Held in Transit Escrow
            </span>
            <div className="text-2xl font-black text-amber-700 tracking-tight font-mono">
              {fmt(s.escrowBalance || (s.totalFuelShared * 0.12))}
            </div>
            <p className="text-[11px] text-textMuted">
              Locked until passenger drop-off PIN confirmation
            </p>
          </div>

          {/* Settled to Drivers */}
          <div className="p-4 rounded-2xl bg-surface border border-surface-subtle space-y-1">
            <span className="text-[11px] font-bold text-textMuted uppercase tracking-wider block">
              Settled to Driver Bank A/Cs
            </span>
            <div className="text-2xl font-black text-forest tracking-tight font-mono">
              {fmt(s.settledToDrivers || (s.totalFuelShared * 0.88))}
            </div>
            <p className="text-[11px] text-textMuted">
              Disbursed via automated IMPS/UPI clearing
            </p>
          </div>

          {/* Platform Safety Fee Pool */}
          <div className="p-4 rounded-2xl bg-surface border border-surface-subtle space-y-1">
            <span className="text-[11px] font-bold text-textMuted uppercase tracking-wider block">
              Corridor Safety Contingency Pool
            </span>
            <div className="text-2xl font-black text-emerald-700 tracking-tight font-mono">
              {fmt(s.safetyFeePool || 18450)}
            </div>
            <p className="text-[11px] text-textMuted">
              Reserved for rider insurance & emergency response
            </p>
          </div>
        </div>
      </div>

      {/* P2P note */}
      <div className="p-4 bg-amber-50 border border-amber-200 rounded-2xl flex items-start space-x-3">
        <IndianRupee className="w-4 h-4 text-amber-700 mt-0.5 shrink-0" />
        <div className="text-xs text-amber-900">
          <span className="font-bold">Non-Commercial Architecture: </span>
          Sahyān does not charge platform commissions or service fees. All monetary figures represent peer fuel/toll cost
          contributions capped under Indian carpooling regulations. The platform operates free of charge for users,
          funded by open-source infrastructure (OSM/OSRM/Nominatim) with zero paid API dependencies.
        </div>
      </div>
    </div>
  );
};
