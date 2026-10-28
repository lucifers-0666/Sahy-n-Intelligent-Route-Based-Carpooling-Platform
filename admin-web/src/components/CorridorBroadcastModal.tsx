import React, { useState } from 'react';
import { adminApi } from '../services/api';
import {
  AlertTriangle,
  Radio,
  Send,
  X,
  ShieldAlert,
  CheckCircle2,
  Bell,
  Users,
  Car,
} from 'lucide-react';

interface CorridorBroadcastModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
}

export const CorridorBroadcastModal: React.FC<CorridorBroadcastModalProps> = ({
  isOpen,
  onClose,
  onSuccess,
}) => {
  const [corridor, setCorridor] = useState('All Corridors');
  const [severity, setSeverity] = useState<'info' | 'warning' | 'emergency'>('warning');
  const [targetAudience, setTargetAudience] = useState<'all' | 'drivers'>('all');
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !message.trim()) {
      setError('Please provide both an alert title and a descriptive message.');
      return;
    }

    setSubmitting(true);
    setError(null);
    setResult(null);

    try {
      const res = await adminApi.broadcastCorridorAlert({
        corridor,
        severity,
        targetAudience,
        title: title.trim(),
        message: message.trim(),
      });

      setResult(res.message || 'Alert successfully broadcast to corridor users.');
      if (onSuccess) onSuccess();
      setTimeout(() => {
        onClose();
        setTitle('');
        setMessage('');
        setResult(null);
      }, 2000);
    } catch (err: any) {
      setError(err.message || 'Failed to dispatch corridor emergency broadcast.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs animate-fade-in">
      <div className="bg-white rounded-3xl max-w-lg w-full shadow-2xl border border-surface-subtle overflow-hidden">
        {/* Header */}
        <div className="bg-gradient-to-r from-forest-dark to-forest text-white p-6 relative">
          <button
            onClick={onClose}
            className="absolute top-5 right-5 p-1 rounded-full text-white/80 hover:text-white hover:bg-white/10 transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
          <div className="flex items-center space-x-2 text-forest-mint text-xs font-bold uppercase tracking-widest mb-1">
            <Radio className="w-4 h-4 animate-pulse" />
            <span>Emergency Telemetry Dispatch</span>
          </div>
          <h2 className="text-xl font-extrabold tracking-tight">Corridor Safety Broadcast</h2>
          <p className="text-xs text-white/80 mt-1">
            Publish real-time safety warnings, traffic disruptions, or weather hazards directly to corridor users.
          </p>
        </div>

        {/* Content Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4 text-xs">
          {error && (
            <div className="p-3 bg-rose-50 border border-rose-200 text-rose-800 rounded-xl flex items-center space-x-2">
              <AlertTriangle className="w-4 h-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {result && (
            <div className="p-3 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-xl flex items-center space-x-2">
              <CheckCircle2 className="w-4 h-4 shrink-0" />
              <span>{result}</span>
            </div>
          )}

          {/* Corridor Selection */}
          <div>
            <label className="block text-[11px] font-bold text-textMain uppercase mb-1">
              Target Highway Corridor
            </label>
            <select
              value={corridor}
              onChange={(e) => setCorridor(e.target.value)}
              className="w-full bg-surface border border-surface-subtle rounded-xl p-2.5 text-xs text-textMain focus:outline-none focus:border-forest"
            >
              <option value="All Corridors">All Intercity Corridors (Statewide Gujarat)</option>
              <option value="Ahmedabad - Vadodara Expressway (NE1)">Ahmedabad - Vadodara Expressway (NE1)</option>
              <option value="Surat - Mumbai Corridor (NH48)">Surat - Mumbai Corridor (NH48)</option>
              <option value="Gandhinagar - Ahmedabad Metro Corridor">Gandhinagar - Ahmedabad Metro Corridor</option>
              <option value="Rajkot - Ahmedabad Highway (NH47)">Rajkot - Ahmedabad Highway (NH47)</option>
            </select>
          </div>

          {/* Severity & Audience Grid */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-[11px] font-bold text-textMain uppercase mb-1">
                Alert Severity Level
              </label>
              <select
                value={severity}
                onChange={(e) => setSeverity(e.target.value as any)}
                className="w-full bg-surface border border-surface-subtle rounded-xl p-2.5 text-xs text-textMain focus:outline-none focus:border-forest"
              >
                <option value="info">Informational Notice</option>
                <option value="warning">Road / Weather Caution</option>
                <option value="emergency">Critical Safety Hazard</option>
              </select>
            </div>

            <div>
              <label className="block text-[11px] font-bold text-textMain uppercase mb-1">
                Target Audience
              </label>
              <select
                value={targetAudience}
                onChange={(e) => setTargetAudience(e.target.value as any)}
                className="w-full bg-surface border border-surface-subtle rounded-xl p-2.5 text-xs text-textMain focus:outline-none focus:border-forest"
              >
                <option value="all">All Active Corridor Members</option>
                <option value="drivers">Active Drivers Only</option>
              </select>
            </div>
          </div>

          {/* Title */}
          <div>
            <label className="block text-[11px] font-bold text-textMain uppercase mb-1">
              Broadcast Title
            </label>
            <input
              type="text"
              placeholder="e.g. Heavy Rain & Reduced Visibility on NE1 Expressway"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              maxLength={80}
              className="w-full bg-surface border border-surface-subtle rounded-xl p-2.5 text-xs text-textMain focus:outline-none focus:border-forest"
            />
          </div>

          {/* Message */}
          <div>
            <label className="block text-[11px] font-bold text-textMain uppercase mb-1">
              Detailed Alert Instructions
            </label>
            <textarea
              rows={3}
              placeholder="Provide exact corridor advisory, expected speed limits, alternate routes, or emergency contacts..."
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              className="w-full bg-surface border border-surface-subtle rounded-xl p-2.5 text-xs text-textMain focus:outline-none focus:border-forest"
            />
          </div>

          {/* Action Footer */}
          <div className="pt-2 flex items-center justify-end space-x-2">
            <button
              type="button"
              onClick={onClose}
              disabled={submitting}
              className="px-4 py-2 bg-surface text-textMuted hover:text-textMain font-semibold rounded-xl text-xs transition-colors cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={submitting}
              className="px-5 py-2 bg-forest hover:bg-forest-dark text-white font-bold rounded-xl text-xs transition-colors cursor-pointer flex items-center space-x-1.5 shadow-sm disabled:opacity-50"
            >
              <Send className="w-3.5 h-3.5" />
              <span>{submitting ? 'Dispatching...' : 'Dispatch Corridor Broadcast'}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
