import React from 'react';

export interface SegmentItem {
  label: string;
  count: number;
  color: string;
  textColor?: string;
}

interface CorridorDistributionBarProps {
  segments: SegmentItem[];
  totalLabel?: string;
}

export const CorridorDistributionBar: React.FC<CorridorDistributionBarProps> = ({
  segments,
  totalLabel,
}) => {
  const total = segments.reduce((sum, s) => sum + s.count, 0) || 1;

  return (
    <div className="w-full space-y-3 select-none">
      {/* Segmented Bar */}
      <div className="h-3.5 w-full bg-surface rounded-full overflow-hidden flex p-0.5 border border-surface-subtle shadow-inner gap-0.5">
        {segments.map((seg, i) => {
          const pct = Math.max(seg.count > 0 ? 3 : 0, (seg.count / total) * 100);
          if (seg.count === 0) return null;
          return (
            <div
              key={i}
              className="h-full rounded-full transition-all duration-700 hover:brightness-110 cursor-pointer relative group"
              style={{
                width: `${pct}%`,
                backgroundColor: seg.color,
              }}
              title={`${seg.label}: ${seg.count} (${Math.round((seg.count / total) * 100)}%)`}
            />
          );
        })}
      </div>

      {/* Legend & Count Pill Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
        {segments.map((seg, i) => {
          const pct = Math.round((seg.count / total) * 100);
          return (
            <div
              key={i}
              className="flex items-center justify-between p-2.5 rounded-xl bg-surface/50 border border-surface-subtle hover:bg-white hover:shadow-xs transition-all"
            >
              <div className="flex items-center space-x-2">
                <span
                  className="w-2.5 h-2.5 rounded-full shrink-0 shadow-2xs"
                  style={{ backgroundColor: seg.color }}
                />
                <span className="text-xs font-semibold text-textMain truncate">{seg.label}</span>
              </div>
              <div className="flex items-baseline space-x-1.5 shrink-0 pl-1 font-mono">
                <span className="text-xs font-bold text-textMain">{seg.count}</span>
                <span className="text-[10px] text-textMuted font-medium">{pct}%</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

