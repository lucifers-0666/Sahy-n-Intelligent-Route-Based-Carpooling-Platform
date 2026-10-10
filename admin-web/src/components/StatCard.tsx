import React from 'react';
import { LucideIcon } from 'lucide-react';

interface StatCardProps {
  title: string;
  value: string | number;
  subtitle: string;
  icon: LucideIcon;
  iconBgColor?: string;
  iconColor?: string;
  trend?: string;
  trendPositive?: boolean;
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
}) => {
  return (
    <div className="bg-white rounded-2xl p-5 border border-surface-subtle shadow-xs hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between">
        <div>
          <span className="text-xs font-bold text-textMuted uppercase tracking-wider block">
            {title}
          </span>
          <div className="text-2xl font-extrabold text-textMain mt-1 tracking-tight">
            {value}
          </div>
        </div>

        <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${iconBgColor}`}>
          <Icon className={`w-5 h-5 ${iconColor}`} />
        </div>
      </div>

      <div className="mt-4 flex items-center justify-between text-xs pt-3 border-t border-gray-100">
        <span className="text-textMuted font-medium">{subtitle}</span>
        {trend && (
          <span
            className={`font-semibold px-2 py-0.5 rounded-full text-[11px] ${
              trendPositive
                ? 'bg-emerald-50 text-emerald-700'
                : 'bg-rose-50 text-rose-700'
            }`}
          >
            {trend}
          </span>
        )}
      </div>
    </div>
  );
};
