import React, { useState } from 'react';
import { UserItem } from '../types/admin';
import { UnmaskModal } from './UnmaskModal';
import {
  X,
  ShieldCheck,
  ShieldAlert,
  FileText,
  Check,
  ZoomIn,
  ZoomOut,
  RotateCw,
  ExternalLink,
  Car,
  User,
  Phone,
  Mail,
  Calendar,
  AlertTriangle,
  Lock,
  Eye,
} from 'lucide-react';

interface DriverKycDrawerProps {
  user: UserItem | null;
  isOpen: boolean;
  onClose: () => void;
  onApprove: (userId: string) => Promise<void>;
  onReject: (userId: string, reason: string) => Promise<void>;
}

export const DriverKycDrawer: React.FC<DriverKycDrawerProps> = ({
  user,
  isOpen,
  onClose,
  onApprove,
  onReject,
}) => {
  const [rejectReason, setRejectReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  const [activeDocTab, setActiveDocTab] = useState<'license' | 'rc' | 'id'>('license');
  const [zoomLevel, setZoomLevel] = useState(1);
  const [rotation, setRotation] = useState(0);

  // PII Unmasking state
  const [unmaskOpen, setUnmaskOpen] = useState(false);
  const [unmaskTarget, setUnmaskTarget] = useState<{ id: string; field: string; label: string } | null>(null);
  const [unmaskedValues, setUnmaskedValues] = useState<Record<string, string>>({});

  if (!isOpen || !user) return null;

  const handleApprove = async () => {
    setActionLoading(true);
    try {
      await onApprove(user._id);
      onClose();
    } catch (err: any) {
      alert(`Approval error: ${err.message}`);
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = async () => {
    if (!rejectReason.trim()) {
      alert('Please specify a rejection reason for the applicant.');
      return;
    }
    setActionLoading(true);
    try {
      await onReject(user._id, rejectReason.trim());
      onClose();
    } catch (err: any) {
      alert(`Rejection error: ${err.message}`);
    } finally {
      setActionLoading(false);
    }
  };

  const triggerUnmask = (field: string, label: string) => {
    setUnmaskTarget({ id: user._id, field, label });
    setUnmaskOpen(true);
  };

  const displayedPhone = unmaskedValues[`phone_${user._id}`] || user.phone;
  const displayedEmail = unmaskedValues[`email_${user._id}`] || user.email;
  const displayedLicense = unmaskedValues[`license_${user._id}`] || user.driverProfile?.licenseNumber || 'GJ-01-****-0941';

  // Get active document URL
  const currentDocUrl =
    activeDocTab === 'license'
      ? user.driverProfile?.licenseDocUrl || 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=1200&q=80'
      : activeDocTab === 'rc'
      ? user.driverProfile?.rcDocUrl || 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&w=1200&q=80'
      : user.driverProfile?.idDocUrl || 'https://images.unsplash.com/photo-1584438784894-089d6a62b8fa?auto=format&fit=crop&w=1200&q=80';

  return (
    <div className="fixed inset-0 z-50 overflow-hidden bg-black/60 backdrop-blur-sm animate-fade-in flex justify-end">
      <div className="w-full max-w-5xl bg-surface h-full shadow-2xl flex flex-col border-l border-stone-200 animate-slide-left">
        {/* Header */}
        <div className="bg-white border-b border-stone-200 px-6 py-4 flex items-center justify-between shrink-0">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-forest-light text-forest flex items-center justify-center font-bold">
              {user.name.slice(0, 2).toUpperCase()}
            </div>
            <div>
              <div className="flex items-center space-x-2">
                <h2 className="text-base font-bold text-textMain">{user.name}</h2>
                <span className="badge badge-amber uppercase text-[10px]">
                  {user.driverProfile?.onboardingStatus || 'Pending KYC'}
                </span>
              </div>
              <p className="text-xs text-textMuted">Application ID: {user._id}</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 text-stone-400 hover:text-stone-700 rounded-xl hover:bg-stone-100 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Side-by-Side Body Grid */}
        <div className="flex-1 overflow-hidden grid grid-cols-1 lg:grid-cols-12 divide-y lg:divide-y-0 lg:divide-x divide-stone-200">
          {/* Left Column: Profile & Vehicle Details (5 cols) */}
          <div className="lg:col-span-5 p-6 overflow-y-auto space-y-6 bg-white">
            {/* Identity & Contact with PII Unmasking */}
            <div>
              <h3 className="text-xs font-bold text-textMuted uppercase tracking-wider mb-3">
                Applicant Details
              </h3>
              <div className="space-y-3 bg-stone-50 rounded-2xl p-4 border border-stone-200">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2 text-xs text-textMuted">
                    <Phone className="w-3.5 h-3.5" />
                    <span>Phone Number</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className="text-xs font-mono font-bold text-textMain">{displayedPhone}</span>
                    {!unmaskedValues[`phone_${user._id}`] && (
                      <button
                        onClick={() => triggerUnmask('phone', 'Phone Number')}
                        className="text-[10px] font-bold text-forest hover:underline"
                      >
                        Unmask
                      </button>
                    )}
                  </div>
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2 text-xs text-textMuted">
                    <Mail className="w-3.5 h-3.5" />
                    <span>Email Address</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className="text-xs font-bold text-textMain">{displayedEmail}</span>
                    {!unmaskedValues[`email_${user._id}`] && (
                      <button
                        onClick={() => triggerUnmask('email', 'Email Address')}
                        className="text-[10px] font-bold text-forest hover:underline"
                      >
                        Unmask
                      </button>
                    )}
                  </div>
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2 text-xs text-textMuted">
                    <FileText className="w-3.5 h-3.5" />
                    <span>Driving License</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className="text-xs font-mono font-bold text-forest">{displayedLicense}</span>
                    {!unmaskedValues[`license_${user._id}`] && (
                      <button
                        onClick={() => triggerUnmask('licenseNumber', 'Driving License Number')}
                        className="text-[10px] font-bold text-forest hover:underline"
                      >
                        Unmask
                      </button>
                    )}
                  </div>
                </div>
              </div>
            </div>

            {/* Vehicle & RC Specification */}
            <div>
              <h3 className="text-xs font-bold text-textMuted uppercase tracking-wider mb-3">
                Registered Fleet Asset
              </h3>
              <div className="bg-stone-50 rounded-2xl p-4 border border-stone-200 space-y-3">
                <div className="flex items-center space-x-3">
                  <div className="w-10 h-10 rounded-xl bg-forest/10 text-forest flex items-center justify-center">
                    <Car className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-textMain">
                      {user.vehicle ? `${user.vehicle.make} ${user.vehicle.model}` : 'Honda City ZX (Corridor)'}
                    </h4>
                    <p className="text-xs text-textMuted">
                      {user.vehicle?.registrationNumber || 'GJ-01-AB-1234'} · {user.vehicle?.color || 'Pearl White'}
                    </p>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-2 pt-2 border-t border-stone-200 text-xs">
                  <div>
                    <span className="text-textMuted block text-[11px]">Seat Capacity</span>
                    <span className="font-bold text-textMain">
                      {user.vehicle?.seatCapacity || 4} Passenger Seats
                    </span>
                  </div>
                  <div>
                    <span className="text-textMuted block text-[11px]">Vehicle Type</span>
                    <span className="font-bold text-textMain uppercase">
                      {user.vehicle?.vehicleType || 'Sedan'}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* Rejection Justification Input */}
            <div>
              <label className="block text-xs font-bold text-textMuted uppercase tracking-wider mb-2">
                Rejection Notes (Sent to applicant if rejected)
              </label>
              <textarea
                rows={3}
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                placeholder="e.g. Driving License image is blurred, expiration date mismatch, or vehicle RC plate unreadable..."
                className="w-full px-3.5 py-2.5 rounded-xl border border-stone-200 bg-stone-50 text-xs text-textMain placeholder-stone-400 focus:outline-none focus:ring-2 focus:ring-forest/20 focus:border-forest transition-all resize-none"
              />
            </div>
          </div>

          {/* Right Column: Zoomable High-Res Document Viewer (7 cols) */}
          <div className="lg:col-span-7 flex flex-col bg-stone-900 text-white overflow-hidden">
            {/* Document Switcher & Viewer Toolbar */}
            <div className="px-5 py-3 bg-stone-950 border-b border-stone-800 flex items-center justify-between shrink-0">
              {/* Document Tabs */}
              <div className="flex items-center space-x-1.5">
                <button
                  onClick={() => { setActiveDocTab('license'); setZoomLevel(1); setRotation(0); }}
                  className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                    activeDocTab === 'license' ? 'bg-forest text-white' : 'text-stone-400 hover:text-white'
                  }`}
                >
                  Driving License
                </button>
                <button
                  onClick={() => { setActiveDocTab('rc'); setZoomLevel(1); setRotation(0); }}
                  className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                    activeDocTab === 'rc' ? 'bg-forest text-white' : 'text-stone-400 hover:text-white'
                  }`}
                >
                  Vehicle RC
                </button>
                <button
                  onClick={() => { setActiveDocTab('id'); setZoomLevel(1); setRotation(0); }}
                  className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                    activeDocTab === 'id' ? 'bg-forest text-white' : 'text-stone-400 hover:text-white'
                  }`}
                >
                  Aadhaar / Govt ID
                </button>
              </div>

              {/* Zoom & Rotate Controls */}
              <div className="flex items-center space-x-1">
                <button
                  onClick={() => setZoomLevel((z) => Math.max(z - 0.25, 0.5))}
                  className="p-1.5 rounded-lg text-stone-400 hover:text-white hover:bg-stone-800 transition-colors"
                  title="Zoom Out"
                >
                  <ZoomOut className="w-4 h-4" />
                </button>
                <span className="text-[11px] font-mono text-stone-400 px-1">
                  {Math.round(zoomLevel * 100)}%
                </span>
                <button
                  onClick={() => setZoomLevel((z) => Math.min(z + 0.25, 2.5))}
                  className="p-1.5 rounded-lg text-stone-400 hover:text-white hover:bg-stone-800 transition-colors"
                  title="Zoom In"
                >
                  <ZoomIn className="w-4 h-4" />
                </button>
                <button
                  onClick={() => setRotation((r) => (r + 90) % 360)}
                  className="p-1.5 rounded-lg text-stone-400 hover:text-white hover:bg-stone-800 transition-colors"
                  title="Rotate 90°"
                >
                  <RotateCw className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* Document Canvas */}
            <div className="flex-1 overflow-auto p-6 flex items-center justify-center bg-stone-950/80 relative">
              <div
                className="transition-transform duration-200 origin-center max-w-full max-h-full"
                style={{
                  transform: `scale(${zoomLevel}) rotate(${rotation}deg)`,
                }}
              >
                <img
                  src={currentDocUrl}
                  alt="KYC Document Preview"
                  className="rounded-xl shadow-2xl border border-stone-800 max-h-[420px] object-contain select-none"
                />
              </div>
            </div>

            {/* Inspection Decision Toolbar */}
            <div className="p-4 bg-stone-900 border-t border-stone-800 flex items-center justify-between shrink-0">
              <div className="text-xs text-stone-400 flex items-center space-x-2">
                <ShieldCheck className="w-4 h-4 text-emerald-400" />
                <span>Fail-closed verification audit logged automatically</span>
              </div>

              <div className="flex items-center space-x-3">
                <button
                  onClick={handleReject}
                  disabled={actionLoading}
                  className="px-4 py-2 rounded-xl bg-rose-600/20 hover:bg-rose-600/30 text-rose-400 border border-rose-500/30 text-xs font-bold transition-all disabled:opacity-50"
                >
                  Reject with Reason
                </button>
                <button
                  onClick={handleApprove}
                  disabled={actionLoading}
                  className="px-5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold flex items-center space-x-1.5 transition-all shadow-md disabled:opacity-50"
                >
                  <Check className="w-4 h-4" />
                  <span>Approve Driver Verification</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

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
