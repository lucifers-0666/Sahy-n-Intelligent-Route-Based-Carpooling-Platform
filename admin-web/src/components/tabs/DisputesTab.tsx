import React, { useState, useEffect } from 'react';
import { DisputeCase } from '../../types/admin';
import { adminApi } from '../../services/api';
import { PageHeader } from '../ui/PageHeader';
import { Badge } from '../ui/Badge';
import { EmptyState } from '../ui/EmptyState';
import { ErrorState } from '../ui/ErrorState';
import { Pagination } from '../ui/Pagination';
import {
  BookmarkX,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  Scale,
  Search,
  IndianRupee,
  Calendar,
  MapPin,
  Clock,
  X,
  FileText,
  User,
  ShieldAlert,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { hasCapability } from '../../utils/rbac';

export const DisputesTab: React.FC = () => {
  const { user } = useAuth();
  const canResolve = hasCapability(user?.role, 'VIEW_DISPUTES');

  const [disputes, setDisputes] = useState<DisputeCase[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [totalItems, setTotalItems] = useState(0);
  const pageSize = 15;

  // Selected dispute case for resolution
  const [selectedCase, setSelectedCase] = useState<DisputeCase | null>(null);
  const [resolutionOutcome, setResolutionOutcome] = useState<string>('resolved_paid');
  const [resolutionNotes, setResolutionNotes] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [feedback, setFeedback] = useState<string | null>(null);

  const fetchDisputes = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await adminApi.getDisputes({
        status: statusFilter === 'all' ? undefined : statusFilter,
        search: search.trim() || undefined,
        page,
        limit: pageSize,
      });

      const list = Array.isArray(data)
        ? data
        : (data as any)?.data || (data as any)?.disputes || [];
      const total = (data as any)?.total ?? list.length;

      setDisputes(list);
      setTotalItems(total);
    } catch (err: any) {
      setError(err.message || 'Failed to load dispute cases.');
      setDisputes([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDisputes();
  }, [statusFilter, page]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
    fetchDisputes();
  };

  const handleResolveCase = async () => {
    if (!selectedCase) return;
    if (resolutionNotes.trim().length < 5) {
      alert('Please specify a meaningful resolution note (min 5 characters).');
      return;
    }

    setSubmitting(true);
    try {
      await adminApi.resolveDispute(selectedCase._id, resolutionOutcome, resolutionNotes.trim());
      setFeedback('Dispute case resolved successfully with immutable audit logging.');
      setSelectedCase(null);
      setResolutionNotes('');
      fetchDisputes();
      setTimeout(() => setFeedback(null), 3500);
    } catch (err: any) {
      alert(`Resolution failed: ${err.message}`);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="Disputes & Payment Reconciliation"
        subtitle="Investigate peer non-payment complaints, review passenger rebuttal statements, and record authoritative settlements."
        breadcrumbs={[
          { label: 'Operations' },
          { label: 'Disputes' },
        ]}
      />

      {feedback && (
        <div className="p-3.5 bg-emerald-50 border border-emerald-200 text-emerald-950 rounded-xl text-xs font-semibold flex items-center justify-between animate-in fade-in">
          <div className="flex items-center space-x-2">
            <CheckCircle2 className="w-4 h-4 text-emerald-700" />
            <span>{feedback}</span>
          </div>
          <button onClick={() => setFeedback(null)} className="p-1 hover:bg-black/5 rounded">
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Toolbar & Filters */}
      <div className="card p-4 flex flex-col md:flex-row items-stretch md:items-center justify-between gap-4">
        <form onSubmit={handleSearchSubmit} className="relative flex-1">
          <Search className="w-4 h-4 text-textMuted absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search by booking or ride identifier..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-xs bg-surface rounded-xl border border-surface-subtle text-textMain placeholder-textMuted focus:outline-none focus:ring-2 focus:ring-forest/20 focus:border-forest transition-all"
          />
        </form>

        <div className="flex items-center space-x-1 bg-surface p-1 rounded-xl border border-surface-subtle overflow-x-auto">
          {[
            { id: 'all', label: 'All Disputes' },
            { id: 'driver_reported', label: 'Pending Review' },
            { id: 'passenger_disputed', label: 'Contested' },
            { id: 'resolved_paid', label: 'Settled Paid' },
            { id: 'penalty_applied', label: 'Penalized' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => {
                setStatusFilter(tab.id);
                setPage(1);
              }}
              className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-all cursor-pointer whitespace-nowrap ${
                statusFilter === tab.id
                  ? 'bg-forest text-white shadow-xs'
                  : 'text-textMuted hover:text-textMain hover:bg-white/50'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      {/* Main Table / View */}
      {loading ? (
        <div className="card p-12 text-center">
          <div className="w-8 h-8 border-2 border-forest border-t-transparent rounded-full animate-spin mx-auto mb-3" />
          <p className="text-xs font-semibold text-textMuted">Querying dispute claims from ledger...</p>
        </div>
      ) : error ? (
        <ErrorState
          title="Failed to Load Disputes"
          message={error}
          onRetry={fetchDisputes}
        />
      ) : disputes.length === 0 ? (
        <EmptyState
          icon={BookmarkX}
          title="No Active Disputes"
          description="There are currently no passenger non-payment or cash contribution disputes recorded in this queue."
        />
      ) : (
        <div className="card p-0 overflow-hidden shadow-xs">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-surface/60 text-textMuted font-bold uppercase tracking-wider text-[11px] border-b border-surface-subtle">
                <tr>
                  <th className="py-3.5 px-4">Booking / Trip</th>
                  <th className="py-3.5 px-4">Passenger</th>
                  <th className="py-3.5 px-4">Driver</th>
                  <th className="py-3.5 px-4">Agreed Split</th>
                  <th className="py-3.5 px-4">Dispute Status</th>
                  <th className="py-3.5 px-4 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-subtle">
                {disputes.map((d) => {
                  const disp = d.dispute;
                  const isResolved = disp?.status && disp.status.startsWith('resolved');
                  const origin = d.ride?.origin?.name || 'Origin';
                  const destination = d.ride?.destination?.name || 'Destination';

                  return (
                    <tr key={d._id} className="hover:bg-surface/50 transition-colors">
                      <td className="py-3.5 px-4">
                        <div className="font-bold text-textMain font-mono">#{d._id.slice(-6)}</div>
                        <div className="text-[11px] text-textMuted flex items-center space-x-1 mt-0.5">
                          <MapPin className="w-3 h-3 text-forest shrink-0" />
                          <span className="truncate max-w-[180px]">{origin} to {destination}</span>
                        </div>
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="font-bold text-textMain">{d.passenger?.name || 'Passenger'}</div>
                        <div className="text-[11px] text-textMuted font-mono">{d.passenger?.phone || 'N/A'}</div>
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="font-bold text-textMain">{d.ride?.driver?.name || 'Driver'}</div>
                        <div className="text-[11px] text-textMuted font-mono">{d.ride?.driver?.phone || 'N/A'}</div>
                      </td>

                      <td className="py-3.5 px-4 font-mono font-bold text-textMain">
                        ₹{d.totalContribution}
                      </td>

                      <td className="py-3.5 px-4">
                        <Badge
                          variant={
                            disp?.status === 'driver_reported'
                              ? 'amber'
                              : disp?.status === 'passenger_disputed'
                              ? 'rose'
                              : isResolved
                              ? 'emerald'
                              : 'gray'
                          }
                        >
                          {(disp?.status || 'open').replace(/_/g, ' ').toUpperCase()}
                        </Badge>
                        {disp?.driverReason && (
                          <div className="text-[11px] text-textMuted truncate max-w-[140px] mt-0.5">
                            {disp.driverReason}
                          </div>
                        )}
                      </td>

                      <td className="py-3.5 px-4 text-right">
                        {canResolve && (
                          <button
                            onClick={() => {
                              setSelectedCase(d);
                              setResolutionOutcome('resolved_paid');
                              setResolutionNotes('');
                            }}
                            className="px-3 py-1.5 bg-forest text-white rounded-lg text-xs font-bold hover:bg-forest-dark transition-colors cursor-pointer"
                          >
                            Review & Settle
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          <div className="p-4 border-t border-surface-subtle">
            <Pagination
              page={page}
              totalPages={Math.ceil(totalItems / pageSize)}
              totalItems={totalItems}
              pageSize={pageSize}
              onPageChange={setPage}
            />
          </div>
        </div>
      )}

      {/* Case Resolution Modal */}
      {selectedCase && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-in fade-in">
          <div className="w-full max-w-lg bg-white rounded-2xl shadow-xl p-6 space-y-4 border border-surface-subtle">
            <div className="flex items-center justify-between border-b border-surface-subtle pb-3">
              <div className="flex items-center space-x-2">
                <Scale className="w-5 h-5 text-forest" />
                <h3 className="text-base font-bold text-textMain">
                  Resolve Dispute: #{selectedCase._id.slice(-8)}
                </h3>
              </div>
              <button onClick={() => setSelectedCase(null)} className="p-1 rounded-lg hover:bg-surface text-textMuted">
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-3 bg-surface rounded-xl border border-surface-subtle space-y-1.5 text-xs">
              <div className="flex justify-between">
                <span className="text-textMuted font-bold uppercase text-[10px]">Agreed Fuel Split</span>
                <span className="font-mono font-bold text-textMain">₹{selectedCase.totalContribution}</span>
              </div>
              <div>
                <span className="text-textMuted block text-[10px] font-bold uppercase">Driver Claim:</span>
                <p className="text-textMain font-medium p-2 bg-white rounded-lg border border-surface-subtle mt-0.5">
                  "{selectedCase.dispute?.driverReason || 'Non-payment after arrival'}"
                </p>
              </div>
              {selectedCase.dispute?.passengerResponse && (
                <div>
                  <span className="text-textMuted block text-[10px] font-bold uppercase">Passenger Rebuttal:</span>
                  <p className="text-textMain font-medium p-2 bg-white rounded-lg border border-surface-subtle mt-0.5">
                    "{selectedCase.dispute.passengerResponse}"
                  </p>
                </div>
              )}
            </div>

            <div className="space-y-1.5 text-xs">
              <label className="block font-bold text-textMain">Settlement Outcome</label>
              <div className="grid grid-cols-2 gap-2">
                {[
                  { id: 'resolved_paid', label: 'Mark as Paid', desc: 'Verify cash or UPI payment confirmed' },
                  { id: 'penalty_applied', label: 'Apply Penalty', desc: 'Revoke passenger cash privileges' },
                  { id: 'resolved_forgiven', label: 'Forgive Claim', desc: 'Mutual agreement or route dispute' },
                  { id: 'dismissed', label: 'Dismiss Claim', desc: 'Unsubstantiated allegation' },
                ].map((opt) => (
                  <button
                    key={opt.id}
                    type="button"
                    onClick={() => setResolutionOutcome(opt.id)}
                    className={`p-2.5 rounded-xl border text-left transition-all cursor-pointer ${
                      resolutionOutcome === opt.id
                        ? 'bg-emerald-50 border-emerald-500 text-emerald-950 font-bold'
                        : 'bg-surface border-surface-subtle text-textMuted'
                    }`}
                  >
                    <div className="text-xs font-bold">{opt.label}</div>
                    <div className="text-[10px] text-textMuted mt-0.5">{opt.desc}</div>
                  </button>
                ))}
              </div>
            </div>

            <div className="space-y-1 text-xs">
              <label className="block font-bold text-textMain">
                Administrative Notes (Mandatory for Audit Trail)
              </label>
              <textarea
                rows={3}
                placeholder="Specify evidence reviewed, UPI reference, or passenger communication..."
                value={resolutionNotes}
                onChange={(e) => setResolutionNotes(e.target.value)}
                className="w-full p-2.5 text-xs bg-surface rounded-xl border border-surface-subtle text-textMain focus:outline-none focus:ring-1 focus:ring-forest"
              />
            </div>

            <div className="flex items-center justify-end space-x-3 pt-2 border-t border-surface-subtle">
              <button
                type="button"
                onClick={() => setSelectedCase(null)}
                className="px-4 py-2 bg-surface hover:bg-surface-subtle text-textMain text-xs font-bold rounded-xl"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={submitting || resolutionNotes.trim().length < 5}
                onClick={handleResolveCase}
                className="px-5 py-2 bg-forest hover:bg-forest-dark text-white text-xs font-bold rounded-xl shadow-xs transition-colors cursor-pointer disabled:opacity-50"
              >
                {submitting ? 'Recording...' : 'Authorize Settlement'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
