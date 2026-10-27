import React from 'react';
import { AlertTriangle, X } from 'lucide-react';

interface ConfirmModalProps {
  isOpen: boolean;
  title: string;
  subtitle?: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  variant?: 'danger' | 'primary' | 'warning';
  reasonRequired?: boolean;
  reasonPlaceholder?: string;
  reasonValue?: string;
  onReasonChange?: (val: string) => void;
  isLoading?: boolean;
  onConfirm: () => void;
  onClose: () => void;
}

export const ConfirmModal: React.FC<ConfirmModalProps> = ({
  isOpen,
  title,
  subtitle,
  message,
  confirmLabel = 'Confirm Action',
  cancelLabel = 'Cancel',
  variant = 'primary',
  reasonRequired = false,
  reasonPlaceholder = 'Please state specific reason...',
  reasonValue = '',
  onReasonChange,
  isLoading = false,
  onConfirm,
  onClose,
}) => {
  if (!isOpen) return null;

  const confirmBtnStyles = {
    danger: 'bg-rose-600 hover:bg-rose-700 text-white',
    warning: 'bg-amber-600 hover:bg-amber-700 text-white',
    primary: 'bg-forest hover:bg-forest-dark text-white',
  }[variant];

  const isConfirmDisabled = isLoading || (reasonRequired && !reasonValue.trim());

  return (
    <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4">
      <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-xl border border-surface-subtle space-y-4 animate-in fade-in">
        <div className="flex items-start justify-between">
          <div>
            {variant === 'danger' && (
              <span className="text-[11px] font-bold text-rose-700 uppercase tracking-wider flex items-center space-x-1">
                <AlertTriangle className="w-3.5 h-3.5" />
                <span>Restricted Safety Action</span>
              </span>
            )}
            <h3 className="text-lg font-extrabold text-textMain mt-1">{title}</h3>
            {subtitle && <p className="text-xs text-textMuted mt-0.5">{subtitle}</p>}
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded-lg text-textMuted hover:bg-surface cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-3.5 bg-surface rounded-2xl border border-surface-subtle text-xs text-textMain leading-relaxed">
          {message}
        </div>

        {reasonRequired && (
          <div>
            <label className="block text-xs font-bold text-textMain mb-1">
              Mandatory Justification / Reason:
            </label>
            <textarea
              placeholder={reasonPlaceholder}
              value={reasonValue}
              onChange={(e) => onReasonChange?.(e.target.value)}
              rows={3}
              className="w-full bg-white p-3 text-xs rounded-xl border border-surface-subtle focus:outline-none focus:border-forest text-textMain"
            />
          </div>
        )}

        <div className="flex gap-3 pt-2">
          <button
            type="button"
            onClick={onClose}
            className="flex-1 py-2.5 px-4 rounded-xl border border-surface-subtle text-textMuted font-bold text-xs hover:bg-surface transition-colors cursor-pointer"
          >
            {cancelLabel}
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={isConfirmDisabled}
            className={`flex-1 py-2.5 px-4 rounded-xl font-bold text-xs transition-colors shadow-sm cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed ${confirmBtnStyles}`}
          >
            {isLoading ? 'Processing...' : confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
};
