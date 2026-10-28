import React, { useState, useEffect } from 'react';
import { UserItem } from '../../types/admin';
import { adminApi } from '../../services/api';
import { DriverKycDrawer } from '../DriverKycDrawer';
import {
  ShieldCheck,
  ShieldAlert,
  FileText,
  Check,
  X,
  Search,
  ExternalLink,
  Clock,
} from 'lucide-react';

export const VerificationsTab: React.FC = () => {
  const [users, setUsers] = useState<UserItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<'submitted' | 'approved' | 'rejected' | 'all'>('submitted');
  const [search, setSearch] = useState('');

  // Selected driver for modal view & review
  const [selectedUser, setSelectedUser] = useState<UserItem | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  // Bulk actions state
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [bulkProcessing, setBulkProcessing] = useState(false);
  const [bulkFeedback, setBulkFeedback] = useState<string | null>(null);

  const toggleSelect = (id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const toggleSelectAll = () => {
    if (selectedIds.size === users.length) {
      setSelectedIds(new Set());
    } else {
      setSelectedIds(new Set(users.map((u) => u._id)));
    }
  };

  const handleBulkApprove = async () => {
    if (selectedIds.size === 0) return;
    setBulkProcessing(true);
    setBulkFeedback(null);
    try {
      const ids = Array.from(selectedIds);
      let successCount = 0;
      for (const id of ids) {
        try {
          await adminApi.verifyDriver(id, 'approve');
          successCount++;
        } catch (e) {
          console.error(`Failed to approve ${id}`, e);
        }
      }
      setBulkFeedback(`Successfully approved ${successCount} driver verification(s).`);
      setSelectedIds(new Set());
      await fetchUsers();
    } finally {
      setBulkProcessing(false);
    }
  };

  const handleBulkReject = async () => {
    if (selectedIds.size === 0) return;
    const reason = window.prompt('Enter reason for bulk rejection:') || 'Compliance documentation requirement not met';
    setBulkProcessing(true);
    setBulkFeedback(null);
    try {
      const ids = Array.from(selectedIds);
      let count = 0;
      for (const id of ids) {
        try {
          await adminApi.verifyDriver(id, 'reject', reason);
          count++;
        } catch (e) {
          console.error(`Failed to reject ${id}`, e);
        }
      }
      setBulkFeedback(`Rejected ${count} driver application(s).`);
      setSelectedIds(new Set());
      await fetchUsers();
    } finally {
      setBulkProcessing(false);
    }
  };

  const fetchUsers = async () => {
    setLoading(true);
    setError(null);
    try {
      const backendStatus =
        filter === 'submitted'
          ? 'pending'
          : filter === 'approved'
          ? 'verified'
          : filter === 'rejected'
          ? 'rejected'
          : 'all';

      const data = await adminApi.getUsers({
        status: backendStatus,
        search: search.trim() || undefined,
      });

      const safeData = Array.isArray(data) ? data : [];
      const applicants =
        filter === 'all'
          ? safeData.filter(
              (u) =>
                (u?.driverProfile && u.driverProfile.onboardingStatus !== 'not_started') ||
                u?.capabilities?.canDrive ||
                u?.vehicle
            )
          : safeData;
      setUsers(applicants);
    } catch (err: any) {
      setError(err.message || 'Failed to load driver verifications');
      setUsers([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [filter]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchUsers();
  };

  const handleApprove = async (userId: string) => {
    await adminApi.verifyDriver(userId, 'approve');
    setSelectedUser(null);
    fetchUsers();
  };

  const handleReject = async (userId: string, reason: string) => {
    await adminApi.verifyDriver(userId, 'reject', reason);
    setSelectedUser(null);
    fetchUsers();
  };

  return (
    <div className="space-y-6">
      {/* Header and filters */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-extrabold text-textMain tracking-tight">
            Driver Verification & Document Review
          </h1>
          <p className="text-xs text-textMuted font-medium mt-0.5">
            Audit government driving licenses, vehicle registration certificates (RC), and compliance records.
          </p>
        </div>

        {/* Filter Chips */}
        <div className="flex items-center space-x-1.5 bg-white p-1 rounded-xl border border-surface-subtle shadow-xs">
          {[
            { id: 'submitted', label: 'Pending Review' },
            { id: 'approved', label: 'Approved' },
            { id: 'rejected', label: 'Rejected' },
            { id: 'all', label: 'All Records' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setFilter(tab.id as any)}
              className={`px-3 py-1.5 text-xs font-bold rounded-lg transition-colors cursor-pointer ${
                filter === tab.id
                  ? 'bg-forest text-white'
                  : 'text-textMuted hover:text-textMain hover:bg-surface'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      {/* Search Input */}
      <form onSubmit={handleSearchSubmit} className="flex gap-2">
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-textMuted absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search by driver name, email, or license number..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full bg-white pl-10 pr-4 py-2 text-xs rounded-xl border border-surface-subtle focus:outline-none focus:border-forest text-textMain"
          />
        </div>
        <button
          type="submit"
          className="px-4 py-2 bg-forest text-white text-xs font-bold rounded-xl hover:bg-forest-dark transition-colors cursor-pointer"
        >
          Search
        </button>
      </form>

      {/* Bulk Feedback Banner */}
      {bulkFeedback && (
        <div className="p-3 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-xl text-xs flex items-center justify-between">
          <span>{bulkFeedback}</span>
          <button onClick={() => setBulkFeedback(null)} className="text-emerald-700 hover:text-emerald-900 font-bold ml-2">Dismiss</button>
        </div>
      )}

      {/* Bulk Action Toolbar */}
      {selectedIds.size > 0 && (
        <div className="bg-forest-dark text-white p-3 rounded-2xl flex items-center justify-between gap-4 shadow-md animate-fade-in">
          <div className="flex items-center space-x-2 text-xs">
            <span className="w-2 h-2 rounded-full bg-forest-mint animate-pulse" />
            <span className="font-bold">{selectedIds.size} Driver Application{selectedIds.size > 1 ? 's' : ''} Selected</span>
          </div>

          <div className="flex items-center space-x-2">
            <button
              onClick={handleBulkApprove}
              disabled={bulkProcessing}
              className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white text-xs font-bold rounded-lg transition-colors cursor-pointer flex items-center space-x-1"
            >
              <Check className="w-3.5 h-3.5" />
              <span>{bulkProcessing ? 'Processing...' : 'Approve Selected'}</span>
            </button>
            <button
              onClick={handleBulkReject}
              disabled={bulkProcessing}
              className="px-3 py-1.5 bg-rose-600 hover:bg-rose-700 disabled:opacity-50 text-white text-xs font-bold rounded-lg transition-colors cursor-pointer flex items-center space-x-1"
            >
              <X className="w-3.5 h-3.5" />
              <span>Reject Selected</span>
            </button>
            <button
              onClick={() => setSelectedIds(new Set())}
              disabled={bulkProcessing}
              className="px-2.5 py-1.5 text-forest-mint hover:text-white text-xs font-semibold cursor-pointer"
            >
              Clear
            </button>
          </div>
        </div>
      )}

      {/* Queue Content */}
      {loading ? (
        <div className="bg-white rounded-2xl p-12 text-center text-textMuted text-xs">
          Loading verification queue from database...
        </div>
      ) : error ? (
        <div className="bg-rose-50 border border-rose-200 rounded-2xl p-6 text-center text-rose-800 text-xs">
          {error}
        </div>
      ) : users.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center border border-surface-subtle shadow-xs">
          <ShieldCheck className="w-10 h-10 text-emerald-600 mx-auto mb-2" />
          <h3 className="text-sm font-bold text-textMain">No Verification Records Found</h3>
          <p className="text-xs text-textMuted mt-1">
            {filter === 'submitted'
              ? 'The pending driver review queue is currently empty.'
              : 'No applicants matched your current search and filter settings.'}
          </p>
        </div>
      ) : (
        <div className="bg-white rounded-2xl border border-surface-subtle shadow-xs overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-surface text-textMuted font-bold uppercase tracking-wider border-b border-surface-subtle">
                <tr>
                  <th className="py-3 px-4 w-10">
                    <input
                      type="checkbox"
                      checked={users.length > 0 && selectedIds.size === users.length}
                      onChange={toggleSelectAll}
                      className="rounded border-surface-subtle text-forest focus:ring-forest cursor-pointer"
                    />
                  </th>
                  <th className="py-3 px-4">Driver</th>
                  <th className="py-3 px-4">License Number</th>
                  <th className="py-3 px-4">Submission Status</th>
                  <th className="py-3 px-4">Applied Date</th>
                  <th className="py-3 px-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-subtle">
                {users.map((u) => {
                  const status = u.driverProfile?.onboardingStatus || 'not_started';
                  const isChecked = selectedIds.has(u._id);
                  return (
                    <tr key={u._id} className={`hover:bg-surface/50 transition-colors ${isChecked ? 'bg-forest-light/30' : ''}`}>
                      <td className="py-3.5 px-4 w-10">
                        <input
                          type="checkbox"
                          checked={isChecked}
                          onChange={() => toggleSelect(u._id)}
                          className="rounded border-surface-subtle text-forest focus:ring-forest cursor-pointer"
                        />
                      </td>
                      <td className="py-3.5 px-4">
                        <div className="font-bold text-textMain">{u.name}</div>
                        <div className="text-[11px] text-textMuted">{u.email} · {u.phone}</div>
                      </td>
                      <td className="py-3.5 px-4 font-mono font-medium">
                        {u.driverProfile?.licenseNumber || 'Not Provided'}
                      </td>
                      <td className="py-3.5 px-4">
                        {status === 'submitted' && (
                          <span className="inline-flex items-center space-x-1 px-2.5 py-0.5 rounded-full bg-amber-50 text-amber-800 border border-amber-200 font-semibold text-[11px]">
                            <Clock className="w-3 h-3" />
                            <span>Pending Review</span>
                          </span>
                        )}
                        {status === 'approved' && (
                          <span className="inline-flex items-center space-x-1 px-2.5 py-0.5 rounded-full bg-emerald-50 text-emerald-800 border border-emerald-200 font-semibold text-[11px]">
                            <Check className="w-3 h-3" />
                            <span>Verified Driver</span>
                          </span>
                        )}
                        {status === 'rejected' && (
                          <span className="inline-flex items-center space-x-1 px-2.5 py-0.5 rounded-full bg-rose-50 text-rose-800 border border-rose-200 font-semibold text-[11px]">
                            <X className="w-3 h-3" />
                            <span>Rejected</span>
                          </span>
                        )}
                      </td>
                      <td className="py-3.5 px-4 text-textMuted">
                        {u.createdAt ? new Date(u.createdAt).toLocaleDateString() : 'N/A'}
                      </td>
                      <td className="py-3.5 px-4 text-right">
                        <button
                          onClick={() => {
                            setSelectedUser(u);
                            setRejectReason('');
                          }}
                          className="px-3 py-1.5 bg-forest-light text-forest hover:bg-forest hover:text-white rounded-lg font-bold text-xs transition-colors cursor-pointer"
                        >
                          Review Docs
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Driver KYC Inspection Drawer */}
      <DriverKycDrawer
        user={selectedUser}
        isOpen={Boolean(selectedUser)}
        onClose={() => setSelectedUser(null)}
        onApprove={handleApprove}
        onReject={handleReject}
      />
    </div>
  );
};
