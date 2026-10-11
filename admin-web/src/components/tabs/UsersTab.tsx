import React, { useState, useEffect } from 'react';
import { UserItem } from '../../types/admin';
import { adminApi } from '../../services/api';
import { UnmaskModal } from '../UnmaskModal';
import {
  Users,
  Search,
  Star,
  ShieldCheck,
  AlertOctagon,
  CheckCircle,
  X,
  AlertTriangle,
  RotateCcw,
  Info,
  Eye,
} from 'lucide-react';

export const UsersTab: React.FC = () => {
  const [users, setUsers] = useState<UserItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [roleFilter, setRoleFilter] = useState<'all' | 'driver' | 'passenger'>('all');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'suspended'>('all');
  const [search, setSearch] = useState('');

  // PII Unmasking state
  const [unmaskOpen, setUnmaskOpen] = useState(false);
  const [unmaskTarget, setUnmaskTarget] = useState<{ id: string; field: string; label: string } | null>(null);
  const [unmaskedValues, setUnmaskedValues] = useState<Record<string, string>>({});

  // Suspension modal state
  const [suspendingUser, setSuspendingUser] = useState<UserItem | null>(null);
  const [suspensionReason, setSuspensionReason] = useState('');
  const [suspensionSubmitting, setSuspensionSubmitting] = useState(false);
  const [suspensionError, setSuspensionError] = useState<string | null>(null);

  // Reactivation modal state
  const [reactivatingUser, setReactivatingUser] = useState<UserItem | null>(null);
  const [reactivationReason, setReactivationReason] = useState('');
  const [reactivationSubmitting, setReactivationSubmitting] = useState(false);
  const [reactivationError, setReactivationError] = useState<string | null>(null);

  // Selected driver for detail inspection
  const [inspectedUser, setInspectedUser] = useState<UserItem | null>(null);

  const fetchUsers = async () => {
    setLoading(true);
    setError(null);
    try {
      const backendStatus = roleFilter === 'driver' ? 'drivers' : 'all';
      const data = await adminApi.getUsers({
        status: backendStatus,
        search: search.trim() || undefined,
      });

      const safeList: UserItem[] = Array.isArray(data)
        ? data
        : Array.isArray((data as any)?.users)
        ? (data as any).users
        : [];

      let filtered = safeList;
      if (roleFilter === 'driver') {
        filtered = safeList.filter(
          (u) =>
            u?.capabilities?.canDrive ||
            u?.driverProfile?.onboardingStatus === 'approved' ||
            !!u?.vehicle
        );
      } else if (roleFilter === 'passenger') {
        filtered = safeList.filter(
          (u) =>
            !u?.capabilities?.canDrive &&
            u?.driverProfile?.onboardingStatus !== 'approved'
        );
      }

      if (statusFilter === 'active') {
        filtered = filtered.filter((u) => u?.accountStatus !== 'suspended');
      } else if (statusFilter === 'suspended') {
        filtered = filtered.filter((u) => u?.accountStatus === 'suspended');
      }

      setUsers(filtered);
    } catch (err: any) {
      setError(err.message || 'Failed to load user accounts.');
      setUsers([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [roleFilter, statusFilter]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchUsers();
  };

  const handleOpenSuspendModal = (user: UserItem, e: React.MouseEvent) => {
    e.stopPropagation();
    setSuspendingUser(user);
    setSuspensionReason('');
    setSuspensionError(null);
  };

  const handleOpenReactivateModal = (user: UserItem, e: React.MouseEvent) => {
    e.stopPropagation();
    setReactivatingUser(user);
    setReactivationReason('');
    setReactivationError(null);
  };

  const handleConfirmSuspend = async () => {
    if (!suspendingUser) return;
    const trimmedReason = suspensionReason.trim();
    if (trimmedReason.length < 5) {
      setSuspensionError('Reason must be at least 5 characters long.');
      return;
    }
    if (trimmedReason.length > 500) {
      setSuspensionError('Reason cannot exceed 500 characters.');
      return;
    }

    setSuspensionSubmitting(true);
    setSuspensionError(null);
    try {
      const updatedUser = await adminApi.suspendDriver(suspendingUser._id, trimmedReason);
      setUsers((prev) =>
        prev.map((u) => (u._id === suspendingUser._id ? { ...u, ...updatedUser, accountStatus: 'suspended' } : u))
      );
      if (inspectedUser?._id === suspendingUser._id) {
        setInspectedUser({ ...inspectedUser, ...updatedUser, accountStatus: 'suspended' });
      }
      setFeedback({
        type: 'success',
        message: `Driver account for ${suspendingUser.name} has been suspended. All capabilities are blocked.`,
      });
      setSuspendingUser(null);
    } catch (err: any) {
      setSuspensionError(err.message || 'Failed to suspend account on server.');
    } finally {
      setSuspensionSubmitting(false);
    }
  };

  const handleConfirmReactivate = async () => {
    if (!reactivatingUser) return;
    setReactivationSubmitting(true);
    setReactivationError(null);
    try {
      const updatedUser = await adminApi.reactivateDriver(
        reactivatingUser._id,
        reactivationReason.trim() || undefined
      );
      setUsers((prev) =>
        prev.map((u) => (u._id === reactivatingUser._id ? { ...u, ...updatedUser, accountStatus: 'active' } : u))
      );
      if (inspectedUser?._id === reactivatingUser._id) {
        setInspectedUser({ ...inspectedUser, ...updatedUser, accountStatus: 'active' });
      }
      setFeedback({
        type: 'success',
        message: `Account for ${reactivatingUser.name} has been reactivated successfully.`,
      });
      setReactivatingUser(null);
    } catch (err: any) {
      setReactivationError(err.message || 'Failed to reactivate account on server.');
    } finally {
      setReactivationSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header and filters */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-black text-gray-950 uppercase tracking-tight font-mono">
            User Directory & Access Control
          </h1>
          <p className="text-xs text-gray-600 font-mono mt-0.5">
            Audit registered accounts, driver eligibility, and execute fail-closed suspensions.
          </p>
        </div>

        {/* Status & Role Filters with Brutalist borders */}
        <div className="flex flex-wrap items-center gap-2">
          <div className="flex items-center space-x-1 bg-gray-100 p-1 border-2 border-gray-900 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]">
            {[
              { id: 'all', label: 'All Roles' },
              { id: 'driver', label: 'Drivers' },
              { id: 'passenger', label: 'Passengers' },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setRoleFilter(tab.id as any)}
                className={`px-3 py-1 text-[11px] font-bold uppercase transition-colors cursor-pointer ${
                  roleFilter === tab.id
                    ? 'bg-gray-900 text-white'
                    : 'text-gray-700 hover:bg-gray-200'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>

          <div className="flex items-center space-x-1 bg-gray-100 p-1 border-2 border-gray-900 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]">
            {[
              { id: 'all', label: 'All Status' },
              { id: 'active', label: 'Active' },
              { id: 'suspended', label: 'Suspended' },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setStatusFilter(tab.id as any)}
                className={`px-3 py-1 text-[11px] font-bold uppercase transition-colors cursor-pointer ${
                  statusFilter === tab.id
                    ? 'bg-gray-900 text-white'
                    : 'text-gray-700 hover:bg-gray-200'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Global Feedback Banner */}
      {feedback && (
        <div
          className={`p-3 border-2 text-xs font-mono font-bold flex items-center justify-between shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] ${
            feedback.type === 'success'
              ? 'bg-emerald-50 border-emerald-900 text-emerald-950'
              : 'bg-rose-50 border-rose-900 text-rose-950'
          }`}
        >
          <div className="flex items-center space-x-2">
            {feedback.type === 'success' ? (
              <CheckCircle className="w-4 h-4 text-emerald-800 shrink-0" />
            ) : (
              <AlertTriangle className="w-4 h-4 text-rose-800 shrink-0" />
            )}
            <span>{feedback.message}</span>
          </div>
          <button
            onClick={() => setFeedback(null)}
            className="p-1 hover:bg-black/10 cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Search Input */}
      <form onSubmit={handleSearchSubmit} className="flex gap-2">
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-gray-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search by name, email, or mobile number..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full bg-white pl-10 pr-4 py-2 text-xs border-2 border-gray-900 font-mono text-gray-950 focus:outline-none shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
          />
        </div>
        <button
          type="submit"
          className="px-5 py-2 bg-gray-900 text-white text-xs font-black uppercase font-mono hover:bg-gray-800 transition-colors border-2 border-gray-900 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] cursor-pointer"
        >
          Search
        </button>
      </form>

      {/* Table Content */}
      {loading ? (
        <div className="bg-white border-2 border-gray-900 p-12 text-center text-gray-600 font-mono text-xs shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
          QUERYING ACCOUNTS FROM DATABASE...
        </div>
      ) : error ? (
        <div className="bg-rose-50 border-2 border-rose-900 p-6 text-center text-rose-950 font-mono text-xs shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
          {error}
        </div>
      ) : users.length === 0 ? (
        <div className="bg-white border-2 border-gray-900 p-12 text-center shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
          <Users className="w-10 h-10 text-gray-900 mx-auto mb-2" />
          <h3 className="text-sm font-black uppercase font-mono text-gray-950">No Accounts Found</h3>
          <p className="text-xs text-gray-600 font-mono mt-1">
            No community accounts matched the active filter criteria.
          </p>
        </div>
      ) : (
        <div className="bg-white border-2 border-gray-900 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs font-mono">
              <thead className="bg-gray-100 text-gray-950 font-black uppercase tracking-wider border-b-2 border-gray-900">
                <tr>
                  <th className="py-3 px-4">Member Name</th>
                  <th className="py-3 px-4">Contact Info</th>
                  <th className="py-3 px-4">Role & Eligibility</th>
                  <th className="py-3 px-4">Account Status</th>
                  <th className="py-3 px-4">Community Rating</th>
                  <th className="py-3 px-4">Journeys</th>
                  <th className="py-3 px-4 text-right">Access Controls</th>
                </tr>
              </thead>
              <tbody className="divide-y-2 divide-gray-200">
                {(Array.isArray(users) ? users : []).map((u) => {
                  const isEligibleDriver =
                    u?.capabilities?.canDrive ||
                    u?.driverProfile?.onboardingStatus === 'approved' ||
                    !!u?.vehicle;
                  const isSuspended = u?.accountStatus === 'suspended';
                  const displayRating =
                    typeof u?.rating === 'number'
                      ? u.rating.toFixed(1)
                      : u?.rating && typeof (u.rating as any).average === 'number'
                      ? (u.rating as any).average.toFixed(1)
                      : '4.9';
                  const userIdStr = String(u?._id || '');
                  const shortId = userIdStr ? userIdStr.slice(-6) : 'N/A';

                  return (
                    <tr
                      key={userIdStr || Math.random()}
                      onClick={() => setInspectedUser(u)}
                      className="hover:bg-gray-50 transition-colors cursor-pointer"
                    >
                      <td className="py-3.5 px-4">
                        <div className="font-bold text-gray-950 flex items-center space-x-1.5">
                          <span>{u?.name || 'Unnamed Member'}</span>
                          {u?.isVerified && <ShieldCheck className="w-3.5 h-3.5 text-gray-900" />}
                        </div>
                        <div className="text-[11px] text-gray-500 font-mono">ID: {shortId}</div>
                      </td>

                      <td className="py-3.5 px-4 font-medium" onClick={(e) => e.stopPropagation()}>
                        <div className="flex items-center justify-between space-x-2">
                          <span className="text-gray-950 font-bold truncate max-w-[160px]">
                            {unmaskedValues[`email_${userIdStr}`] || u?.email || 'N/A'}
                          </span>
                          {!unmaskedValues[`email_${userIdStr}`] && userIdStr && (
                            <button
                              type="button"
                              onClick={() => {
                                setUnmaskTarget({ id: userIdStr, field: 'email', label: 'Email Address' });
                                setUnmaskOpen(true);
                              }}
                              className="text-[9px] uppercase font-bold text-forest hover:underline shrink-0"
                            >
                              Unmask
                            </button>
                          )}
                        </div>
                        <div className="flex items-center justify-between space-x-2 text-[11px] text-gray-500 font-mono mt-0.5">
                          <span>{unmaskedValues[`phone_${userIdStr}`] || u?.phone || 'N/A'}</span>
                          {!unmaskedValues[`phone_${userIdStr}`] && userIdStr && (
                            <button
                              type="button"
                              onClick={() => {
                                setUnmaskTarget({ id: userIdStr, field: 'phone', label: 'Phone Number' });
                                setUnmaskOpen(true);
                              }}
                              className="text-[9px] uppercase font-bold text-forest hover:underline shrink-0"
                            >
                              Unmask
                            </button>
                          )}
                        </div>
                      </td>

                      <td className="py-3.5 px-4">
                        <span
                          className={`inline-block px-2 py-0.5 text-[10px] font-black uppercase border-2 ${
                            isEligibleDriver
                              ? 'bg-blue-50 text-blue-950 border-blue-900'
                              : 'bg-gray-100 text-gray-800 border-gray-900'
                          }`}
                        >
                          {isEligibleDriver ? 'Eligible Driver' : 'Passenger Only'}
                        </span>
                        {u?.vehicle && typeof u.vehicle === 'object' && (
                          <div className="text-[10px] text-gray-700 font-bold mt-1">
                            {u.vehicle.make || ''} {u.vehicle.model || ''} {u.vehicle.registrationNumber ? `(${u.vehicle.registrationNumber})` : ''}
                          </div>
                        )}
                      </td>

                      <td className="py-3.5 px-4">
                        {isSuspended ? (
                          <div>
                            <span className="inline-flex items-center space-x-1 px-2.5 py-1 bg-red-600 text-white font-black text-[10px] uppercase border-2 border-red-950 shadow-[1px_1px_0px_0px_rgba(0,0,0,1)]">
                              <AlertOctagon className="w-3 h-3" />
                              <span>SUSPENDED</span>
                            </span>
                            {u.suspensionReason && (
                              <div
                                title={u.suspensionReason}
                                className="text-[10px] text-red-700 font-bold truncate max-w-[160px] mt-1"
                              >
                                {u.suspensionReason}
                              </div>
                            )}
                          </div>
                        ) : (
                          <span className="inline-block px-2.5 py-1 bg-emerald-100 text-emerald-950 font-black text-[10px] uppercase border-2 border-emerald-900">
                            ACTIVE
                          </span>
                        )}
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="flex items-center space-x-1 font-bold text-gray-950">
                          <Star className="w-3.5 h-3.5 text-gray-900 fill-gray-900" />
                          <span>{displayRating}</span>
                        </div>
                      </td>

                      <td className="py-3.5 px-4 font-bold text-gray-950">
                        {u.totalRides || 0}
                      </td>

                      <td className="py-3.5 px-4 text-right">
                        <div className="flex items-center justify-end space-x-2">
                          {isEligibleDriver ? (
                            isSuspended ? (
                              <button
                                type="button"
                                onClick={(e) => handleOpenReactivateModal(u, e)}
                                className="px-3 py-1.5 bg-gray-900 hover:bg-gray-800 text-white text-[11px] font-black uppercase font-mono border-2 border-gray-900 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] active:translate-x-[1px] active:translate-y-[1px] active:shadow-none cursor-pointer flex items-center space-x-1"
                              >
                                <RotateCcw className="w-3 h-3" />
                                <span>Reactivate</span>
                              </button>
                            ) : (
                              <button
                                type="button"
                                onClick={(e) => handleOpenSuspendModal(u, e)}
                                className="px-3 py-1.5 bg-red-600 hover:bg-red-700 text-white text-[11px] font-black uppercase font-mono border-2 border-red-950 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] active:translate-x-[1px] active:translate-y-[1px] active:shadow-none cursor-pointer flex items-center space-x-1"
                              >
                                <AlertOctagon className="w-3 h-3" />
                                <span>Suspend Driver</span>
                              </button>
                            )
                          ) : (
                            <span className="text-[10px] text-gray-500 font-bold uppercase">
                              Passenger Account
                            </span>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Driver Inspection Drawer */}
      {inspectedUser && (
        <div className="bg-white border-2 border-gray-900 p-6 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] font-mono space-y-4">
          <div className="flex items-center justify-between border-b-2 border-gray-900 pb-3">
            <div className="flex items-center space-x-2">
              <Info className="w-4 h-4 text-gray-950" />
              <h2 className="text-sm font-black uppercase tracking-tight text-gray-950">
                Account Inspection: {inspectedUser.name || 'Unnamed Member'}
              </h2>
            </div>
            <button
              type="button"
              onClick={() => setInspectedUser(null)}
              className="p-1 border border-gray-900 hover:bg-gray-100 cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4 text-xs">
            <div className="p-3 bg-gray-50 border border-gray-900">
              <span className="text-gray-500 block uppercase text-[10px]">Account ID</span>
              <span className="font-bold text-gray-950 select-all">{inspectedUser._id || 'N/A'}</span>
            </div>
            <div className="p-3 bg-gray-50 border border-gray-900">
              <span className="text-gray-500 block uppercase text-[10px]">Email & Mobile</span>
              <span className="font-bold text-gray-950 block">{inspectedUser.email || 'N/A'}</span>
              <span className="text-gray-600 block">{inspectedUser.phone || 'N/A'}</span>
            </div>
            <div className="p-3 bg-gray-50 border border-gray-900">
              <span className="text-gray-500 block uppercase text-[10px]">Access Status</span>
              <span
                className={`font-black uppercase inline-block mt-0.5 px-2 py-0.5 text-[10px] border ${
                  inspectedUser.accountStatus === 'suspended'
                    ? 'bg-red-600 text-white border-red-950'
                    : 'bg-emerald-100 text-emerald-950 border-emerald-900'
                }`}
              >
                {inspectedUser.accountStatus === 'suspended' ? 'SUSPENDED' : 'ACTIVE'}
              </span>
            </div>
            <div className="p-3 bg-gray-50 border border-gray-900">
              <span className="text-gray-500 block uppercase text-[10px]">Registration Date</span>
              <span className="font-bold text-gray-950">
                {inspectedUser.createdAt && !isNaN(new Date(inspectedUser.createdAt).getTime())
                  ? new Date(inspectedUser.createdAt).toLocaleString()
                  : 'N/A'}
              </span>
            </div>
          </div>

          {inspectedUser.accountStatus === 'suspended' && (
            <div className="p-4 bg-red-50 border-2 border-red-950 space-y-2">
              <div className="text-xs font-black uppercase text-red-950 flex items-center space-x-1.5">
                <AlertOctagon className="w-4 h-4 text-red-700" />
                <span>Active Suspension Audit Record</span>
              </div>
              <div className="text-xs text-red-900 font-bold">
                <span className="text-red-700">Reason: </span>
                {inspectedUser.suspensionReason || 'No reason specified'}
              </div>
              {inspectedUser.suspendedAt && !isNaN(new Date(inspectedUser.suspendedAt).getTime()) && (
                <div className="text-[11px] text-red-800">
                  <span className="text-red-700">Enforced At: </span>
                  {new Date(inspectedUser.suspendedAt).toLocaleString()}
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* Minimal Brutalism Suspension Confirmation Dialog */}
      {suspendingUser && (
        <div className="fixed inset-0 bg-black/70 flex items-center justify-center p-4 z-50 animate-in fade-in">
          <div className="w-full max-w-lg bg-white border-4 border-gray-950 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] p-6 space-y-5 font-mono">
            {/* Header */}
            <div className="border-b-2 border-gray-950 pb-3 flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <AlertOctagon className="w-6 h-6 text-red-600 shrink-0" />
                <h3 className="text-base font-black uppercase tracking-tight text-gray-950">
                  Suspend Driver Account
                </h3>
              </div>
              <button
                type="button"
                onClick={() => setSuspendingUser(null)}
                className="p-1 hover:bg-gray-100 border border-gray-900 cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Target Account Summary */}
            <div className="p-3 bg-gray-100 border-2 border-gray-900 space-y-1 text-xs">
              <div className="font-bold text-gray-950">
                Target Driver: <span className="font-black">{suspendingUser.name}</span>
              </div>
              <div className="text-gray-700">Email: {suspendingUser.email}</div>
              <div className="text-gray-700">Mobile: {suspendingUser.phone}</div>
              {suspendingUser.vehicle && (
                <div className="text-gray-700 font-bold">
                  Vehicle: {suspendingUser.vehicle.make} {suspendingUser.vehicle.model} ({suspendingUser.vehicle.registrationNumber})
                </div>
              )}
            </div>

            {/* Critical Warning Box */}
            <div className="p-3 bg-red-100 border-2 border-red-900 text-xs text-red-950 font-bold space-y-1">
              <div className="flex items-center space-x-1.5 uppercase tracking-wider text-red-900 font-black">
                <AlertTriangle className="w-4 h-4 shrink-0 text-red-700" />
                <span>Critical Access Enforcement Warning</span>
              </div>
              <p className="text-[11px] leading-relaxed">
                Suspending this driver blocks the <strong>entire user account</strong>. The driver will be immediately disconnected from Socket.IO telematics, existing JWTs will be rejected with HTTP 403, and they will be barred from both driver operations and passenger bookings.
              </p>
            </div>

            {/* Reason Input */}
            <div className="space-y-1.5">
              <label className="block text-xs font-black uppercase text-gray-950">
                Mandatory Suspension Reason (Min 5 characters)
              </label>
              <textarea
                required
                rows={3}
                placeholder="Specify regulatory violation, safety report, or verification reason..."
                value={suspensionReason}
                onChange={(e) => setSuspensionReason(e.target.value)}
                className="w-full p-2.5 text-xs bg-white border-2 border-gray-950 font-mono text-gray-950 focus:outline-none focus:ring-0 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
              />
              <div className="flex justify-between text-[10px] text-gray-600 font-bold">
                <span>Trimming enforced. Will be recorded in persistent immutable audit logs.</span>
                <span>{suspensionReason.trim().length}/500</span>
              </div>
            </div>

            {/* Dialog Error Banner */}
            {suspensionError && (
              <div className="p-2.5 bg-rose-50 border-2 border-rose-900 text-xs text-rose-950 font-bold">
                {suspensionError}
              </div>
            )}

            {/* Actions */}
            <div className="flex items-center justify-end space-x-3 pt-2 border-t-2 border-gray-950">
              <button
                type="button"
                disabled={suspensionSubmitting}
                onClick={() => setSuspendingUser(null)}
                className="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-950 text-xs font-bold uppercase border-2 border-gray-900 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] cursor-pointer disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={suspensionSubmitting || suspensionReason.trim().length < 5}
                onClick={handleConfirmSuspend}
                className="px-5 py-2 bg-red-600 hover:bg-red-700 text-white text-xs font-black uppercase border-2 border-red-950 shadow-[3px_3px_0px_0px_rgba(0,0,0,1)] active:translate-x-[1px] active:translate-y-[1px] active:shadow-none cursor-pointer disabled:opacity-50 flex items-center space-x-1.5"
              >
                {suspensionSubmitting ? (
                  <span>Enforcing Block...</span>
                ) : (
                  <>
                    <AlertOctagon className="w-3.5 h-3.5" />
                    <span>Confirm Account Suspension</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Minimal Brutalism Reactivation Confirmation Dialog */}
      {reactivatingUser && (
        <div className="fixed inset-0 bg-black/70 flex items-center justify-center p-4 z-50 animate-in fade-in">
          <div className="w-full max-w-md bg-white border-4 border-gray-950 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] p-6 space-y-4 font-mono">
            <div className="border-b-2 border-gray-950 pb-3 flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <RotateCcw className="w-5 h-5 text-gray-950 shrink-0" />
                <h3 className="text-base font-black uppercase tracking-tight text-gray-950">
                  Reactivate Account
                </h3>
              </div>
              <button
                type="button"
                onClick={() => setReactivatingUser(null)}
                className="p-1 hover:bg-gray-100 border border-gray-900 cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-3 bg-gray-100 border-2 border-gray-900 space-y-1 text-xs">
              <div className="font-bold text-gray-950">
                Driver: <span className="font-black">{reactivatingUser.name}</span>
              </div>
              <div className="text-gray-700">Email: {reactivatingUser.email}</div>
              {reactivatingUser.suspensionReason && (
                <div className="text-red-700 text-[11px] font-bold mt-1">
                  Prior Suspension Reason: {reactivatingUser.suspensionReason}
                </div>
              )}
            </div>

            <div className="text-xs text-gray-800 leading-relaxed">
              Confirming reactivation will immediately restore full platform access, enabling ride publication, booking capabilities, and telematics participation.
            </div>

            <div className="space-y-1">
              <label className="block text-[11px] font-black uppercase text-gray-950">
                Reactivation Reason or Note (Optional)
              </label>
              <input
                type="text"
                placeholder="Compliance verified, documentation updated, etc."
                value={reactivationReason}
                onChange={(e) => setReactivationReason(e.target.value)}
                className="w-full p-2 text-xs bg-white border-2 border-gray-950 font-mono text-gray-950 focus:outline-none shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
              />
            </div>

            {reactivationError && (
              <div className="p-2.5 bg-rose-50 border-2 border-rose-900 text-xs text-rose-950 font-bold">
                {reactivationError}
              </div>
            )}

            <div className="flex items-center justify-end space-x-3 pt-2 border-t-2 border-gray-950">
              <button
                type="button"
                disabled={reactivationSubmitting}
                onClick={() => setReactivatingUser(null)}
                className="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-950 text-xs font-bold uppercase border-2 border-gray-900 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] cursor-pointer disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={reactivationSubmitting}
                onClick={handleConfirmReactivate}
                className="px-5 py-2 bg-gray-950 hover:bg-gray-800 text-white text-xs font-black uppercase border-2 border-gray-950 shadow-[3px_3px_0px_0px_rgba(0,0,0,1)] active:translate-x-[1px] active:translate-y-[1px] active:shadow-none cursor-pointer disabled:opacity-50 flex items-center space-x-1.5"
              >
                {reactivationSubmitting ? (
                  <span>Reactivating...</span>
                ) : (
                  <>
                    <RotateCcw className="w-3.5 h-3.5" />
                    <span>Confirm Reactivation</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Unmask PII Modal */}
      {unmaskTarget && (
        <UnmaskModal
          isOpen={unmaskOpen}
          onClose={() => setUnmaskOpen(false)}
          resourceId={unmaskTarget.id}
          fieldName={unmaskTarget.field}
          fieldLabel={unmaskTarget.label}
          onSuccess={(unmaskedVal) => {
            setUnmaskedValues((prev) => ({
              ...prev,
              [`${unmaskTarget.field}_${unmaskTarget.id}`]: String(unmaskedVal),
            }));
          }}
        />
      )}
    </div>
  );
};
