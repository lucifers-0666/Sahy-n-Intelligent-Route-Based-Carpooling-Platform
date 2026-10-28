import React from 'react';

interface RadialProgressRingProps {
  progress: number; // 0 to 100
  size?: number;
  strokeWidth?: number;
  color?: string;
  gradientTo?: string;
  backgroundColor?: string;
  label?: string;
  sublabel?: string;
  showPercentage?: boolean;
}

export const RadialProgressRing: React.FC<RadialProgressRingProps> = ({
  progress,
  size = 110,
  strokeWidth = 9,
  color = '#0B5D4B',
  gradientTo = '#3DDC97',
  backgroundColor = '#E8F0EC',
  label,
  sublabel,
  showPercentage = true,
}) => {
  const gradientId = React.useId();
  const radius = (size - strokeWidth) / 2;
  const circumference = radius * 2 * Math.PI;
  const clampedProgress = Math.min(100, Math.max(0, progress));
  const strokeDashoffset = circumference - (clampedProgress / 100) * circumference;

  return (
    <div className="flex flex-col items-center justify-center relative select-none">
      <div className="relative" style={{ width: size, height: size }}>
        <svg width={size} height={size} className="transform -rotate-90">
          <defs>
            <linearGradient id={gradientId} x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor={color} />
              <stop offset="100%" stopColor={gradientTo} />
            </linearGradient>
            <filter id={`glow-${gradientId}`} x="-20%" y="-20%" width="140%" height="140%">
              <feDropShadow dx="0" dy="2" stdDeviation="3" floodColor={gradientTo} floodOpacity="0.25" />
            </filter>
          </defs>

          {/* Background Track */}
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke={backgroundColor}
            strokeWidth={strokeWidth}
            fill="transparent"
          />

          {/* Foreground Progress Ring with Glow */}
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke={`url(#${gradientId})`}
            strokeWidth={strokeWidth}
            fill="transparent"
            strokeDasharray={circumference}
            strokeDashoffset={strokeDashoffset}
            strokeLinecap="round"
            filter={`url(#glow-${gradientId})`}
            className="transition-all duration-1000 ease-out"
          />
        </svg>

        {/* Center Text */}
        <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
          {showPercentage && (
            <span className="text-xl font-extrabold text-textMain tracking-tight">
              {Math.round(clampedProgress)}%
            </span>
          )}
          {sublabel && (
            <span className="text-[10px] font-bold text-textMuted uppercase tracking-wider mt-0.5">
              {sublabel}
            </span>
          )}
        </div>
      </div>

      {label && (
        <span className="text-xs font-semibold text-textMain mt-2 text-center">
          {label}
        </span>
      )}
    </div>
  );
};

