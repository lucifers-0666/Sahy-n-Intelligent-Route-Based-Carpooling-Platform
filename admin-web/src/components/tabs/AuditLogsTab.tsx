import React, { useState, useEffect, useCallback } from 'react';
import { AuditLogItem } from '../../types/admin';
import { adminApi } from '../../services/api';
import {
  ScrollText,
  ChevronLeft,
  ChevronRight,
  Filter,
  Clock,
  User,
  ShieldAlert,
  ShieldCheck,
  FileCheck,
  FileX,
  AlertTriangle,
  CheckCircle2,
  XCircle,
  Ban,
  RefreshCw,
} from 'lucide-react';

const ACTION_LABELS: Record<string, { label: string; color: string; badgeClass: string; Icon: React.ComponentType<{ className?: string }> }> = {
  DRIVER_SUSPENDED:   { label: 'Driver Suspended',    color: 'text-rose-700',   badgeClass: 'badge-red',    Icon: Ban },
  DRIVER_REACTIVATED: { label: 'Driver Reactivated',  color: 'text-emerald-700',badgeClass: 'badge-green',  Icon: ShieldCheck },
  DRIVER_VERIFIED:    { label: 'Driver Verified',      color: 'text-emerald-700',badgeClass: 'badge-green',  Icon: FileCheck },
  DRIVER_REJECTED:    { label: 'Driver Rejected',      color: 'text-rose-700',   badgeClass: 'badge-red',    Icon: FileX },
  RIDE_MODERATED:     { label: 'Ride Moderated',       color: 'text-amber-700',  badgeClass: 'badge-amber',  Icon: AlertTriangle },
  RIDE_CANCELLED:     { label: 'Ride Cancelled',       color: 'text-rose-700',   badgeClass: 'badge-red',    Icon: XCircle },
  REPORT_RESOLVED:    { label: 'Report Resolved',      color: 'text-emerald-700',badgeClass: 'badge-green',  Icon: CheckCircle2 },
  REPORT_DISMISSED:   { label: 'Report Dismissed',     color: 'text-gray-600',   badgeClass: 'badge-gray',   Icon: XCircle },
  BOOKING_CANCELLED:  { label: 'Booking Cancelled',    color: 'text-amber-700',  badgeClass: 'badge-amber',  Icon: XCircle },
  USER_DELETED:       { label: 'User Deleted',         color: 'text-rose-700',   badgeClass: 'badge-red',    Icon: User },
  CONFIG_UPDATED:     { label: 'Config Updated',       color: 'text-purple-700', badgeClass: 'badge-purple', Icon: RefreshCw },
  ADMIN_LOGIN:        { label: 'Admin Login',           color: 'text-blue-700',   badgeClass: 'badge-blue',   Icon: ShieldAlert },
};

const ALL_ACTIONS = ['all', ...Object.keys(ACTION_LABELS)];
const PAGE_SIZE = 20;

function formatTimeAgo(dateStr: string) {
  const diff = Date.now() - new Date(dateStr).getTime();
  const s = Math.floor(diff / 1000);
  if (s < 60) return `${s}s ago`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  return `${d}d ago`;
}

function formatDateTime(dateStr: string) {
  return new Date(dateStr).toLocaleString('en-IN', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  });
}

