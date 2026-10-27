import React from 'react';
import { LucideIcon, ArrowUpRight } from 'lucide-react';

interface StatCardProps {
  title: string;
  value: string | number;
  subtitle: string;
  icon: LucideIcon;
  iconBgColor?: string;
  iconColor?: string;
  trend?: string;
  trendPositive?: boolean;
  onClick?: () => void;
  clickableHint?: string;
}

export const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  subtitle,
  icon: Icon,
  iconBgColor = 'bg-forest-light',
  iconColor = 'text-forest',
  trend,
  trendPositive = true,
  onClick,
  clickableHint,
}) => {
  const isClickable = Boolean(onClick);

  return (
    <div
      onClick={onClick}
      role={isClickable ? 'button' : undefined}
      tabIndex={isClickable ? 0 : undefined}
      onKeyDown={(e) => {
        if (isClickable && (e.key === 'Enter' || e.key === ' ')) {
          e.preventDefault();
          onClick?.();
        }
      }}
      className={`bg-white rounded-2xl p-5 border border-surface-subtle shadow-xs transition-all ${
        isClickable
          ? 'cursor-pointer hover:shadow-md hover:border-forest-mint group'
          : ''
      }`}
    >
      <div className="flex items-start justify-between">
        <div>
          <div className="flex items-center space-x-1">
            <span className="text-[11px] font-bold text-textMuted uppercase tracking-wider block">
              {title}
            </span>
            {isClickable && (
              <ArrowUpRight className="w-3.5 h-3.5 text-textLight group-hover:text-forest transition-colors" />
            )}
          </div>
          <div className="text-2xl font-extrabold text-textMain mt-1 tracking-tight">
            {value}
          </div>
        </div>

        <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${iconBgColor}`}>
          <Icon className={`w-5 h-5 ${iconColor}`} />
        </div>
      </div>

      <div className="mt-4 flex items-center justify-between text-xs pt-3 border-t border-surface-subtle">
        <span className="text-textMuted font-medium truncate">{subtitle}</span>
        {trend && (
          <span
            className={`font-bold px-2 py-0.5 rounded-full text-[10px] uppercase tracking-wide shrink-0 ${
              trendPositive
                ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                : 'bg-rose-50 text-rose-800 border border-rose-200'
            }`}
          >
            {trend}
          </span>
        )}
      </div>
      {clickableHint && (
        <div className="mt-1 text-[10px] text-forest font-semibold opacity-0 group-hover:opacity-100 transition-opacity">
          {clickableHint}
        </div>
      )}
    </div>
  );
};
