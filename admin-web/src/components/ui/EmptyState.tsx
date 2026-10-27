import React from 'react';
import { LucideIcon } from 'lucide-react';

interface EmptyStateProps {
  icon: LucideIcon;
  title: string;
  description: string;
  action?: {
    label: string;
    onClick: () => void;
  };
  actionLabel?: string;
  onAction?: () => void;
}

export const EmptyState: React.FC<EmptyStateProps> = ({
  icon: Icon,
  title,
  description,
  action,
  actionLabel,
  onAction,
}) => {
  const hasAction = action || (actionLabel && onAction);
  const clickHandler = action?.onClick || onAction;
  const label = action?.label || actionLabel;

  return (
    <div className="bg-white rounded-2xl p-12 text-center border border-surface-subtle shadow-xs flex flex-col items-center justify-center">
      <div className="w-12 h-12 rounded-2xl bg-forest-light text-forest flex items-center justify-center mb-3">
        <Icon className="w-6 h-6" />
      </div>
      <h3 className="text-sm font-bold text-textMain">{title}</h3>
      <p className="text-xs text-textMuted mt-1 max-w-sm">{description}</p>
      {hasAction && clickHandler && (
        <button
          onClick={clickHandler}
          className="mt-4 px-4 py-2 bg-forest hover:bg-forest-dark text-white font-bold text-xs rounded-xl transition-colors cursor-pointer"
        >
          {label}
        </button>
      )}
    </div>
  );
};