export const AuditLogsTab: React.FC = () => {
  const [logs, setLogs] = useState<AuditLogItem[]>([]);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [actionFilter, setActionFilter] = useState('all');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [expanded, setExpanded] = useState<string | null>(null);

  const fetchLogs = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await adminApi.getAuditLogs({
        page,
        limit: PAGE_SIZE,
        action: actionFilter,
        startDate: startDate || undefined,
        endDate: endDate || undefined,
      });
      setLogs(data.logs);
      setTotal(data.total);
      setTotalPages(data.totalPages);
    } catch (e: any) {
      setError(e.message || 'Failed to load audit logs');
    } finally {
      setLoading(false);
    }
  }, [page, actionFilter, startDate, endDate]);

  useEffect(() => {
    fetchLogs();
  }, [fetchLogs]);

  // Reset to page 1 when filter changes
  useEffect(() => {
    setPage(1);
  }, [actionFilter, startDate, endDate]);

  const handleClearDates = () => {
    setStartDate('');
    setEndDate('');
  };

  const meta = (action: string) =>
    ACTION_LABELS[action] ?? { label: action, color: 'text-textMuted', badgeClass: 'badge-gray', Icon: Clock };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="section-title flex items-center gap-2">
            <ScrollText className="w-5 h-5 text-forest" />
            Admin Audit Logs
          </h1>
          <p className="section-subtitle">
            Complete chronological record of all administrative actions · {total.toLocaleString()} entries
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2 shrink-0">
          {/* Action Filter */}
          <div className="flex items-center gap-1.5">
            <Filter className="w-4 h-4 text-textMuted" />
            <select
              className="select text-xs"
              value={actionFilter}
              onChange={(e) => setActionFilter(e.target.value)}
            >
              {ALL_ACTIONS.map((a) => (
                <option key={a} value={a}>
                  {a === 'all' ? 'All Actions' : ACTION_LABELS[a]?.label ?? a}
                </option>
              ))}
            </select>
          </div>

          {/* Date Range Filtering */}
          <div className="flex items-center gap-1.5 bg-white px-2.5 py-1 rounded-xl border border-surface-subtle text-xs">
            <Clock className="w-3.5 h-3.5 text-textMuted" />
            <span className="text-[11px] text-textMuted font-medium">From:</span>
            <input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="bg-transparent border-0 text-textMain text-xs focus:outline-none"
            />
            <span className="text-[11px] text-textMuted font-medium">To:</span>
            <input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className="bg-transparent border-0 text-textMain text-xs focus:outline-none"
            />
            {(startDate || endDate) && (
              <button
                onClick={handleClearDates}
                className="text-[11px] font-semibold text-rose-600 hover:text-rose-800 ml-1 cursor-pointer"
                title="Clear date range filter"
              >
                Clear
              </button>
            )}
          </div>

          <button
            onClick={fetchLogs}
            className="btn-ghost"
            title="Refresh"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Table */}
      <div className="card p-0 overflow-hidden">
        {loading ? (
          <div className="p-6 space-y-3">
            {[...Array(8)].map((_, i) => (
              <div key={i} className="skeleton h-14 rounded-xl" />
            ))}
          </div>
        ) : error ? (
          <div className="empty-state">
            <div className="empty-state-icon"><ScrollText className="w-6 h-6" /></div>
            <p className="text-sm font-bold text-textMain">Failed to load audit logs</p>
            <p className="text-xs text-textMuted mt-1">{error}</p>
            <button onClick={fetchLogs} className="btn-primary mt-4">Retry</button>
          </div>
        ) : logs.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon"><CheckCircle2 className="w-6 h-6 text-forest" /></div>
            <p className="text-sm font-bold text-textMain">No audit entries found</p>
            <p className="text-xs text-textMuted mt-1">
              {actionFilter !== 'all' ? 'Try removing the action filter.' : 'Admin actions will appear here once performed.'}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-surface border-b border-surface-subtle">
                <tr>
                  <th className="table-header">Action</th>
                  <th className="table-header">Admin</th>
                  <th className="table-header">Target User</th>
                  <th className="table-header">Reason</th>
                  <th className="table-header">Time</th>
                </tr>
              </thead>
              <tbody>
                {logs.map((log) => {
                  const m = meta(log.action);
                  const Icon = m.Icon;
                  const isExpanded = expanded === log._id;
                  return (
                    <React.Fragment key={log._id}>
                      <tr
                        className={`table-row cursor-pointer ${isExpanded ? 'bg-surface/60' : ''}`}
                        onClick={() => setExpanded(isExpanded ? null : log._id)}
                      >
                        <td className="table-cell">
                          <div className="flex items-center gap-2">
                            <Icon className={`w-4 h-4 ${m.color} shrink-0`} />
                            <span className={`badge ${m.badgeClass}`}>{m.label}</span>
                          </div>
                        </td>
                        <td className="table-cell">
                          <div className="font-semibold text-textMain text-xs">
                            {log.admin?.name || '—'}
                          </div>
                          <div className="text-[10px] text-textMuted">{log.admin?.email || ''}</div>
                        </td>
                        <td className="table-cell">
                          {log.targetUser ? (
                            <>
                              <div className="font-semibold text-textMain text-xs">{log.targetUser.name}</div>
                              <div className="text-[10px] text-textMuted">{log.targetUser.email}</div>
                            </>
                          ) : (
                            <span className="text-xs text-textMuted">—</span>
                          )}
                        </td>
                        <td className="table-cell max-w-xs">
                          <p className="text-xs text-textMuted truncate">{log.reason || '—'}</p>
                        </td>
                        <td className="table-cell whitespace-nowrap">
                          <div className="text-xs font-semibold text-textMain">{formatTimeAgo(log.createdAt)}</div>
                          <div className="text-[10px] text-textMuted">{formatDateTime(log.createdAt)}</div>
                        </td>
                      </tr>
                      {isExpanded && (
                        <tr className="bg-surface/60">
                          <td colSpan={5} className="px-6 pb-4 pt-2">
                            <div className="p-4 rounded-xl bg-white border border-surface-subtle text-xs space-y-2">
                              <div className="font-bold text-textMain mb-2">Full Audit Detail</div>
                              <div className="grid grid-cols-2 gap-2">
                                <div>
                                  <span className="text-textMuted">Log ID:</span>{' '}
                                  <span className="font-mono text-textMain">{log._id}</span>
                                </div>
                                <div>
                                  <span className="text-textMuted">Timestamp:</span>{' '}
                                  <span className="text-textMain">{formatDateTime(log.createdAt)}</span>
                                </div>
                                <div>
                                  <span className="text-textMuted">Action:</span>{' '}
                                  <span className="font-bold text-textMain">{log.action}</span>
                                </div>
                                <div>
                                  <span className="text-textMuted">Admin ID:</span>{' '}
                                  <span className="font-mono text-textMain">{log.admin?._id || '—'}</span>
                                </div>
                              </div>
                              <div>
                                <span className="text-textMuted">Reason:</span>{' '}
                                <span className="text-textMain">{log.reason || '(none recorded)'}</span>
                              </div>
                              {log.metadata && Object.keys(log.metadata).length > 0 && (
                                <div>
                                  <span className="text-textMuted block mb-1">Metadata:</span>
                                  <pre className="bg-surface rounded-lg p-3 font-mono text-[10px] text-textMain overflow-x-auto">
                                    {JSON.stringify(log.metadata, null, 2)}
                                  </pre>
                                </div>
                              )}
                            </div>
                          </td>
                        </tr>
                      )}
                    </React.Fragment>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Pagination */}
      {!loading && !error && totalPages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-xs text-textMuted">
            Page {page} of {totalPages} · {total.toLocaleString()} total entries
          </p>
          <div className="flex items-center gap-2">
            <button
              disabled={page <= 1}
              onClick={() => setPage((p) => p - 1)}
              className="btn-secondary flex items-center gap-1 text-xs disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <ChevronLeft className="w-3.5 h-3.5" />
              Prev
            </button>
            <button
              disabled={page >= totalPages}
              onClick={() => setPage((p) => p + 1)}
              className="btn-secondary flex items-center gap-1 text-xs disabled:opacity-40 disabled:cursor-not-allowed"
            >
              Next
              <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
