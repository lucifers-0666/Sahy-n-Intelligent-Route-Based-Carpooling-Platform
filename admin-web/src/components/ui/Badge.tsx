import React from 'react';

export type BadgeVariant =
  | 'emerald'
  | 'rose'
  | 'amber'
  | 'blue'
  | 'purple'
  | 'gray'
  | 'gold';

interface BadgeProps {
  children: React.ReactNode;
  variant?: BadgeVariant;
  size?: 'sm' | 'md';
  dot?: boolean;
  className?: string;
}

export const Badge: React.FC<BadgeProps> = ({
  children,
  variant = 'gray',
  size = 'md',
  dot = false,
  className = '',
}) => {
  const variantStyles: Record<BadgeVariant, { container: string; dot: string }> = {
    emerald: {
      container: 'bg-emerald-50 text-emerald-800 border-emerald-200',
      dot: 'bg-emerald-500',
    },
    rose: {
      container: 'bg-rose-50 text-rose-800 border-rose-200',
      dot: 'bg-rose-500',
    },
    amber: {
      container: 'bg-amber-50 text-amber-800 border-amber-200',
      dot: 'bg-amber-500',
    },
    blue: {
      container: 'bg-blue-50 text-blue-800 border-blue-200',
      dot: 'bg-blue-500',
    },
    purple: {
      container: 'bg-purple-50 text-purple-800 border-purple-200',
      dot: 'bg-purple-500',
    },
    gray: {
      container: 'bg-surface text-textMuted border-surface-subtle',
      dot: 'bg-textLight',
    },
    gold: {
      container: 'bg-amber-50/70 text-amber-900 border-amber-300',
      dot: 'bg-amber-600',
    },
  };

  const sizeStyles = {
    sm: 'text-[10px] px-2 py-0.5',
    md: 'text-[11px] px-2.5 py-0.5',
  }[size];

  const current = variantStyles[variant];

  return (
    <span
      className={`inline-flex items-center space-x-1.5 font-bold uppercase tracking-wider rounded-full border ${current.container} ${sizeStyles} ${className}`}
    >
      {dot && <span className={`w-1.5 h-1.5 rounded-full ${current.dot}`} />}
      <span>{children}</span>
    </span>
  );
};
