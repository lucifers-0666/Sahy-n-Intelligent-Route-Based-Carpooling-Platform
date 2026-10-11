import React, { useState, useEffect } from 'react';
import { BookingItem } from '../../types/admin';
import { adminApi } from '../../services/api';
import {
  Bookmark,
  Calendar,
  MapPin,
  IndianRupee,
  User,
  Clock,
  CheckCircle,
  XCircle,
  AlertCircle,
  X,
  CreditCard,
} from 'lucide-react';

export const BookingsTab: React.FC = () => {
  const [bookings, setBookings] = useState<BookingItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [paymentFilter, setPaymentFilter] = useState<string>('all');
  const [selectedBooking, setSelectedBooking] = useState<BookingItem | null>(null);
  const [refundReason, setRefundReason] = useState('');
  const [refundLoading, setRefundLoading] = useState(false);
  const [actionFeedback, setActionFeedback] = useState<string | null>(null);

  const fetchBookings = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await adminApi.getBookings({
        status: statusFilter,
        paymentStatus: paymentFilter,
      });
      setBookings(Array.isArray(data) ? data : []);
    } catch (err: any) {
      setError(err.message || 'Failed to load bookings');
      setBookings([]);
    } finally {
      setLoading(false);
    }
  };

  const handleForceRefund = async () => {
    if (!selectedBooking) return;
    if (!refundReason.trim()) {
      alert('Please specify a valid dispute reason to authorize force refund.');
      return;
    }
    setRefundLoading(true);
    try {
      await adminApi.forceRefundBooking(selectedBooking._id, refundReason.trim());
      setActionFeedback('Disputed booking refunded successfully.');
      setRefundReason('');
      fetchBookings();
      setTimeout(() => setSelectedBooking(null), 1200);
    } catch (err: any) {
      alert(`Force refund failed: ${err.message}`);
    } finally {
      setRefundLoading(false);
    }
  };

  useEffect(() => {
    fetchBookings();
  }, [statusFilter, paymentFilter]);

  return (
    <div className="space-y-6">
      {/* Header and filters */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-extrabold text-textMain tracking-tight">
            Booking & Cancellation Investigation
          </h1>
          <p className="text-xs text-textMuted font-medium mt-0.5">
            Audit passenger seat reservations, fuel contribution settlements, and cancellation logs.
          </p>
        </div>

        {/* Status Filters */}
        <div className="flex items-center space-x-1 bg-white p-1 rounded-xl border border-surface-subtle shadow-xs overflow-x-auto">
          {[
            { id: 'all', label: 'All Bookings' },
            { id: 'accepted', label: 'Accepted' },
            { id: 'pending', label: 'Pending' },
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

      {/* Payment sub-filter */}
      <div className="flex items-center space-x-2 text-xs">
        <span className="text-textMuted font-bold">Payment Status:</span>
        {['all', 'paid', 'pending', 'refunded', 'escrow_released'].map((p) => (
          <button
            key={p}
            onClick={() => setPaymentFilter(p)}
            className={`px-2.5 py-1 rounded-lg font-medium transition-colors cursor-pointer capitalize ${
              paymentFilter === p
                ? 'bg-forest-light text-forest font-bold'
                : 'text-textMuted hover:text-textMain'
            }`}
          >
            {p.replace('_', ' ')}
          </button>
        ))}
      </div>

      {/* Content */}
      {loading ? (
        <div className="bg-white rounded-2xl p-12 text-center text-textMuted text-xs">
          Loading booking reservation records from database...
        </div>
      ) : error ? (
        <div className="bg-rose-50 border border-rose-200 rounded-2xl p-6 text-center text-rose-800 text-xs">
          {error}
        </div>
      ) : bookings.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center border border-surface-subtle shadow-xs">
          <Bookmark className="w-10 h-10 text-forest mx-auto mb-2" />
          <h3 className="text-sm font-bold text-textMain">No Bookings Found</h3>
          <p className="text-xs text-textMuted mt-1">
            No booking reservations match the selected status filters.
          </p>
        </div>
      ) : (
        <div className="bg-white rounded-2xl border border-surface-subtle shadow-xs overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-surface text-textMuted font-bold uppercase tracking-wider border-b border-surface-subtle">
                <tr>
                  <th className="py-3 px-4">Passenger</th>
                  <th className="py-3 px-4">Corridor Trip</th>
                  <th className="py-3 px-4">Seats & Split</th>
                  <th className="py-3 px-4">Booking State</th>
                  <th className="py-3 px-4">Payment</th>
                  <th className="py-3 px-4 text-right">Audit</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-subtle">
                {bookings.map((b) => {
                  return (
                    <tr key={b._id} className="hover:bg-surface/50 transition-colors">
                      <td className="py-3.5 px-4">
                        <div className="font-bold text-textMain">{b.passenger?.name || 'Passenger'}</div>
                        <div className="text-[11px] text-textMuted">{b.passenger?.email || b.passenger?.phone}</div>
                        <div className="text-[10px] text-textMuted font-mono mt-0.5">ID: {b._id.slice(-6)}</div>
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="font-bold text-textMain flex items-center space-x-1">
                          <MapPin className="w-3.5 h-3.5 text-forest shrink-0" />
                          <span>{b.ride?.origin?.name || 'Origin'}</span>
                          <span className="text-textMuted font-normal">→</span>
                          <span>{b.ride?.destination?.name || 'Destination'}</span>
                        </div>
                        <div className="text-[11px] text-textMuted">
                          Driver: {b.ride?.driver?.name || 'Operator'}
                        </div>
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="font-bold text-textMain">
                          {b.requestedSeats} {b.requestedSeats === 1 ? 'seat' : 'seats'}
                        </div>
                        <div className="text-[11px] text-forest font-semibold">
                          ₹{b.totalContribution} total (₹{b.contributionPerSeat}/seat)
                        </div>
                      </td>

                      <td className="py-3.5 px-4">
                        <span
                          className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                            b.status === 'accepted'
                              ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                              : b.status === 'completed'
                              ? 'bg-blue-50 text-blue-800 border border-blue-200'
                              : b.status === 'pending'
                              ? 'bg-amber-50 text-amber-800 border border-amber-200'
                              : 'bg-rose-50 text-rose-800 border border-rose-200'
                          }`}
                        >
                          {(b.status || 'pending').toUpperCase()}
                        </span>
                      </td>

                      <td className="py-3.5 px-4">
                        <span
                          className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                            b.paymentStatus === 'paid'
                              ? 'bg-emerald-100 text-emerald-800'
                              : b.paymentStatus === 'escrow_released'
                              ? 'bg-teal-100 text-teal-800'
                              : b.paymentStatus === 'refunded'
                              ? 'bg-purple-100 text-purple-800'
                              : 'bg-amber-100 text-amber-800'
                          }`}
                        >
                          {(b.paymentStatus || 'pending').replace('_', ' ')}
                        </span>
                      </td>

                      <td className="py-3.5 px-4 text-right">
                        <button
                          onClick={() => setSelectedBooking(b)}
                          className="px-3 py-1.5 bg-forest-light text-forest hover:bg-forest hover:text-white rounded-lg font-bold text-xs transition-colors cursor-pointer"
                        >
                          Inspect
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

      {/* Inspect Booking Detail Modal */}
      {selectedBooking && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-xl border border-surface-subtle space-y-5">
            <div className="flex items-start justify-between">
              <div>
                <span className="text-xs font-bold text-forest uppercase tracking-wider flex items-center space-x-1">
                  <Bookmark className="w-3.5 h-3.5" />
                  <span>Reservation Audit Record</span>
                </span>
                <h3 className="text-lg font-extrabold text-textMain mt-1">
                  Booking #{selectedBooking._id.slice(-8)}
                </h3>
              </div>
              <button
                onClick={() => setSelectedBooking(null)}
                className="p-1 rounded-lg text-textMuted hover:bg-surface cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-2.5 bg-surface p-4 rounded-2xl border border-surface-subtle text-xs">
              <div className="flex justify-between py-1 border-b border-surface-subtle">
                <span className="text-textMuted">Passenger Name:</span>
                <span className="font-bold text-textMain">{selectedBooking.passenger?.name}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-surface-subtle">
                <span className="text-textMuted">Contact Phone:</span>
                <span className="font-mono text-textMain">{selectedBooking.passenger?.phone || 'N/A'}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-surface-subtle">
                <span className="text-textMuted">Pickup Point:</span>
                <span className="font-medium text-textMain">{selectedBooking.pickup?.name || selectedBooking.ride?.origin?.name}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-surface-subtle">
                <span className="text-textMuted">Drop Point:</span>
                <span className="font-medium text-textMain">{selectedBooking.drop?.name || selectedBooking.ride?.destination?.name}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-surface-subtle">
                <span className="text-textMuted">Seats Reserved:</span>
                <span className="font-bold text-textMain">{selectedBooking.requestedSeats} seats</span>
              </div>
              <div className="flex justify-between py-1 border-b border-surface-subtle">
                <span className="text-textMuted">Contribution Amount:</span>
                <span className="font-bold text-forest">₹{selectedBooking.totalContribution} (Non-commercial fuel share)</span>
              </div>
              <div className="flex justify-between py-1 border-b border-surface-subtle">
                <span className="text-textMuted">Payment Escrow:</span>
                <span className="font-bold text-textMain capitalize">
                  {(selectedBooking.paymentStatus || 'pending').replace('_', ' ')}
                </span>
              </div>
              <div className="flex justify-between py-1">
                <span className="text-textMuted">Booked On:</span>
                <span className="text-textMuted">{new Date(selectedBooking.createdAt).toLocaleString()}</span>
              </div>
            </div>

            {actionFeedback && (
              <div className="p-3 bg-emerald-50 rounded-xl border border-emerald-200 text-xs text-emerald-800 font-bold">
                {actionFeedback}
              </div>
            )}

            {selectedBooking.passengerNote && (
              <div className="p-3 bg-amber-50 rounded-xl border border-amber-200 text-xs">
                <span className="font-bold text-amber-900 block mb-0.5">Passenger Note:</span>
                <p className="text-amber-800">{selectedBooking.passengerNote}</p>
              </div>
            )}

            {/* Dispute Resolution: Force Refund */}
            {selectedBooking.paymentStatus !== 'refunded' && (
              <div className="p-3.5 bg-rose-50 rounded-2xl border border-rose-200 space-y-2.5">
                <div className="text-xs font-bold text-rose-900 flex items-center justify-between">
                  <span>Dispute Resolution: Force Refund</span>
                  <span className="text-[10px] text-rose-700 font-normal">SuperAdmin & Safety Officer</span>
                </div>
                <input
                  type="text"
                  placeholder="Mandatory dispute justification reason..."
                  value={refundReason}
                  onChange={(e) => setRefundReason(e.target.value)}
                  className="w-full px-3 py-2 text-xs bg-white rounded-xl border border-rose-200 focus:outline-none focus:ring-1 focus:ring-rose-500 text-textMain"
                />
                <button
                  type="button"
                  disabled={refundLoading}
                  onClick={handleForceRefund}
                  className="w-full py-2 bg-rose-600 hover:bg-rose-700 disabled:opacity-50 text-white font-bold text-xs rounded-xl transition-colors cursor-pointer"
                >
                  {refundLoading ? 'Processing Refund...' : 'Authorize Force Refund to Passenger'}
                </button>
              </div>
            )}

            <button
              onClick={() => {
                setSelectedBooking(null);
                setActionFeedback(null);
                setRefundReason('');
              }}
              className="w-full py-2.5 bg-forest hover:bg-forest-dark text-white font-bold text-xs rounded-xl transition-colors cursor-pointer"
            >
              Close Investigation
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
