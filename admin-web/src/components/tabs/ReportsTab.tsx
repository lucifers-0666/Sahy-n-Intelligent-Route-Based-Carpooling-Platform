import React, { useState, useEffect } from 'react';
import { ReportItem } from '../../types/admin';
import { adminApi } from '../../services/api';
import {
  AlertTriangle,
  CheckCircle2,
  Clock,
  Shield,
  X,
  FileCheck2,
} from 'lucide-react';

export const ReportsTab: React.FC = () => {
  const [reports, setReports] = useState<ReportItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>('open');

  // Selected report for resolution dialog
  const [selectedReport, setSelectedReport] = useState<ReportItem | null>(null);
  const [resolveStatus, setResolveStatus] = useState<'resolved' | 'dismissed'>('resolved');
  const [resolutionNotes, setResolutionNotes] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  const fetchReports = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await adminApi.getReports({
        status: statusFilter === 'all' ? undefined : statusFilter,
      });
      setReports(data);
    } catch (err: any) {
      setError(err.message || 'Failed to load safety reports');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReports();
  }, [statusFilter]);

  const handleResolveReport = async (reportId: string) => {
    if (!resolutionNotes.trim()) {
      alert('Please enter resolution notes explaining the action taken.');
      return;
    }

    setActionLoading(true);
    try {
      await adminApi.resolveReport(reportId, resolveStatus, resolutionNotes.trim());
      setSelectedReport(null);
      setResolutionNotes('');
      fetchReports();
    } catch (err: any) {
      alert(`Resolution failed: ${err.message}`);
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header and filters */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-extrabold text-textMain tracking-tight">
            Safety Incidents & Passenger Support Queue
          </h1>
          <p className="text-xs text-textMuted font-medium mt-0.5">
            Handle reported harassment, route deviation disputes, vehicle condition flags, and emergency escalations.
          </p>
        </div>

        {/* Status Filter */}
        <div className="flex items-center space-x-1 bg-white p-1 rounded-xl border border-surface-subtle shadow-xs">
          {[
            { id: 'open', label: 'Open Incidents' },
            { id: 'investigating', label: 'Under Review' },
            { id: 'resolved', label: 'Resolved' },
            { id: 'all', label: 'All Reports' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setStatusFilter(tab.id)}
              className={`px-3 py-1.5 text-xs font-bold rounded-lg transition-colors cursor-pointer ${
                statusFilter === tab.id
                  ? 'bg-forest text-white'
                  : 'text-textMuted hover:text-textMain hover:bg-surface'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      {/* Reports List */}
      {loading ? (
        <div className="bg-white rounded-2xl p-12 text-center text-textMuted text-xs">
          Loading safety incident reports from database...
        </div>
      ) : error ? (
        <div className="bg-rose-50 border border-rose-200 rounded-2xl p-6 text-center text-rose-800 text-xs">
          {error}
        </div>
      ) : reports.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center border border-surface-subtle shadow-xs">
          <Shield className="w-10 h-10 text-emerald-600 mx-auto mb-2" />
          <h3 className="text-sm font-bold text-textMain">No Safety Incidents In Queue</h3>
          <p className="text-xs text-textMuted mt-1">
            {statusFilter === 'open'
              ? 'All passenger and trip safety reports have been resolved.'
              : 'No incident reports found for the selected filter.'}
          </p>
        </div>
      ) : (
        <div className="bg-white rounded-2xl border border-surface-subtle shadow-xs overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-surface text-textMuted font-bold uppercase tracking-wider border-b border-surface-subtle">
                <tr>
                  <th className="py-3 px-4">Priority & Category</th>
                  <th className="py-3 px-4">Description</th>
                  <th className="py-3 px-4">Reporter</th>
                  <th className="py-3 px-4">Reported Party</th>
                  <th className="py-3 px-4">Status</th>
                  <th className="py-3 px-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-subtle">
                {reports.map((report) => {
                  const isPending = report.status === 'open' || report.status === 'investigating' || (report.status as any) === 'pending';
                  const priority = report.severity || report.priority || 'medium';
                  const categoryName = report.title || report.category || report.type || 'Safety Concern';
                  return (
                    <tr key={report._id} className="hover:bg-surface/50 transition-colors">
                      <td className="py-3.5 px-4">
                        <span
                          className={`inline-block px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                            priority === 'critical'
                              ? 'bg-rose-100 text-rose-800'
                              : priority === 'high'
                              ? 'bg-orange-100 text-orange-800'
                              : 'bg-amber-100 text-amber-800'
                          }`}
                        >
                          {priority}
                        </span>
                        <div className="font-bold text-textMain mt-1">
                          {categoryName}
                        </div>
                      </td>

                      <td className="py-3.5 px-4 max-w-xs">
                        <p className="text-textMain line-clamp-2">{report.description}</p>
                        <span className="text-[10px] text-textMuted mt-0.5 block">
                          Reported on {new Date(report.createdAt).toLocaleDateString()}
                        </span>
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="font-bold text-textMain">{report.reporter?.name || 'Rider'}</div>
                        <div className="text-[11px] text-textMuted">{report.reporter?.email || 'N/A'}</div>
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="font-bold text-textMain">{report.reportedUser?.name || 'Driver / Co-Rider'}</div>
                        <div className="text-[11px] text-textMuted">{report.reportedUser?.role || 'User'}</div>
                      </td>

                      <td className="py-3.5 px-4">
                        <span
                          className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                            isPending
                              ? 'bg-amber-50 text-amber-800 border border-amber-200'
                              : 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                          }`}
                        >
                          {report.status.toUpperCase()}
                        </span>
                      </td>

                      <td className="py-3.5 px-4 text-right">
                        {isPending ? (
                          <button
                            onClick={() => {
                              setSelectedReport(report);
                              setResolutionNotes('');
                              setResolveStatus('resolved');
                            }}
                            className="px-3 py-1.5 bg-forest-light text-forest hover:bg-forest hover:text-white rounded-lg font-bold text-xs transition-colors cursor-pointer"
                          >
                            Resolve
                          </button>
                        ) : (
                          <span className="text-textMuted text-[11px]">Closed</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Resolution Dialog Modal */}
      {selectedReport && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-xl border border-surface-subtle space-y-5">
            <div className="flex items-start justify-between">
              <div>
                <span className="text-xs font-bold text-forest uppercase tracking-wider flex items-center space-x-1">
                  <FileCheck2 className="w-3.5 h-3.5" />
                  <span>Incident Resolution Workflow</span>
                </span>
                <h3 className="text-lg font-extrabold text-textMain mt-1">
                  Resolve Safety Report #{selectedReport._id.slice(-6)}
                </h3>
              </div>
              <button
                onClick={() => setSelectedReport(null)}
                className="p-1 rounded-lg text-textMuted hover:bg-surface cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-3.5 bg-surface rounded-2xl border border-surface-subtle text-xs space-y-1">
              <span className="font-bold text-textMain">Report Summary:</span>
              <p className="text-textMuted">{selectedReport.description}</p>
            </div>

            <div>
              <label className="block text-xs font-bold text-textMain mb-1">
                Resolution Outcome:
              </label>
              <select
                value={resolveStatus}
                onChange={(e) => setResolveStatus(e.target.value as any)}
                className="w-full bg-white p-2.5 text-xs rounded-xl border border-surface-subtle focus:outline-none focus:border-forest text-textMain font-medium"
              >
                <option value="resolved">Resolved (Corrective Action Taken / Warning Issued)</option>
                <option value="dismissed">Dismissed (False Flag / Inconclusive Evidence)</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold text-textMain mb-1">
                Resolution Notes & Audit Log:
              </label>
              <textarea
                placeholder="Document the outcome, passenger outreach, or driver counseling applied..."
                value={resolutionNotes}
                onChange={(e) => setResolutionNotes(e.target.value)}
                rows={3}
                className="w-full bg-white p-3 text-xs rounded-xl border border-surface-subtle focus:outline-none focus:border-forest text-textMain"
              />
            </div>

            <div className="flex gap-3 pt-2">
              <button
                onClick={() => setSelectedReport(null)}
                className="flex-1 py-2.5 px-4 rounded-xl border border-gray-200 text-textMuted font-bold text-xs hover:bg-gray-50 transition-colors cursor-pointer"
              >
                Cancel
              </button>
              <button
                onClick={() => handleResolveReport(selectedReport._id)}
                disabled={actionLoading}
                className="flex-1 py-2.5 px-4 rounded-xl bg-forest hover:bg-forest-dark text-white font-bold text-xs transition-colors shadow-sm cursor-pointer"
              >
                {actionLoading ? 'Saving...' : 'Complete Resolution'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
