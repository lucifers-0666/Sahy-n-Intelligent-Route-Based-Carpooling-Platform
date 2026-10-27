import React, { useState, useEffect } from 'react';
import { FraudUser, UserAppeal } from '../../types/admin';
import { adminApi } from '../../services/api';
import { PageHeader } from '../ui/PageHeader';
import { Badge } from '../ui/Badge';
import { EmptyState } from '../ui/EmptyState';
import { ErrorState } from '../ui/ErrorState';
import { Pagination } from '../ui/Pagination';
import {
  ShieldAlert,
  AlertTriangle,
  Scale,
  CheckCircle,
  XCircle,
  Search,
  Filter,
  Info,
  Clock,
  UserCheck,
  UserX,
  X,
  Star,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { hasCapability } from '../../utils/rbac';

export const FraudCenterTab: React.FC = () => {
  const { user } = useAuth();
  const canReviewAppeals = hasCapability(user?.role, 'MANAGE_DRIVER_SUSPENSION');

  const [activeSubTab, setActiveSubTab] = useState<'signals' | 'appeals'>('signals');
  const [fraudUsers, setFraudUsers] = useState<FraudUser[]>([]);
  const [appeals, setAppeals] = useState<UserAppeal[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [riskTierFilter, setRiskTierFilter] = useState<string>('all');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const pageSize = 15;

  // Selected appeal for resolution
  const [selectedAppeal, setSelectedAppeal] = useState<UserAppeal | null>(null);
  const [appealAction, setAppealAction] = useState<'approve' | 'reject'>('approve');
  const [reviewerNotes, setReviewerNotes] = useState('');
  const [appealSubmitting, setAppealSubmitting] = useState(false);
  const [appealFeedback, setAppealFeedback] = useState<string | null>(null);

  const fetchFraudData = async () => {
    setLoading(true);
    setError(null);
    try {
      if (activeSubTab === 'signals') {
        const data = await adminApi.getFraudSignals({
          riskTier: riskTierFilter === 'all' ? undefined : riskTierFilter,
        });
        const users = Array.isArray(data)
          ? data
          : (data as any)?.users || (data as any)?.data || [];
        setFraudUsers(users);
      } else {
        const data = await adminApi.getAppeals();
        const list = Array.isArray(data)
          ? data
          : (data as any)?.appeals || (data as any)?.data || [];
        setAppeals(list);
      }
      setPage(1);
    } catch (err: any) {
      setError(err.message || 'Failed to fetch risk management data.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFraudData();
  }, [activeSubTab, riskTierFilter]);

  const handleReviewAppeal = async () => {
    if (!selectedAppeal) return;
    setAppealSubmitting(true);
    try {
      await adminApi.reviewAppeal(
        selectedAppeal.userId,
        selectedAppeal.appealIndex,
        appealAction,
        reviewerNotes.trim()
      );
      setAppealFeedback(`Appeal ${appealAction}d successfully.`);
      setSelectedAppeal(null);
      setReviewerNotes('');
      fetchFraudData();
      setTimeout(() => setAppealFeedback(null), 3500);
    } catch (err: any) {
      alert(`Appeal review failed: ${err.message}`);
    } finally {
      setAppealSubmitting(false);
    }
  };

  const filteredUsers = fraudUsers.filter((u) => {
    if (!search.trim()) return true;
    const term = search.toLowerCase();
    return (
      u.name?.toLowerCase().includes(term) ||
      u.email?.toLowerCase().includes(term) ||
      u.phone?.toLowerCase().includes(term)
    );
  });

  const totalItems = activeSubTab === 'signals' ? filteredUsers.length : appeals.length;
  const paginatedUsers = filteredUsers.slice((page - 1) * pageSize, page * pageSize);
  const paginatedAppeals = appeals.slice((page - 1) * pageSize, page * pageSize);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Fraud & Risk Management Console"
        subtitle="Monitor behavioral risk scores, non-payment patterns, cash restrictions, and user reinstatement appeals."
        breadcrumbs={[
          { label: 'Operations' },
          { label: 'Fraud & Risk' },
        ]}
      />

      {appealFeedback && (
        <div className="p-3.5 bg-emerald-50 border border-emerald-200 text-emerald-950 rounded-xl text-xs font-semibold flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <CheckCircle className="w-4 h-4 text-emerald-700" />
            <span>{appealFeedback}</span>
          </div>
          <button onClick={() => setAppealFeedback(null)} className="p-1 hover:bg-black/5 rounded">
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Non-Prejudicial Risk Explainability Card */}
      <div className="p-4 bg-blue-50/80 rounded-2xl border border-blue-200 text-xs text-blue-950 flex items-start space-x-3">
        <Info className="w-4 h-4 text-blue-700 shrink-0 mt-0.5" />
        <div className="leading-relaxed">
          <span className="font-bold text-blue-900">Explainable Algorithmic Risk Markers: </span>
          Risk scores represent composite behavioral metrics calculated from cancellation velocity, dispute complaints, and unpaid fuel split reports. A risk flag is an investigative indicator, not proof of misconduct. Automatic suspension without human audit is prohibited.
        </div>
      </div>

      {/* Navigation Sub-Tabs & Filters */}
      <div className="card p-4 flex flex-col md:flex-row items-stretch md:items-center justify-between gap-4">
        <div className="flex items-center bg-surface p-1 rounded-xl border border-surface-subtle">
          <button
            onClick={() => setActiveSubTab('signals')}
            className={`px-4 py-1.5 text-xs font-bold rounded-lg transition-all cursor-pointer flex items-center space-x-1.5 ${
              activeSubTab === 'signals'
                ? 'bg-forest text-white shadow-xs'
                : 'text-textMuted hover:text-textMain'
            }`}
          >
            <ShieldAlert className="w-3.5 h-3.5" />
            <span>Risk Signals</span>
          </button>

          <button
            onClick={() => setActiveSubTab('appeals')}
            className={`px-4 py-1.5 text-xs font-bold rounded-lg transition-all cursor-pointer flex items-center space-x-1.5 ${
              activeSubTab === 'appeals'
                ? 'bg-forest text-white shadow-xs'
                : 'text-textMuted hover:text-textMain'
            }`}
          >
            <Scale className="w-3.5 h-3.5" />
            <span>Reinstatement Appeals</span>
            {appeals.filter((a) => a.status === 'pending').length > 0 && (
              <span className="px-1.5 py-0.2 bg-amber-500 text-white rounded-full text-[10px]">
                {appeals.filter((a) => a.status === 'pending').length}
              </span>
            )}
          </button>
        </div>

        {activeSubTab === 'signals' && (
          <div className="flex flex-wrap items-center gap-2">
            <div className="relative">
              <Search className="w-3.5 h-3.5 text-textMuted absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Search user..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pl-8 pr-3 py-1.5 text-xs bg-surface rounded-xl border border-surface-subtle focus:outline-none focus:ring-1 focus:ring-forest text-textMain"
              />
            </div>

            <div className="flex items-center space-x-1 text-xs">
              {['all', 'high', 'critical'].map((tier) => (
                <button
                  key={tier}
                  onClick={() => setRiskTierFilter(tier)}
                  className={`px-2.5 py-1 rounded-lg font-medium transition-colors cursor-pointer capitalize ${
                    riskTierFilter === tier
                      ? 'bg-forest/10 text-forest font-bold'
                      : 'text-textMuted hover:bg-surface'
                  }`}
                >
                  {tier}
                </button>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Main View Area */}
      {loading ? (
        <div className="card p-12 text-center">
          <div className="w-8 h-8 border-2 border-forest border-t-transparent rounded-full animate-spin mx-auto mb-3" />
          <p className="text-xs font-semibold text-textMuted">Evaluating risk signals & appeals...</p>
        </div>
      ) : error ? (
        <ErrorState
          title="Failed to Load Risk Data"
          message={error}
          onRetry={fetchFraudData}
        />
      ) : activeSubTab === 'signals' ? (
        filteredUsers.length === 0 ? (
          <EmptyState
            icon={CheckCircle}
            title="Clean Risk Queue"
            description="No users currently possess elevated risk scores or active cash booking restrictions."
          />
        ) : (
          <div className="card p-0 overflow-hidden shadow-xs">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-surface/60 text-textMuted font-bold uppercase tracking-wider text-[11px] border-b border-surface-subtle">
                  <tr>
                    <th className="py-3.5 px-4">User</th>
                    <th className="py-3.5 px-4">Risk Tier</th>
                    <th className="py-3.5 px-4">Score</th>
                    <th className="py-3.5 px-4">Non-Payment Flags</th>
                    <th className="py-3.5 px-4">Cash Booking</th>
                    <th className="py-3.5 px-4">Account Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-surface-subtle">
                  {paginatedUsers.map((u) => {
                    const score = u.fraudMetrics?.riskScore || 0;
                    const tier = u.fraudMetrics?.riskTier || (score >= 50 ? 'high' : 'low');
                    const canCash = u.capabilities?.canBookCash !== false;

                    return (
                      <tr key={u._id} className="hover:bg-surface/50 transition-colors">
                        <td className="py-3.5 px-4">
                          <div className="font-bold text-textMain">{u.name}</div>
                          <div className="text-[11px] text-textMuted font-mono">{u.email}</div>
                        </td>
                        <td className="py-3.5 px-4">
                          <Badge variant={tier === 'critical' ? 'rose' : tier === 'high' ? 'amber' : 'blue'}>
                            {tier.toUpperCase()}
                          </Badge>
                        </td>
                        <td className="py-3.5 px-4 font-mono font-bold text-textMain">
                          {score} / 100
                        </td>
                        <td className="py-3.5 px-4 font-semibold text-textMain">
                          {u.fraudMetrics?.unpaidReportsCount || 0} Reports
                        </td>
                        <td className="py-3.5 px-4">
                          <Badge variant={canCash ? 'emerald' : 'rose'}>
                            {canCash ? 'Allowed' : 'Restricted'}
                          </Badge>
                        </td>
                        <td className="py-3.5 px-4">
                          <Badge variant={u.accountStatus === 'suspended' ? 'rose' : 'emerald'}>
                            {u.accountStatus.toUpperCase()}
                          </Badge>
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
        )
      ) : appeals.length === 0 ? (
        <EmptyState
          icon={Scale}
          title="No Reinstatement Appeals"
          description="There are currently no user appeals for restricted permissions or suspended accounts."
        />
      ) : (
        <div className="card p-0 overflow-hidden shadow-xs">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-surface/60 text-textMuted font-bold uppercase tracking-wider text-[11px] border-b border-surface-subtle">
                <tr>
                  <th className="py-3.5 px-4">Applicant</th>
                  <th className="py-3.5 px-4">Submitted Reason</th>
                  <th className="py-3.5 px-4">Appeal Status</th>
                  <th className="py-3.5 px-4">Submitted At</th>
                  <th className="py-3.5 px-4 text-right">Review Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-subtle">
                {paginatedAppeals.map((a, idx) => (
                  <tr key={`${a.userId}_${idx}`} className="hover:bg-surface/50 transition-colors">
                    <td className="py-3.5 px-4">
                      <div className="font-bold text-textMain">{a.userName}</div>
                      <div className="text-[11px] text-textMuted font-mono">{a.userPhone}</div>
                    </td>
                    <td className="py-3.5 px-4 max-w-xs truncate text-textMain">
                      {a.reason}
                    </td>
                    <td className="py-3.5 px-4">
                      <Badge variant={a.status === 'approved' ? 'emerald' : a.status === 'rejected' ? 'rose' : 'amber'}>
                        {a.status.toUpperCase()}
                      </Badge>
                    </td>
                    <td className="py-3.5 px-4 text-textMuted font-mono">
                      {a.submittedAt ? new Date(a.submittedAt).toLocaleDateString() : 'N/A'}
                    </td>
                    <td className="py-3.5 px-4 text-right">
                      {a.status === 'pending' && canReviewAppeals ? (
                        <button
                          onClick={() => {
                            setSelectedAppeal(a);
                            setAppealAction('approve');
                            setReviewerNotes('');
                          }}
                          className="px-3 py-1.5 bg-forest text-white rounded-lg text-xs font-bold hover:bg-forest-dark transition-colors cursor-pointer"
                        >
                          Review Appeal
                        </button>
                      ) : (
                        <span className="text-[11px] text-textMuted">
                          {a.reviewedAt ? `Reviewed ${new Date(a.reviewedAt).toLocaleDateString()}` : 'Completed'}
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
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

      {/* Appeal Review Modal */}
      {selectedAppeal && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-in fade-in">
          <div className="w-full max-w-md bg-white rounded-2xl shadow-xl p-6 space-y-4 border border-surface-subtle">
            <div className="flex items-center justify-between border-b border-surface-subtle pb-3">
              <div className="flex items-center space-x-2">
                <Scale className="w-5 h-5 text-forest" />
                <h3 className="text-base font-bold text-textMain">Review Reinstatement Appeal</h3>
              </div>
              <button onClick={() => setSelectedAppeal(null)} className="p-1 rounded-lg hover:bg-surface text-textMuted">
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-3 bg-surface rounded-xl border border-surface-subtle space-y-1 text-xs">
              <div className="font-semibold text-textMain">Applicant: {selectedAppeal.userName}</div>
              <div className="text-textMuted">Submitted Appeal Justification:</div>
              <p className="text-xs text-textMain font-medium p-2 bg-white rounded-lg border border-surface-subtle mt-1">
                "{selectedAppeal.reason}"
              </p>
            </div>

            <div className="space-y-1 text-xs">
              <label className="block font-bold text-textMain">Resolution Decision</label>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setAppealAction('approve')}
                  className={`p-2.5 rounded-xl border text-xs font-bold transition-all flex items-center justify-center space-x-1.5 cursor-pointer ${
                    appealAction === 'approve'
                      ? 'bg-emerald-50 border-emerald-500 text-emerald-950 font-extrabold'
                      : 'bg-surface border-surface-subtle text-textMuted'
                  }`}
                >
                  <CheckCircle className="w-4 h-4 text-emerald-600" />
                  <span>Reinstate Account</span>
                </button>
                <button
                  type="button"
                  onClick={() => setAppealAction('reject')}
                  className={`p-2.5 rounded-xl border text-xs font-bold transition-all flex items-center justify-center space-x-1.5 cursor-pointer ${
                    appealAction === 'reject'
                      ? 'bg-rose-50 border-rose-500 text-rose-950 font-extrabold'
                      : 'bg-surface border-surface-subtle text-textMuted'
                  }`}
                >
                  <XCircle className="w-4 h-4 text-rose-600" />
                  <span>Reject Appeal</span>
                </button>
              </div>
            </div>

            <div className="space-y-1 text-xs">
              <label className="block font-bold text-textMain">Reviewer Notes (Recorded in Audit Ledger)</label>
              <textarea
                rows={3}
                placeholder="Provide justification for approval or grounds for rejection..."
                value={reviewerNotes}
                onChange={(e) => setReviewerNotes(e.target.value)}
                className="w-full p-2.5 text-xs bg-surface rounded-xl border border-surface-subtle text-textMain focus:outline-none focus:ring-1 focus:ring-forest"
              />
            </div>

            <div className="flex items-center justify-end space-x-3 pt-2 border-t border-surface-subtle">
              <button
                type="button"
                onClick={() => setSelectedAppeal(null)}
                className="px-4 py-2 bg-surface hover:bg-surface-subtle text-textMain text-xs font-bold rounded-xl"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={appealSubmitting}
                onClick={handleReviewAppeal}
                className={`px-5 py-2 text-white text-xs font-bold rounded-xl shadow-xs transition-colors cursor-pointer ${
                  appealAction === 'approve' ? 'bg-forest hover:bg-forest-dark' : 'bg-rose-600 hover:bg-rose-700'
                }`}
              >
                {appealSubmitting ? 'Recording...' : `Confirm ${appealAction === 'approve' ? 'Approval' : 'Rejection'}`}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
