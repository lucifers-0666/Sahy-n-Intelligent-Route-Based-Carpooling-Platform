import React, { useState, useEffect } from 'react';
import { UserItem } from '../../types/admin';
import { adminApi } from '../../services/api';
import {
  Users,
  Search,
  CheckCircle2,
  XCircle,
  Star,
  ShieldCheck,
} from 'lucide-react';

export const UsersTab: React.FC = () => {
  const [users, setUsers] = useState<UserItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [roleFilter, setRoleFilter] = useState<'all' | 'driver' | 'passenger'>('all');
  const [search, setSearch] = useState('');

  const fetchUsers = async () => {
    setLoading(true);
    setError(null);
    try {
      const backendStatus = roleFilter === 'driver' ? 'drivers' : 'all';
      const data = await adminApi.getUsers({
        status: backendStatus,
        search: search.trim() || undefined,
      });

      let filtered = data;
      if (roleFilter === 'driver') {
        filtered = data.filter(
          (u) =>
            u.capabilities?.canDrive ||
            u.driverProfile?.onboardingStatus === 'approved' ||
            u.vehicle
        );
      } else if (roleFilter === 'passenger') {
        filtered = data.filter(
          (u) =>
            !u.capabilities?.canDrive &&
            u.driverProfile?.onboardingStatus !== 'approved'
        );
      }

      setUsers(filtered);
    } catch (err: any) {
      setError(err.message || 'Failed to load users');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [roleFilter]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchUsers();
  };

  return (
    <div className="space-y-6">
      {/* Header and filters */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-extrabold text-textMain tracking-tight">
            User Directory & Community Accounts
          </h1>
          <p className="text-xs text-textMuted font-medium mt-0.5">
            Audit registered passenger accounts, verified carpool operators, and community trust metrics.
          </p>
        </div>

        {/* Role Filters */}
        <div className="flex items-center space-x-1.5 bg-white p-1 rounded-xl border border-surface-subtle shadow-xs">
          {[
            { id: 'all', label: 'All Accounts' },
            { id: 'driver', label: 'Verified Drivers' },
            { id: 'passenger', label: 'Passengers' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setRoleFilter(tab.id as any)}
              className={`px-3 py-1.5 text-xs font-bold rounded-lg transition-colors cursor-pointer ${
                roleFilter === tab.id
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
            placeholder="Search by name, email, or mobile number..."
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

      {/* Table Content */}
      {loading ? (
        <div className="bg-white rounded-2xl p-12 text-center text-textMuted text-xs">
          Loading user records from database...
        </div>
      ) : error ? (
        <div className="bg-rose-50 border border-rose-200 rounded-2xl p-6 text-center text-rose-800 text-xs">
          {error}
        </div>
      ) : users.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center border border-surface-subtle shadow-xs">
          <Users className="w-10 h-10 text-forest mx-auto mb-2" />
          <h3 className="text-sm font-bold text-textMain">No Accounts Found</h3>
          <p className="text-xs text-textMuted mt-1">
            No community accounts matched the search criteria.
          </p>
        </div>
      ) : (
        <div className="bg-white rounded-2xl border border-surface-subtle shadow-xs overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-surface text-textMuted font-bold uppercase tracking-wider border-b border-surface-subtle">
                <tr>
                  <th className="py-3 px-4">Member Name</th>
                  <th className="py-3 px-4">Contact Info</th>
                  <th className="py-3 px-4">Role & Verification</th>
                  <th className="py-3 px-4">Community Rating</th>
                  <th className="py-3 px-4">Trips Completed</th>
                  <th className="py-3 px-4 text-right">Joined</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-subtle">
                {users.map((u) => {
                  const isDriver =
                    u.capabilities?.canDrive ||
                    u.driverProfile?.onboardingStatus === 'approved' ||
                    !!u.vehicle;
                  const displayRating =
                    typeof u.rating === 'number'
                      ? u.rating.toFixed(1)
                      : u.rating && typeof (u.rating as any).average === 'number'
                      ? (u.rating as any).average.toFixed(1)
                      : '4.9';
                  return (
                    <tr key={u._id} className="hover:bg-surface/50 transition-colors">
                      <td className="py-3.5 px-4">
                        <div className="font-bold text-textMain flex items-center space-x-1.5">
                          <span>{u.name}</span>
                          {u.isVerified && <ShieldCheck className="w-3.5 h-3.5 text-forest" />}
                        </div>
                        <div className="text-[11px] text-textMuted font-mono">ID: {u._id.slice(-6)}</div>
                      </td>

                      <td className="py-3.5 px-4 font-medium">
                        <div className="text-textMain">{u.email}</div>
                        <div className="text-[11px] text-textMuted">{u.phone}</div>
                      </td>

                      <td className="py-3.5 px-4">
                        <span
                          className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                            isDriver
                              ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                              : 'bg-blue-50 text-blue-800 border border-blue-200'
                          }`}
                        >
                          {isDriver ? 'Verified Driver' : 'Passenger'}
                        </span>
                        {u.vehicle && (
                          <div className="text-[10px] text-forest font-semibold mt-1">
                            {u.vehicle.make} {u.vehicle.model} ({u.vehicle.registrationNumber})
                          </div>
                        )}
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="flex items-center space-x-1 font-bold text-textMain">
                          <Star className="w-3.5 h-3.5 text-amber-500 fill-amber-500" />
                          <span>{displayRating}</span>
                        </div>
                      </td>

                      <td className="py-3.5 px-4 font-medium text-textMain">
                        {u.totalRides || 0} journeys
                      </td>

                      <td className="py-3.5 px-4 text-right text-textMuted">
                        {u.createdAt ? new Date(u.createdAt).toLocaleDateString() : 'N/A'}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};
