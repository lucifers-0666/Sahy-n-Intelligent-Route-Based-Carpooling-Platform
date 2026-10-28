import React, { useState, useEffect } from 'react';
import { SystemTelemetryData } from '../../types/admin';
import { adminApi } from '../../services/api';
import {
  Activity,
  Database,
  Radio,
  Cpu,
  ShieldCheck,
  Server,
  RefreshCw,
  Clock,
  CheckCircle2,
  AlertTriangle,
} from 'lucide-react';

export const OperationalTab: React.FC = () => {
  const [telemetry, setTelemetry] = useState<SystemTelemetryData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [autoRefresh, setAutoRefresh] = useState(true);

  const fetchTelemetry = async () => {
    try {
      const data = await adminApi.getSystemTelemetry();
      setTelemetry(data);
      setError(null);
    } catch (err: any) {
      setError(err.message || 'Failed to poll operational telemetry');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTelemetry();
    let interval: any = null;
    if (autoRefresh) {
      interval = setInterval(fetchTelemetry, 5000);
    }
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [autoRefresh]);

  const formatUptime = (seconds: number) => {
    const days = Math.floor(seconds / 86400);
    const hrs = Math.floor((seconds % 86400) / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    if (days > 0) return `${days}d ${hrs}h ${mins}m`;
    if (hrs > 0) return `${hrs}h ${mins}m ${secs}s`;
    return `${mins}m ${secs}s`;
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-extrabold text-textMain tracking-tight">System & Telematics Operations</h2>
          <p className="text-xs text-textMuted mt-0.5">
            Real-time infrastructure health, cluster latency, Socket.IO rooms, and backend telemetry
          </p>
        </div>
        <div className="flex items-center space-x-2">
          <label className="flex items-center space-x-1.5 text-xs text-textMuted cursor-pointer bg-white px-3 py-1.5 rounded-xl border border-border">
            <input
              type="checkbox"
              checked={autoRefresh}
              onChange={(e) => setAutoRefresh(e.target.checked)}
              className="rounded text-forest focus:ring-forest"
            />
            <span>Auto-poll (5s)</span>
          </label>
          <button
            onClick={fetchTelemetry}
            className="btn-secondary py-1.5 px-3 text-xs flex items-center space-x-1"
          >
            <RefreshCw className="w-3.5 h-3.5" />
            <span>Refresh</span>
          </button>
        </div>
      </div>

      {loading && !telemetry ? (
        <div className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {[...Array(3)].map((_, i) => (
              <div key={i} className="skeleton h-28 rounded-2xl" />
            ))}
          </div>
          <div className="skeleton h-64 rounded-2xl" />
        </div>
      ) : error ? (
        <div className="card text-center py-10 space-y-3">
          <AlertTriangle className="w-8 h-8 text-amber-600 mx-auto" />
          <div className="text-sm font-semibold text-textMain">{error}</div>
          <button onClick={fetchTelemetry} className="btn-secondary text-xs">Retry Polling</button>
        </div>
      ) : telemetry ? (
        <div className="space-y-6">
          {/* Top Status Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            {/* MongoDB Health */}
            <div className="card border-l-4 border-emerald-500 space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-[11px] font-semibold text-textMuted uppercase tracking-wider">Database Cluster</span>
                <Database className="w-4 h-4 text-emerald-700" />
              </div>
              <div className="flex items-baseline space-x-2">
                <span className="text-2xl font-extrabold text-emerald-900 capitalize">
                  {telemetry.database.status}
                </span>
                {telemetry.database.latencyMs !== null && (
                  <span className="text-xs font-mono font-bold text-emerald-700">
                    ({telemetry.database.latencyMs}ms ping)
                  </span>
                )}
              </div>
              <div className="text-[11px] text-textMuted truncate">
                Host: {telemetry.database.host}
              </div>
            </div>

            {/* Socket.IO Telematics */}
            <div className="card border-l-4 border-blue-500 space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-[11px] font-semibold text-textMuted uppercase tracking-wider">Telematics Engine</span>
                <Radio className="w-4 h-4 text-blue-700" />
              </div>
              <div className="flex items-baseline space-x-2">
                <span className="text-2xl font-extrabold text-blue-900 font-mono">
                  {telemetry.telematics.activeSocketRooms}
                </span>
                <span className="text-xs font-semibold text-textMuted">Active Corridor Rooms</span>
              </div>
              <div className="text-[11px] text-textMuted">
                Protocol: {telemetry.telematics.protocol}
              </div>
            </div>

            {/* Server Process Uptime */}
            <div className="card border-l-4 border-forest space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-[11px] font-semibold text-textMuted uppercase tracking-wider">Process Uptime</span>
                <Clock className="w-4 h-4 text-forest" />
              </div>
              <div className="text-2xl font-extrabold text-forest font-mono">
                {formatUptime(telemetry.uptimeSeconds)}
              </div>
              <div className="text-[11px] text-textMuted">
                Timestamp: {new Date(telemetry.serverTime).toLocaleTimeString()}
              </div>
            </div>
          </div>

          {/* Subsystem Services Details */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Integrated Gateways & Auth */}
            <div className="card space-y-4">
              <div className="flex items-center space-x-2 border-b border-border pb-3">
                <ShieldCheck className="w-4 h-4 text-forest" />
                <h3 className="text-sm font-bold text-textMain">Connected Subsystems</h3>
              </div>

              <div className="space-y-3 text-xs">
                <div className="flex items-center justify-between p-3 rounded-xl bg-gray-50 border border-border">
                  <div>
                    <div className="font-semibold text-textMain">SMS / OTP Dispatch Subsystem</div>
                    <div className="text-[11px] text-textMuted">Two-factor phone authentication</div>
                  </div>
                  <span className={`px-2.5 py-1 text-[11px] font-bold rounded-full ${
                    telemetry.services.smsGateway === 'live_fast2sms'
                      ? 'bg-emerald-100 text-emerald-900 border border-emerald-300'
                      : 'bg-amber-100 text-amber-900 border border-amber-300'
                  }`}>
                    {telemetry.services.smsGateway === 'live_fast2sms' ? 'Fast2SMS Production' : 'Development Mock Engine'}
                  </span>
                </div>

                <div className="flex items-center justify-between p-3 rounded-xl bg-gray-50 border border-border">
                  <div>
                    <div className="font-semibold text-textMain">Firebase Auth Interop</div>
                    <div className="text-[11px] text-textMuted">Token verification & OAuth federation</div>
                  </div>
                  <span className={`px-2.5 py-1 text-[11px] font-bold rounded-full ${
                    telemetry.services.firebaseAuth === 'configured'
                      ? 'bg-emerald-100 text-emerald-900 border border-emerald-300'
                      : 'bg-blue-100 text-blue-900 border border-blue-300'
                  }`}>
                    {telemetry.services.firebaseAuth === 'configured' ? 'Firebase Live' : 'Mock Development Mode'}
                  </span>
                </div>

                <div className="flex items-center justify-between p-3 rounded-xl bg-gray-50 border border-border">
                  <div>
                    <div className="font-semibold text-textMain">JWT Secret Cryptography</div>
                    <div className="text-[11px] text-textMuted">Session authenticity signature</div>
                  </div>
                  <span className={`px-2.5 py-1 text-[11px] font-bold rounded-full ${
                    telemetry.services.jwtSignature
                      ? 'bg-emerald-100 text-emerald-900 border border-emerald-300'
                      : 'bg-red-100 text-red-900 border border-red-300'
                  }`}>
                    {telemetry.services.jwtSignature ? 'Signed & Verified' : 'Missing Key'}
                  </span>
                </div>
              </div>
            </div>

            {/* Memory & Host Metrics */}
            <div className="card space-y-4">
              <div className="flex items-center space-x-2 border-b border-border pb-3">
                <Cpu className="w-4 h-4 text-forest" />
                <h3 className="text-sm font-bold text-textMain">Node.js Process Footprint</h3>
              </div>

              <div className="space-y-4 text-xs">
                <div>
                  <div className="flex justify-between font-semibold mb-1">
                    <span className="text-textMuted">Resident Set Size (RSS):</span>
                    <span className="font-mono text-textMain">{telemetry.memory.rssMb} MB</span>
                  </div>
                  <div className="w-full bg-gray-200 h-2 rounded-full overflow-hidden">
                    <div
                      className="bg-forest h-full rounded-full transition-all"
                      style={{ width: `${Math.min(100, (telemetry.memory.rssMb / 512) * 100)}%` }}
                    />
                  </div>
                </div>

                <div>
                  <div className="flex justify-between font-semibold mb-1">
                    <span className="text-textMuted">V8 Heap Memory:</span>
                    <span className="font-mono text-textMain">
                      {telemetry.memory.heapUsedMb} MB used / {telemetry.memory.heapTotalMb} MB allocated
                    </span>
                  </div>
                  <div className="w-full bg-gray-200 h-2 rounded-full overflow-hidden">
                    <div
                      className="bg-emerald-600 h-full rounded-full transition-all"
                      style={{
                        width: `${Math.min(100, (telemetry.memory.heapUsedMb / telemetry.memory.heapTotalMb) * 100)}%`,
                      }}
                    />
                  </div>
                </div>

                <div className="p-3 bg-forest-light rounded-xl border border-forest/20 text-forest text-[11px] leading-relaxed">
                  Memory allocation is optimized with streaming JSON pipelines and fail-closed garbage collection.
                </div>
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
};
