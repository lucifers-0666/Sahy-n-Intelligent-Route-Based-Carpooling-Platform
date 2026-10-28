import React from 'react';
import { LucideIcon, ArrowUpRight, TrendingUp, TrendingDown } from 'lucide-react';
import { SparklineChart } from './charts/SparklineChart';

interface StatCardProps {
  title: string;
  value: string | number;
  subtitle: string;
  icon: LucideIcon;
  iconBgColor?: string;
  iconColor?: string;
  trend?: string;
  trendPositive?: boolean;
  trendPercentage?: string;
  sparklineData?: number[];
  onClick?: () => void;
  clickableHint?: string;
}

export const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  subtitle,
  icon: Icon,
  iconBgColor = 'bg-forest/10',
  iconColor = 'text-forest',
  trend,
  trendPositive = true,
  trendPercentage,
  sparklineData,
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
      className={`card relative p-5 bg-white rounded-2xl border border-surface-subtle transition-all duration-300 group overflow-hidden ${
        isClickable
          ? 'cursor-pointer hover:-translate-y-1 hover:border-forest-mint hover:shadow-glass-hover'
          : 'hover:shadow-card'
      }`}
    >
      {/* Ambient background hover glow */}
      <div className="absolute top-0 right-0 w-32 h-32 bg-forest-mint/10 rounded-full blur-2xl -mr-10 -mt-10 opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none" />

      <div className="flex items-start justify-between relative z-10">
        <div className="flex-1 pr-2">
          <div className="flex items-center space-x-1.5">
            <span className="text-[11px] font-bold text-textMuted uppercase tracking-wider block">
              {title}
            </span>
            {isClickable && (
              <ArrowUpRight className="w-3.5 h-3.5 text-textLight group-hover:text-forest group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-all" />
            )}
          </div>
          <div className="text-2xl sm:text-3xl font-extrabold text-textMain mt-1.5 tracking-tight font-sans">
            {value}
          </div>
        </div>

        <div
          className={`w-11 h-11 rounded-xl flex items-center justify-center shrink-0 transition-transform duration-300 group-hover:scale-110 shadow-xs ${iconBgColor}`}
        >
          <Icon className={`w-5 h-5 ${iconColor}`} />
        </div>
      </div>

      {/* Middle: Sparkline Chart if available */}
      {sparklineData && sparklineData.length > 1 && (
        <div className="mt-3 flex items-center justify-between">
          <div className="text-[11px] font-semibold text-textMuted">7D Velocity</div>
          <SparklineChart
            data={sparklineData}
            isPositive={trendPositive}
            width={96}
            height={28}
          />
        </div>
      )}

      {/* Footer / Subtitle / Trend */}
      <div className="mt-4 flex items-center justify-between text-xs pt-3 border-t border-surface-subtle/80 relative z-10">
        <span className="text-textMuted font-medium truncate pr-2 text-[11px]">
          {subtitle}
        </span>
        {(trend || trendPercentage) && (
          <span
            className={`inline-flex items-center space-x-1 font-bold px-2 py-0.5 rounded-full text-[10px] tracking-wide shrink-0 ${
              trendPositive
                ? 'bg-emerald-50 text-emerald-800 border border-emerald-200/80'
                : 'bg-rose-50 text-rose-800 border border-rose-200/80'
            }`}
          >
            {trendPositive ? (
              <TrendingUp className="w-3 h-3 text-emerald-600" />
            ) : (
              <TrendingDown className="w-3 h-3 text-rose-600" />
            )}
            <span>{trendPercentage || trend}</span>
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
