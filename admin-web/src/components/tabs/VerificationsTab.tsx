import React, { useState, useEffect } from 'react';
import { UserItem } from '../../types/admin';
import { adminApi } from '../../services/api';
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

      // Show applicants who applied for driver role or have vehicles
      const applicants =
        filter === 'all'
          ? data.filter(
              (u) =>
                (u.driverProfile && u.driverProfile.onboardingStatus !== 'not_started') ||
                u.capabilities?.canDrive ||
                u.vehicle
            )
          : data;
      setUsers(applicants);
    } catch (err: any) {
      setError(err.message || 'Failed to load driver verifications');
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
    setActionLoading(true);
    try {
      await adminApi.verifyDriver(userId, 'approve');
      setSelectedUser(null);
      fetchUsers();
    } catch (err: any) {
      alert(`Approval failed: ${err.message}`);
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = async (userId: string) => {
    if (!rejectReason.trim()) {
      alert('Please provide a specific rejection reason for the applicant.');
      return;
    }
    setActionLoading(true);
    try {
      await adminApi.verifyDriver(userId, 'reject', rejectReason.trim());
      setSelectedUser(null);
      setRejectReason('');
      fetchUsers();
    } catch (err: any) {
      alert(`Rejection failed: ${err.message}`);
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
                  return (
                    <tr key={u._id} className="hover:bg-surface/50 transition-colors">
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

      {/* Review Documents Modal */}
      {selectedUser && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-xl border border-surface-subtle space-y-5 animate-in fade-in duration-150">
            <div className="flex items-start justify-between">
              <div>
                <span className="text-xs font-bold text-forest uppercase tracking-wider">
                  Driver Document Verification
                </span>
                <h3 className="text-lg font-extrabold text-textMain mt-0.5">
                  {selectedUser.name}
                </h3>
                <p className="text-xs text-textMuted">
                  {selectedUser.email} · {selectedUser.phone}
                </p>
              </div>
              <button
                onClick={() => setSelectedUser(null)}
                className="p-1 rounded-lg text-textMuted hover:bg-surface cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Document Details Card */}
            <div className="space-y-3 bg-surface p-4 rounded-2xl border border-surface-subtle text-xs">
              <div className="flex justify-between items-center pb-2 border-b border-surface-subtle">
                <span className="text-textMuted font-medium">Driving License Number:</span>
                <span className="font-mono font-bold text-textMain">
                  {selectedUser.driverProfile?.licenseNumber || 'N/A'}
                </span>
              </div>

              <div className="flex justify-between items-center pb-2 border-b border-surface-subtle">
                <span className="text-textMuted font-medium">License Document:</span>
                {selectedUser.driverProfile?.licenseDocUrl ? (
                  <a
                    href={selectedUser.driverProfile.licenseDocUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="flex items-center space-x-1 text-forest font-bold hover:underline"
                  >
                    <FileText className="w-3.5 h-3.5" />
                    <span>View DL File</span>
                    <ExternalLink className="w-3 h-3" />
                  </a>
                ) : (
                  <span className="text-textMuted">Not Uploaded</span>
                )}
              </div>

              <div className="flex justify-between items-center">
                <span className="text-textMuted font-medium">Vehicle RC Document:</span>
                {selectedUser.driverProfile?.rcDocUrl ? (
                  <a
                    href={selectedUser.driverProfile.rcDocUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="flex items-center space-x-1 text-forest font-bold hover:underline"
                  >
                    <FileText className="w-3.5 h-3.5" />
                    <span>View RC File</span>
                    <ExternalLink className="w-3 h-3" />
                  </a>
                ) : (
                  <span className="text-textMuted">Not Uploaded</span>
                )}
              </div>
            </div>

            {/* Rejection Note field if rejecting */}
            <div>
              <label className="block text-xs font-bold text-textMain mb-1">
                Rejection Reason (if rejecting application):
              </label>
              <textarea
                placeholder="E.g., License photo expired, image blurred, or number does not match Parivahan registry..."
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                rows={2}
                className="w-full bg-white p-3 text-xs rounded-xl border border-surface-subtle focus:outline-none focus:border-forest text-textMain"
              />
            </div>

            {/* Action buttons */}
            <div className="flex gap-3 pt-2">
              <button
                onClick={() => handleReject(selectedUser._id)}
                disabled={actionLoading}
                className="flex-1 py-2.5 px-4 rounded-xl border border-rose-300 text-rose-700 bg-rose-50 hover:bg-rose-100 font-bold text-xs transition-colors cursor-pointer flex items-center justify-center space-x-1.5"
              >
                <ShieldAlert className="w-4 h-4" />
                <span>{actionLoading ? 'Processing...' : 'Reject Driver'}</span>
              </button>

              <button
                onClick={() => handleApprove(selectedUser._id)}
                disabled={actionLoading}
                className="flex-1 py-2.5 px-4 rounded-xl bg-forest hover:bg-forest-dark text-white font-bold text-xs transition-colors shadow-sm cursor-pointer flex items-center justify-center space-x-1.5"
              >
                <ShieldCheck className="w-4 h-4" />
                <span>{actionLoading ? 'Processing...' : 'Approve & Verify'}</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
