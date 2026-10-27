import React, { useState, useEffect } from 'react';
import { UserItem } from '../../types/admin';
import { adminApi } from '../../services/api';
import { UnmaskModal } from '../UnmaskModal';
import { PageHeader } from '../ui/PageHeader';
import { Badge } from '../ui/Badge';
import { EmptyState } from '../ui/EmptyState';
import { ErrorState } from '../ui/ErrorState';
import { Pagination } from '../ui/Pagination';
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
  Phone,
  MessageSquare,
  Mail,
  Copy,
  Car,
  Filter,
} from 'lucide-react';

export const UsersTab: React.FC = () => {
  const [users, setUsers] = useState<UserItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [roleFilter, setRoleFilter] = useState<'all' | 'driver' | 'passenger'>('all');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'suspended'>('all');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const pageSize = 15;

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

  const copyToClipboard = (text: string, label: string) => {
    if (navigator?.clipboard?.writeText) {
      navigator.clipboard.writeText(text);
      setFeedback({ type: 'success', message: `${label} copied to clipboard.` });
      setTimeout(() => setFeedback(null), 3000);
    }
  };

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
      setPage(1);
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
        message: `Account for ${suspendingUser.name} has been suspended with audit logging.`,
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

  // Pagination slice
  const totalUsers = users.length;
  const paginatedUsers = users.slice((page - 1) * pageSize, page * pageSize);

  return (
    <div className="space-y-6">
      {/* Header */}
      <PageHeader
        title="User Directory & Access Control"
        subtitle="Audit registered accounts, driver eligibility, and execute fail-closed suspensions with DPDP-compliant PII protection."
        breadcrumbs={[
          { label: 'Operations' },
          { label: 'User Directory' },
        ]}
      />

      {/* Global Feedback Banner */}
      {feedback && (
        <div
          className={`p-3.5 rounded-xl text-xs font-semibold flex items-center justify-between border shadow-xs animate-in fade-in ${
            feedback.type === 'success'
              ? 'bg-emerald-50/90 border-emerald-200 text-emerald-950'
              : 'bg-rose-50/90 border-rose-200 text-rose-950'
          }`}
        >
          <div className="flex items-center space-x-2">
            {feedback.type === 'success' ? (
              <CheckCircle className="w-4 h-4 text-emerald-700 shrink-0" />
            ) : (
              <AlertTriangle className="w-4 h-4 text-rose-700 shrink-0" />
            )}
            <span>{feedback.message}</span>
          </div>
          <button
            onClick={() => setFeedback(null)}
            className="p-1 rounded-lg hover:bg-black/5 cursor-pointer text-textMuted"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Search and Filters Toolbar */}
      <div className="card p-4 flex flex-col md:flex-row items-stretch md:items-center justify-between gap-4">
        {/* Search */}
        <form onSubmit={handleSearchSubmit} className="relative flex-1">
          <Search className="w-4 h-4 text-textMuted absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search by name, email, or mobile number..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-xs bg-surface rounded-xl border border-surface-subtle text-textMain placeholder-textMuted focus:outline-none focus:ring-2 focus:ring-forest/20 focus:border-forest transition-all"
          />
        </form>

        {/* Filter Pills */}
        <div className="flex flex-wrap items-center gap-2">
          {/* Role Filter */}
          <div className="flex items-center bg-surface p-1 rounded-xl border border-surface-subtle">
            {[
              { id: 'all', label: 'All Roles' },
              { id: 'driver', label: 'Drivers' },
              { id: 'passenger', label: 'Passengers' },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setRoleFilter(tab.id as any)}
                className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-all cursor-pointer ${
                  roleFilter === tab.id
                    ? 'bg-forest text-white shadow-xs'
                    : 'text-textMuted hover:text-textMain hover:bg-white/50'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>

          {/* Status Filter */}
          <div className="flex items-center bg-surface p-1 rounded-xl border border-surface-subtle">
            {[
              { id: 'all', label: 'All Status' },
              { id: 'active', label: 'Active' },
              { id: 'suspended', label: 'Suspended' },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setStatusFilter(tab.id as any)}
                className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-all cursor-pointer ${
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
      </div>

      {/* Main Table / State View */}
      {loading ? (
        <div className="card p-12 text-center">
          <div className="w-8 h-8 border-2 border-forest border-t-transparent rounded-full animate-spin mx-auto mb-3" />
          <p className="text-xs font-semibold text-textMuted">Querying accounts from database...</p>
        </div>
      ) : error ? (
        <ErrorState
          title="Failed to Load Accounts"
          message={error}
          onRetry={fetchUsers}
        />
      ) : users.length === 0 ? (
        <EmptyState
          icon={Users}
          title="No Accounts Found"
          description="No community accounts matched the active filter criteria or search query."
          actionLabel="Clear Filters"
          onAction={() => {
            setRoleFilter('all');
            setStatusFilter('all');
            setSearch('');
          }}
        />
      ) : (
        <div className="card p-0 overflow-hidden shadow-xs">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-surface/60 text-textMuted font-bold uppercase tracking-wider text-[11px] border-b border-surface-subtle">
                <tr>
                  <th className="py-3.5 px-4">Member Name</th>
                  <th className="py-3.5 px-4">Contact Info</th>
                  <th className="py-3.5 px-4">Role & Eligibility</th>
                  <th className="py-3.5 px-4">Account Status</th>
                  <th className="py-3.5 px-4">Rating</th>
                  <th className="py-3.5 px-4">Total Trips</th>
                  <th className="py-3.5 px-4 text-right">Access Controls</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-subtle">
                {paginatedUsers.map((u) => {
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
                      className="hover:bg-surface/50 transition-colors cursor-pointer"
                    >
                      <td className="py-3.5 px-4">
                        <div className="font-bold text-textMain flex items-center space-x-1.5">
                          <span>{u?.name || 'Unnamed Member'}</span>
                          {u?.isVerified && (
                            <span title="Government KYC Verified">
                              <ShieldCheck className="w-3.5 h-3.5 text-forest" />
                            </span>
                          )}
                        </div>
                        <div className="text-[11px] text-textMuted font-mono mt-0.5">ID: {shortId}</div>
                      </td>

                      <td className="py-3.5 px-4" onClick={(e) => e.stopPropagation()}>
                        {(() => {
                          const unmaskedEmail = unmaskedValues[`email_${userIdStr}`];
                          const unmaskedPhone = unmaskedValues[`phone_${userIdStr}`];
                          const cleanPhone = (unmaskedPhone || '').replace(/[\s\-]/g, '');
                          const digitsOnly = cleanPhone.replace(/\D/g, '');

                          return (
                            <div className="space-y-1">
                              {/* Email Row */}
                              <div className="flex items-center justify-between space-x-2">
                                <span className={`truncate max-w-[160px] text-xs ${unmaskedEmail ? 'text-textMain font-bold' : 'text-textMuted'}`}>
                                  {unmaskedEmail || u?.email || 'N/A'}
                                </span>
                                {unmaskedEmail ? (
                                  <div className="flex items-center space-x-1 shrink-0">
                                    <a
                                      href={`mailto:${unmaskedEmail}`}
                                      title="Send Email"
                                      className="p-1 rounded-md hover:bg-surface text-textMuted hover:text-textMain transition-colors"
                                    >
                                      <Mail className="w-3.5 h-3.5" />
                                    </a>
                                    <button
                                      type="button"
                                      onClick={() => copyToClipboard(unmaskedEmail, 'Email')}
                                      title="Copy Email"
                                      className="p-1 rounded-md hover:bg-surface text-textMuted hover:text-textMain transition-colors cursor-pointer"
                                    >
                                      <Copy className="w-3.5 h-3.5" />
                                    </button>
                                  </div>
                                ) : (
                                  userIdStr && (
                                    <button
                                      type="button"
                                      onClick={() => {
                                        setUnmaskTarget({ id: userIdStr, field: 'email', label: 'Email Address' });
                                        setUnmaskOpen(true);
                                      }}
                                      className="text-[10px] font-bold text-forest hover:text-forest-dark hover:underline shrink-0"
                                    >
                                      Unmask
                                    </button>
                                  )
                                )}
                              </div>

                              {/* Phone Row */}
                              <div className="flex items-center justify-between space-x-2 text-[11px]">
                                <span className={`font-mono ${unmaskedPhone ? 'text-forest font-bold' : 'text-textMuted'}`}>
                                  {unmaskedPhone || u?.phone || 'N/A'}
                                </span>
                                {unmaskedPhone ? (
                                  <div className="flex items-center space-x-1 shrink-0">
                                    <a
                                      href={`tel:${cleanPhone}`}
                                      title="Direct Phone Call"
                                      className="px-1.5 py-0.5 bg-emerald-50 hover:bg-emerald-100 text-emerald-800 rounded text-[10px] font-semibold flex items-center space-x-1 transition-colors"
                                    >
                                      <Phone className="w-2.5 h-2.5" />
                                      <span>Call</span>
                                    </a>
                                    <a
                                      href={`https://wa.me/${digitsOnly}`}
                                      target="_blank"
                                      rel="noopener noreferrer"
                                      title="WhatsApp Direct Message"
                                      className="px-1.5 py-0.5 bg-emerald-50 hover:bg-emerald-100 text-emerald-800 rounded text-[10px] font-semibold flex items-center space-x-1 transition-colors"
                                    >
                                      <MessageSquare className="w-2.5 h-2.5" />
                                      <span>Chat</span>
                                    </a>
                                    <button
                                      type="button"
                                      onClick={() => copyToClipboard(unmaskedPhone, 'Phone number')}
                                      title="Copy Phone Number"
                                      className="p-1 rounded-md hover:bg-surface text-textMuted hover:text-textMain transition-colors cursor-pointer"
                                    >
                                      <Copy className="w-3 h-3" />
                                    </button>
                                  </div>
                                ) : (
                                  userIdStr && (
                                    <button
                                      type="button"
                                      onClick={() => {
                                        setUnmaskTarget({ id: userIdStr, field: 'phone', label: 'Phone Number' });
                                        setUnmaskOpen(true);
                                      }}
                                      className="text-[10px] font-bold text-forest hover:text-forest-dark hover:underline shrink-0"
                                    >
                                      Unmask
                                    </button>
                                  )
                                )}
                              </div>
                            </div>
                          );
                        })()}
                      </td>

                      <td className="py-3.5 px-4">
                        <Badge variant={isEligibleDriver ? 'blue' : 'gray'}>
                          {isEligibleDriver ? 'Eligible Driver' : 'Passenger Only'}
                        </Badge>
                        {u?.vehicle && typeof u.vehicle === 'object' && (
                          <div className="text-[11px] text-textMuted flex items-center space-x-1 mt-1 font-medium">
                            <Car className="w-3 h-3 text-textLight shrink-0" />
                            <span>
                              {u.vehicle.make || ''} {u.vehicle.model || ''}{' '}
                              {u.vehicle.registrationNumber ? `(${u.vehicle.registrationNumber})` : ''}
                            </span>
                          </div>
                        )}
                      </td>

                      <td className="py-3.5 px-4">
                        {isSuspended ? (
                          <div>
                            <Badge variant="rose">Suspended</Badge>
                            {u.suspensionReason && (
                              <div
                                title={u.suspensionReason}
                                className="text-[11px] text-rose-700 truncate max-w-[150px] mt-1 font-medium"
                              >
                                {u.suspensionReason}
                              </div>
                            )}
                          </div>
                        ) : (
                          <Badge variant="emerald">Active</Badge>
                        )}
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="flex items-center space-x-1 font-semibold text-textMain">
                          <Star className="w-3.5 h-3.5 text-amber-500 fill-amber-500" />
                          <span>{displayRating}</span>
                        </div>
                      </td>

                      <td className="py-3.5 px-4 font-semibold text-textMain">
                        {u.totalRides || 0}
                      </td>

                      <td className="py-3.5 px-4 text-right">
                        <div className="flex items-center justify-end space-x-2">
                          {isEligibleDriver ? (
                            isSuspended ? (
                              <button
                                type="button"
                                onClick={(e) => handleOpenReactivateModal(u, e)}
                                className="px-2.5 py-1.5 bg-forest/10 hover:bg-forest/20 text-forest rounded-lg text-xs font-bold transition-colors cursor-pointer flex items-center space-x-1"
                              >
                                <RotateCcw className="w-3 h-3" />
                                <span>Reactivate</span>
                              </button>
                            ) : (
                              <button
                                type="button"
                                onClick={(e) => handleOpenSuspendModal(u, e)}
                                className="px-2.5 py-1.5 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 rounded-lg text-xs font-bold transition-colors cursor-pointer flex items-center space-x-1"
                              >
                                <AlertOctagon className="w-3 h-3" />
                                <span>Suspend</span>
                              </button>
                            )
                          ) : (
                            <span className="text-[11px] text-textMuted font-medium">
                              Passenger
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

          {/* Pagination */}
          <div className="p-4 border-t border-surface-subtle">
            <Pagination
              page={page}
              totalPages={Math.ceil(totalUsers / pageSize)}
              totalItems={totalUsers}
              pageSize={pageSize}
              onPageChange={setPage}
            />
          </div>
        </div>
      )}

      {/* Account Inspection Drawer */}
      {inspectedUser && (
        <div className="card p-6 shadow-md border-forest/20 space-y-4 animate-in fade-in">
          <div className="flex items-center justify-between border-b border-surface-subtle pb-3">
            <div className="flex items-center space-x-2">
              <Info className="w-4 h-4 text-forest" />
              <h2 className="text-sm font-bold text-textMain">
                Account Inspection: {inspectedUser.name || 'Unnamed Member'}
              </h2>
            </div>
            <button
              type="button"
              onClick={() => setInspectedUser(null)}
              className="p-1 rounded-lg hover:bg-surface text-textMuted hover:text-textMain cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4 text-xs">
            <div className="p-3 bg-surface rounded-xl border border-surface-subtle">
              <span className="text-textMuted block text-[10px] font-bold uppercase tracking-wider">Account ID</span>
              <span className="font-mono font-semibold text-textMain select-all">{inspectedUser._id || 'N/A'}</span>
            </div>

            <div className="p-3 bg-surface rounded-xl border border-surface-subtle">
              <div className="flex items-center justify-between mb-1">
                <span className="text-textMuted text-[10px] font-bold uppercase tracking-wider">Contact</span>
                {(!unmaskedValues[`phone_${inspectedUser._id}`] || !unmaskedValues[`email_${inspectedUser._id}`]) && (
                  <button
                    type="button"
                    onClick={() => {
                      setUnmaskTarget({ id: String(inspectedUser._id), field: 'phone', label: 'Phone Number' });
                      setUnmaskOpen(true);
                    }}
                    className="text-[10px] font-bold text-forest hover:underline"
                  >
                    Unmask PII
                  </button>
                )}
              </div>
              <span className="font-semibold text-textMain block truncate">
                {unmaskedValues[`email_${inspectedUser._id}`] || inspectedUser.email || 'N/A'}
              </span>
              <div className="flex items-center justify-between mt-1 text-[11px] font-mono">
                <span className={unmaskedValues[`phone_${inspectedUser._id}`] ? 'text-forest font-bold' : 'text-textMuted'}>
                  {unmaskedValues[`phone_${inspectedUser._id}`] || inspectedUser.phone || 'N/A'}
                </span>
                {unmaskedValues[`phone_${inspectedUser._id}`] && (
                  <div className="flex items-center space-x-1 shrink-0 ml-2">
                    <a
                      href={`tel:${(unmaskedValues[`phone_${inspectedUser._id}`] || '').replace(/[\s\-]/g, '')}`}
                      title="Direct Phone Call"
                      className="px-1.5 py-0.5 bg-emerald-100 text-emerald-900 rounded text-[10px] font-semibold"
                    >
                      Call
                    </a>
                    <a
                      href={`https://wa.me/${(unmaskedValues[`phone_${inspectedUser._id}`] || '').replace(/\D/g, '')}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      title="Direct WhatsApp"
                      className="px-1.5 py-0.5 bg-emerald-100 text-emerald-900 rounded text-[10px] font-semibold"
                    >
                      Chat
                    </a>
                  </div>
                )}
              </div>
            </div>

            <div className="p-3 bg-surface rounded-xl border border-surface-subtle">
              <span className="text-textMuted block text-[10px] font-bold uppercase tracking-wider">Access Status</span>
              <div className="mt-1">
                <Badge variant={inspectedUser.accountStatus === 'suspended' ? 'rose' : 'emerald'}>
                  {inspectedUser.accountStatus === 'suspended' ? 'SUSPENDED' : 'ACTIVE'}
                </Badge>
              </div>
            </div>

            <div className="p-3 bg-surface rounded-xl border border-surface-subtle">
              <span className="text-textMuted block text-[10px] font-bold uppercase tracking-wider">Registration Date</span>
              <span className="font-semibold text-textMain mt-1 block">
                {inspectedUser.createdAt && !isNaN(new Date(inspectedUser.createdAt).getTime())
                  ? new Date(inspectedUser.createdAt).toLocaleDateString()
                  : 'N/A'}
              </span>
            </div>
          </div>

          {inspectedUser.accountStatus === 'suspended' && (
            <div className="p-4 bg-rose-50/80 rounded-xl border border-rose-200 space-y-1.5">
              <div className="text-xs font-bold text-rose-950 flex items-center space-x-1.5">
                <AlertOctagon className="w-4 h-4 text-rose-700" />
                <span>Active Suspension Audit Record</span>
              </div>
              <div className="text-xs text-rose-900 font-medium">
                <span className="text-rose-700 font-semibold">Reason: </span>
                {inspectedUser.suspensionReason || 'No reason specified'}
              </div>
              {inspectedUser.suspendedAt && !isNaN(new Date(inspectedUser.suspendedAt).getTime()) && (
                <div className="text-[11px] text-rose-800 font-mono">
                  Enforced At: {new Date(inspectedUser.suspendedAt).toLocaleString()}
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* Suspension Confirmation Dialog */}
      {suspendingUser && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-in fade-in">
          <div className="w-full max-w-lg bg-white rounded-2xl shadow-xl p-6 space-y-5 border border-surface-subtle">
            <div className="border-b border-surface-subtle pb-3 flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <div className="w-8 h-8 rounded-lg bg-rose-50 flex items-center justify-center">
                  <AlertOctagon className="w-5 h-5 text-rose-600" />
                </div>
                <h3 className="text-base font-bold text-textMain">
                  Suspend Driver Account
                </h3>
              </div>
              <button
                type="button"
                onClick={() => setSuspendingUser(null)}
                className="p-1 rounded-lg hover:bg-surface text-textMuted cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-3.5 bg-surface rounded-xl border border-surface-subtle space-y-1 text-xs">
              <div className="font-semibold text-textMain">
                Target Driver: <span className="font-bold">{suspendingUser.name}</span>
              </div>
              <div className="text-textMuted">Email: {suspendingUser.email}</div>
              <div className="text-textMuted">Mobile: {suspendingUser.phone}</div>
              {suspendingUser.vehicle && (
                <div className="text-textMuted font-medium">
                  Vehicle: {suspendingUser.vehicle.make} {suspendingUser.vehicle.model} ({suspendingUser.vehicle.registrationNumber})
                </div>
              )}
            </div>

            <div className="p-3.5 bg-rose-50 rounded-xl border border-rose-200 text-xs text-rose-950 font-medium space-y-1">
              <div className="flex items-center space-x-1.5 uppercase font-bold text-rose-900 tracking-wider text-[11px]">
                <AlertTriangle className="w-3.5 h-3.5 shrink-0 text-rose-700" />
                <span>Fail-Closed Access Enforcement</span>
              </div>
              <p className="text-[11px] leading-relaxed text-rose-900">
                Suspending this driver terminates active Socket.IO telemetry, revokes JWT permissions immediately, and prevents booking or driving operations across all corridors.
              </p>
            </div>

            <div className="space-y-1.5">
              <label className="block text-xs font-bold text-textMain">
                Mandatory Suspension Reason (Min 5 characters)
              </label>
              <textarea
                required
                rows={3}
                placeholder="Specify regulatory violation, safety report, or verification issue..."
                value={suspensionReason}
                onChange={(e) => setSuspensionReason(e.target.value)}
                className="w-full p-3 text-xs bg-surface rounded-xl border border-surface-subtle text-textMain focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500 transition-all"
              />
              <div className="flex justify-between text-[11px] text-textMuted">
                <span>Recorded in persistent immutable audit ledger.</span>
                <span className="font-mono">{suspensionReason.trim().length}/500</span>
              </div>
            </div>

            {suspensionError && (
              <div className="p-2.5 bg-rose-50 rounded-lg border border-rose-200 text-xs text-rose-950 font-semibold">
                {suspensionError}
              </div>
            )}

            <div className="flex items-center justify-end space-x-3 pt-2 border-t border-surface-subtle">
              <button
                type="button"
                disabled={suspensionSubmitting}
                onClick={() => setSuspendingUser(null)}
                className="px-4 py-2 bg-surface hover:bg-surface-subtle text-textMain text-xs font-bold rounded-xl transition-colors cursor-pointer disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={suspensionSubmitting || suspensionReason.trim().length < 5}
                onClick={handleConfirmSuspend}
                className="px-5 py-2 bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold rounded-xl shadow-xs transition-colors cursor-pointer disabled:opacity-50 flex items-center space-x-1.5"
              >
                {suspensionSubmitting ? (
                  <span>Enforcing...</span>
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

      {/* Reactivation Confirmation Dialog */}
      {reactivatingUser && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-in fade-in">
          <div className="w-full max-w-md bg-white rounded-2xl shadow-xl p-6 space-y-4 border border-surface-subtle">
            <div className="border-b border-surface-subtle pb-3 flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <div className="w-8 h-8 rounded-lg bg-emerald-50 flex items-center justify-center">
                  <RotateCcw className="w-5 h-5 text-forest" />
                </div>
                <h3 className="text-base font-bold text-textMain">
                  Reactivate Account
                </h3>
              </div>
              <button
                type="button"
                onClick={() => setReactivatingUser(null)}
                className="p-1 rounded-lg hover:bg-surface text-textMuted cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-3 bg-surface rounded-xl border border-surface-subtle space-y-1 text-xs">
              <div className="font-semibold text-textMain">
                Driver: <span className="font-bold">{reactivatingUser.name}</span>
              </div>
              <div className="text-textMuted">Email: {reactivatingUser.email}</div>
              {reactivatingUser.suspensionReason && (
                <div className="text-rose-700 text-[11px] font-medium mt-1">
                  Prior Reason: {reactivatingUser.suspensionReason}
                </div>
              )}
            </div>

            <p className="text-xs text-textMuted leading-relaxed">
              Confirming reactivation will immediately restore full platform access, enabling ride publication, booking capabilities, and telematics participation.
            </p>

            <div className="space-y-1">
              <label className="block text-xs font-bold text-textMain">
                Reactivation Reason or Note (Optional)
              </label>
              <input
                type="text"
                placeholder="Compliance verified, documentation updated, etc."
                value={reactivationReason}
                onChange={(e) => setReactivationReason(e.target.value)}
                className="w-full p-2.5 text-xs bg-surface rounded-xl border border-surface-subtle text-textMain focus:outline-none focus:ring-2 focus:ring-forest/20 focus:border-forest transition-all"
              />
            </div>

            {reactivationError && (
              <div className="p-2.5 bg-rose-50 rounded-lg border border-rose-200 text-xs text-rose-950 font-semibold">
                {reactivationError}
              </div>
            )}

            <div className="flex items-center justify-end space-x-3 pt-2 border-t border-surface-subtle">
              <button
                type="button"
                disabled={reactivationSubmitting}
                onClick={() => setReactivatingUser(null)}
                className="px-4 py-2 bg-surface hover:bg-surface-subtle text-textMain text-xs font-bold rounded-xl transition-colors cursor-pointer disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={reactivationSubmitting}
                onClick={handleConfirmReactivate}
                className="px-5 py-2 bg-forest hover:bg-forest-dark text-white text-xs font-bold rounded-xl shadow-xs transition-colors cursor-pointer disabled:opacity-50 flex items-center space-x-1.5"
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
