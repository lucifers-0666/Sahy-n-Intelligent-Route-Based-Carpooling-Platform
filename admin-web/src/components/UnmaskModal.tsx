import React, { useState } from 'react';
import { adminApi } from '../services/api';
import { ShieldAlert, Lock, Eye, X, AlertTriangle } from 'lucide-react';

interface UnmaskModalProps {
  isOpen: boolean;
  onClose: () => void;
  resourceId: string;
  fieldName: string;
  fieldLabel: string;
  onSuccess: (unmaskedValue: any) => void;
}

export const UnmaskModal: React.FC<UnmaskModalProps> = ({
  isOpen,
  onClose,
  resourceId,
  fieldName,
  fieldLabel,
  onSuccess,
}) => {
  const [reason, setReason] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!reason.trim()) {
      setError('A formal justification reason is required for DPDP / GDPR audit compliance.');
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const res = await adminApi.unmaskPii(resourceId, fieldName, reason.trim());
      onSuccess(res.unmaskedValue);
      onClose();
    } catch (err: any) {
      setError(err.message || 'Failed to unmask personal identifier');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in">
      <div className="bg-white rounded-2xl max-w-md w-full border border-stone-200 shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="bg-stone-900 text-white p-5 flex items-start justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-amber-500/20 text-amber-400 flex items-center justify-center shrink-0">
              <ShieldAlert className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-base font-bold text-white">Unmask Sensitive PII</h3>
              <p className="text-xs text-stone-400 mt-0.5">DPDP 2023 Immutable Audit Access</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-stone-400 hover:text-white p-1 rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div className="bg-amber-50 border border-amber-200 rounded-xl p-3 flex items-start space-x-2.5">
            <AlertTriangle className="w-4 h-4 text-amber-700 shrink-0 mt-0.5" />
            <p className="text-xs text-amber-800 leading-relaxed">
              You are requesting to decrypt and reveal <strong className="font-semibold">{fieldLabel}</strong>.
              This access is permanently attributed to your admin credentials in the central audit ledger.
            </p>
          </div>

          <div>
            <label className="block text-xs font-bold text-stone-700 uppercase tracking-wider mb-1.5">
              Mandatory Justification Reason
            </label>
            <textarea
              required
              rows={3}
              value={reason}
              onChange={(e) => {
                setReason(e.target.value);
                if (error) setError(null);
              }}
              placeholder="e.g. SOS safety emergency review, police contact dispatch, or KYC verification document conflict..."
              className="w-full px-3.5 py-2.5 rounded-xl border border-stone-300 bg-stone-50 text-stone-900 text-sm focus:outline-none focus:ring-2 focus:ring-forest/20 focus:border-forest transition-all resize-none"
            />
          </div>

          {error && (
            <p className="text-xs font-semibold text-rose-600 bg-rose-50 p-2.5 rounded-lg border border-rose-200">
              {error}
            </p>
          )}

          {/* Action CTAs */}
          <div className="flex items-center justify-end space-x-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              disabled={loading}
              className="px-4 py-2 rounded-xl border border-stone-300 text-stone-700 text-xs font-bold hover:bg-stone-50 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading || !reason.trim()}
              className="flex items-center space-x-2 px-5 py-2 rounded-xl bg-forest hover:bg-forest-dark text-white text-xs font-bold transition-all disabled:opacity-50 shadow-sm"
            >
              {loading ? (
                <span>Decrypting...</span>
              ) : (
                <>
                  <Eye className="w-4 h-4" />
                  <span>Authorize & Reveal PII</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
