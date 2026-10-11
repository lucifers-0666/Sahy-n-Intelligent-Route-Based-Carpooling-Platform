import React, { useState, useEffect } from 'react';
import { RideItem } from '../../types/admin';
import { adminApi } from '../../services/api';
import {
  Car,
  Ban,
  Clock,
  MapPin,
  CheckCircle,
  AlertTriangle,
  X,
} from 'lucide-react';

export const RidesTab: React.FC = () => {
  const [rides, setRides] = useState<RideItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>('all');

  // Selected ride for moderation dialog
  const [selectedRide, setSelectedRide] = useState<RideItem | null>(null);
  const [moderationReason, setModerationReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  const fetchRides = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await adminApi.getRides({
        status: statusFilter === 'all' ? undefined : statusFilter,
      });
      setRides(Array.isArray(data) ? data : []);
    } catch (err: any) {
      setError(err.message || 'Failed to load rides');
      setRides([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRides();
  }, [statusFilter]);

  const handleModerateRide = async (rideId: string) => {
    if (!moderationReason.trim()) {
      alert('Please provide a specific moderation reason for canceling this corridor ride.');
      return;
    }

    setActionLoading(true);
    try {
      await adminApi.moderateRide(rideId, 'cancel', moderationReason.trim());
      setSelectedRide(null);
      setModerationReason('');
      fetchRides();
    } catch (err: any) {
      alert(`Moderation failed: ${err.message}`);
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
            Corridor Ride Monitoring & Moderation
          </h1>
          <p className="text-xs text-textMuted font-medium mt-0.5">
            Audit live journeys, investigate route deviations, and enforce platform carpooling policies.
          </p>
        </div>

        {/* Status Filter */}
        <div className="flex items-center space-x-1 bg-white p-1 rounded-xl border border-surface-subtle shadow-xs overflow-x-auto">
          {[
            { id: 'all', label: 'All Trips' },
            { id: 'scheduled', label: 'Scheduled' },
            { id: 'active', label: 'Active Live' },
            { id: 'completed', label: 'Completed' },
            { id: 'cancelled', label: 'Cancelled' },
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

      {/* Rides List */}
      {loading ? (
        <div className="bg-white rounded-2xl p-12 text-center text-textMuted text-xs">
          Loading active and scheduled corridors...
        </div>
      ) : error ? (
        <div className="bg-rose-50 border border-rose-200 rounded-2xl p-6 text-center text-rose-800 text-xs">
          {error}
        </div>
      ) : rides.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center border border-surface-subtle shadow-xs">
          <Car className="w-10 h-10 text-forest mx-auto mb-2" />
          <h3 className="text-sm font-bold text-textMain">No Rides Found</h3>
          <p className="text-xs text-textMuted mt-1">
            No corridor rides match the selected status filter.
          </p>
        </div>
      ) : (
        <div className="bg-white rounded-2xl border border-surface-subtle shadow-xs overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-surface text-textMuted font-bold uppercase tracking-wider border-b border-surface-subtle">
                <tr>
                  <th className="py-3 px-4">Corridor Route</th>
                  <th className="py-3 px-4">Driver</th>
                  <th className="py-3 px-4">Departure</th>
                  <th className="py-3 px-4">Seats & Cost</th>
                  <th className="py-3 px-4">Status</th>
                  <th className="py-3 px-4 text-right">Moderation</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-subtle">
                {rides.map((ride) => {
                  return (
                    <tr key={ride._id} className="hover:bg-surface/50 transition-colors">
                      <td className="py-3.5 px-4">
                        <div className="flex items-center space-x-1.5 font-bold text-textMain">
                          <MapPin className="w-3.5 h-3.5 text-forest shrink-0" />
                          <span>{ride.origin?.name || 'Origin'}</span>
                          <span className="text-textMuted font-normal">→</span>
                          <span>{ride.destination?.name || 'Destination'}</span>
                        </div>
                        <div className="text-[11px] text-textMuted font-mono mt-0.5">
                          ID: {ride._id.slice(-8)}
                        </div>
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="font-bold text-textMain">
                          {ride.driver?.name || 'Unknown Driver'}
                        </div>
                        <div className="text-[11px] text-textMuted">
                          {ride.driver?.phone || 'No phone'} · Rating: {typeof ride.driver?.rating === 'number' ? ride.driver.rating.toFixed(1) : (ride.driver?.rating && typeof (ride.driver.rating as any).average === 'number' ? (ride.driver.rating as any).average.toFixed(1) : '5.0')}
                        </div>
                        {ride.vehicle && (
                          <div className="text-[10px] text-forest font-semibold mt-0.5">
                            {ride.vehicle.make} {ride.vehicle.model} ({ride.vehicle.registrationNumber})
                          </div>
                        )}
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="flex items-center space-x-1 text-textMain font-medium">
                          <Clock className="w-3.5 h-3.5 text-textMuted" />
                          <span>
                            {ride.departureTime
                              ? new Date(ride.departureTime).toLocaleDateString() + ' ' + new Date(ride.departureTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                              : 'Scheduled'}
                          </span>
                        </div>
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="font-bold text-textMain">
                          {ride.availableSeats ?? 0} of {ride.totalSeats ?? 4} seats open
                        </div>
                        <div className="text-[11px] text-forest font-semibold">
                          ₹{ride.contributionPerSeat ?? ride.pricePerSeat ?? 0} / seat (fuel share)
                        </div>
                      </td>

                      <td className="py-3.5 px-4">
                        <span
                          className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                            ride.status === 'active' || ride.status === 'boarding'
                              ? 'bg-blue-50 text-blue-800 border border-blue-200'
                              : ride.status === 'scheduled'
                              ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                              : ride.status === 'completed'
                              ? 'bg-gray-100 text-gray-700'
                              : 'bg-rose-50 text-rose-800 border border-rose-200'
                          }`}
                        >
                          {(ride.status || 'SCHEDULED').toUpperCase()}
                        </span>
                      </td>

                      <td className="py-3.5 px-4 text-right">
                        {ride.status !== 'completed' && ride.status !== 'cancelled' ? (
                          <button
                            onClick={() => {
                              setSelectedRide(ride);
                              setModerationReason('');
                            }}
                            className="px-3 py-1.5 bg-rose-50 hover:bg-rose-100 text-rose-700 rounded-lg font-bold text-xs transition-colors cursor-pointer flex items-center space-x-1 ml-auto"
                          >
                            <Ban className="w-3.5 h-3.5" />
                            <span>Moderate</span>
                          </button>
                        ) : (
                          <span className="text-textMuted text-[11px] font-medium">No actions</span>
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

      {/* Moderation Reason Modal */}
      {selectedRide && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-xl border border-surface-subtle space-y-5">
            <div className="flex items-start justify-between">
              <div>
                <span className="text-xs font-bold text-rose-700 uppercase tracking-wider flex items-center space-x-1">
                  <AlertTriangle className="w-3.5 h-3.5" />
                  <span>Admin Moderation Action</span>
                </span>
                <h3 className="text-lg font-extrabold text-textMain mt-1">
                  Moderate / Cancel Corridor Ride
                </h3>
                <p className="text-xs text-textMuted">
                  {selectedRide.origin?.name} → {selectedRide.destination?.name}
                </p>
              </div>
              <button
                onClick={() => setSelectedRide(null)}
                className="p-1 rounded-lg text-textMuted hover:bg-surface cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-3.5 bg-rose-50 border border-rose-200 rounded-2xl text-xs text-rose-900 space-y-1">
              <span className="font-bold">Administrative Warning:</span>
              <p>
                Canceling this ride will immediately refund/notify all booked passengers and update the corridor availability in real-time telematics.
              </p>
            </div>

            <div>
              <label className="block text-xs font-bold text-textMain mb-1">
                Reason for Moderation Cancellation:
              </label>
              <textarea
                placeholder="E.g., Severe safety violation reported, route closure on NH-48, driver non-compliance..."
                value={moderationReason}
                onChange={(e) => setModerationReason(e.target.value)}
                rows={3}
                className="w-full bg-white p-3 text-xs rounded-xl border border-surface-subtle focus:outline-none focus:border-rose-600 text-textMain"
              />
            </div>

            <div className="flex gap-3 pt-2">
              <button
                onClick={() => setSelectedRide(null)}
                className="flex-1 py-2.5 px-4 rounded-xl border border-gray-200 text-textMuted font-bold text-xs hover:bg-gray-50 transition-colors cursor-pointer"
              >
                Dismiss
              </button>
              <button
                onClick={() => handleModerateRide(selectedRide._id)}
                disabled={actionLoading}
                className="flex-1 py-2.5 px-4 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs transition-colors shadow-sm cursor-pointer"
              >
                {actionLoading ? 'Canceling...' : 'Confirm Cancellation'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
