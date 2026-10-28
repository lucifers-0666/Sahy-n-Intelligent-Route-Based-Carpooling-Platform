import React, { useState, useRef } from 'react';

export interface ChartDataPoint {
  label: string;
  value: number;
  secondaryValue?: number;
  dateStr?: string;
  metadata?: string;
}

interface InteractiveAreaChartProps {
  data: ChartDataPoint[];
  title?: string;
  subtitle?: string;
  currencyPrefix?: string;
  unitSuffix?: string;
  height?: number;
  primaryColor?: string;
  gradientToColor?: string;
  showPoints?: boolean;
}

export const InteractiveAreaChart: React.FC<InteractiveAreaChartProps> = ({
  data,
  title,
  subtitle,
  currencyPrefix = '₹',
  unitSuffix = '',
  height = 220,
  primaryColor = '#0B5D4B',
  gradientToColor = '#3DDC97',
  showPoints = true,
}) => {
  const [hoverIndex, setHoverIndex] = useState<number | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const gradientId = React.useId();

  // Normalize data: ensure at least 2 points for a smooth curve
  let normalizedData = [...data];
  if (normalizedData.length === 0) {
    normalizedData = [
      { label: 'Start', value: 0 },
      { label: 'Current', value: 0 },
    ];
  } else if (normalizedData.length === 1) {
    // Graceful baseline expansion so a single data point doesn't look like a solid monolithic block
    const single = normalizedData[0];
    normalizedData = [
      { label: 'Previous', value: Math.round(single.value * 0.4), metadata: 'Baseline' },
      single,
      { label: 'Projected', value: Math.round(single.value * 1.15), metadata: 'Forecast' },
    ];
  }

  const values = normalizedData.map((d) => d.value);
  const maxVal = Math.max(...values, 100);
  const minVal = Math.min(...values, 0);
  const range = maxVal - minVal || 1;

  // SVG viewBox coordinates
  const svgWidth = 700;
  const svgHeight = height;
  const paddingLeft = 20;
  const paddingRight = 20;
  const paddingTop = 25;
  const paddingBottom = 35;

  const usableWidth = svgWidth - paddingLeft - paddingRight;
  const usableHeight = svgHeight - paddingTop - paddingBottom;

  const points = normalizedData.map((item, idx) => {
    const x = paddingLeft + (idx / (normalizedData.length - 1)) * usableWidth;
    const y = paddingTop + usableHeight - ((item.value - minVal) / range) * usableHeight;
    return { x, y, item };
  });

  // Construct smooth bezier curve path
  let pathD = `M ${points[0].x} ${points[0].y}`;
  for (let i = 0; i < points.length - 1; i++) {
    const p0 = points[i];
    const p1 = points[i + 1];
    const cpX1 = p0.x + (p1.x - p0.x) * 0.45;
    const cpY1 = p0.y;
    const cpX2 = p1.x - (p1.x - p0.x) * 0.45;
    const cpY2 = p1.y;
    pathD += ` C ${cpX1} ${cpY1}, ${cpX2} ${cpY2}, ${p1.x} ${p1.y}`;
  }

  const fillD = `${pathD} L ${points[points.length - 1].x} ${svgHeight - paddingBottom} L ${points[0].x} ${svgHeight - paddingBottom} Z`;

  const activePoint = hoverIndex !== null ? points[hoverIndex] : points[points.length - 1];

  const handleMouseMove = (e: React.MouseEvent<SVGSVGElement>) => {
    if (!containerRef.current) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const mouseX = e.clientX - rect.left;
    const pct = Math.max(0, Math.min(1, (mouseX - paddingLeft) / (rect.width - paddingLeft - paddingRight)));
    const nearestIdx = Math.round(pct * (points.length - 1));
    setHoverIndex(nearestIdx);
  };

  const handleMouseLeave = () => {
    setHoverIndex(null);
  };

  return (
    <div ref={containerRef} className="w-full relative select-none">
      {/* Chart Header */}
      {(title || subtitle) && (
        <div className="flex items-center justify-between mb-3 px-1">
          <div>
            {title && <h3 className="text-sm font-bold text-textMain">{title}</h3>}
            {subtitle && <p className="text-xs text-textMuted mt-0.5">{subtitle}</p>}
          </div>
          {activePoint && (
            <div className="text-right">
              <div className="text-base font-extrabold text-forest font-mono tracking-tight">
                {currencyPrefix}
                {activePoint.item.value.toLocaleString('en-IN')}
                {unitSuffix}
              </div>
              <div className="text-[11px] text-textMuted font-medium">
                {activePoint.item.label} {activePoint.item.metadata ? `· ${activePoint.item.metadata}` : ''}
              </div>
            </div>
          )}
        </div>
      )}

      {/* SVG Container */}
      <div className="relative rounded-2xl overflow-hidden bg-gradient-to-b from-surface/40 via-surface/10 to-transparent p-1">
        <svg
          viewBox={`0 0 ${svgWidth} ${svgHeight}`}
          className="w-full h-auto overflow-visible cursor-crosshair"
          onMouseMove={handleMouseMove}
          onMouseLeave={handleMouseLeave}
        >
          <defs>
            <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={primaryColor} stopOpacity={0.32} />
              <stop offset="60%" stopColor={gradientToColor} stopOpacity={0.08} />
              <stop offset="100%" stopColor={gradientToColor} stopOpacity={0.0} />
            </linearGradient>

            <filter id={`glow-${gradientId}`} x="-20%" y="-20%" width="140%" height="140%">
              <feDropShadow dx="0" dy="4" stdDeviation="6" floodColor={primaryColor} floodOpacity="0.25" />
            </filter>
          </defs>

          {/* Horizontal Gridlines */}
          {[0, 0.33, 0.66, 1].map((ratio, i) => {
            const y = paddingTop + usableHeight * (1 - ratio);
            const val = Math.round(minVal + range * ratio);
            return (
              <g key={i}>
                <line
                  x1={paddingLeft}
                  y1={y}
                  x2={svgWidth - paddingRight}
                  y2={y}
                  stroke="#E8F0EC"
                  strokeDasharray="4 4"
                  strokeWidth="1"
                />
                <text
                  x={svgWidth - paddingRight}
                  y={y - 4}
                  textAnchor="end"
                  fill="#9AADA7"
                  fontSize="10"
                  fontFamily="JetBrains Mono, monospace"
                  fontWeight="600"
                >
                  {currencyPrefix}{val.toLocaleString('en-IN')}
                </text>
              </g>
            );
          })}

          {/* Area Fill */}
          <path d={fillD} fill={`url(#${gradientId})`} />

          {/* Line Stroke with Glow */}
          <path
            d={pathD}
            fill="none"
            stroke={primaryColor}
            strokeWidth="3"
            strokeLinecap="round"
            strokeLinejoin="round"
            filter={`url(#glow-${gradientId})`}
          />

          {/* Vertical Tracking Guideline */}
          {activePoint && hoverIndex !== null && (
            <line
              x1={activePoint.x}
              y1={paddingTop}
              x2={activePoint.x}
              y2={svgHeight - paddingBottom}
              stroke={primaryColor}
              strokeWidth="1.5"
              strokeDasharray="3 3"
              opacity="0.8"
            />
          )}

          {/* Interactive Data Points */}
          {points.map((pt, i) => {
            const isHovered = hoverIndex === i;
            return (
              <g key={i} className="transition-all duration-150">
                {/* Outer ring */}
                <circle
                  cx={pt.x}
                  cy={pt.y}
                  r={isHovered ? 6 : (showPoints ? 4 : 0)}
                  fill="#FFFFFF"
                  stroke={isHovered ? gradientToColor : primaryColor}
                  strokeWidth={isHovered ? 2.5 : 2}
                  className="transition-all"
                />
                {/* Center dot */}
                {isHovered && (
                  <circle
                    cx={pt.x}
                    cy={pt.y}
                    r={3}
                    fill={primaryColor}
                  />
                )}
                {/* X Axis Label */}
                <text
                  x={pt.x}
                  y={svgHeight - 12}
                  textAnchor="middle"
                  fill={isHovered ? primaryColor : '#6B7F78'}
                  fontSize="11"
                  fontWeight={isHovered ? '700' : '500'}
                  className="transition-colors"
                >
                  {pt.item.label}
                </text>
              </g>
            );
          })}
        </svg>

        {/* Hover Tooltip Overlay */}
        {hoverIndex !== null && activePoint && (
          <div
            className="absolute pointer-events-none transform -translate-x-1/2 -translate-y-full transition-all duration-75 z-20"
            style={{
              left: `${(activePoint.x / svgWidth) * 100}%`,
              top: `${(activePoint.y / svgHeight) * 100}%`,
              marginTop: '-12px',
            }}
          >
            <div className="glass-card px-3 py-2 rounded-xl shadow-glass border border-forest-mint/50 flex flex-col items-center whitespace-nowrap">
              <span className="text-[10px] font-bold text-textMuted uppercase tracking-wider">
                {activePoint.item.label}
              </span>
              <span className="text-xs font-extrabold text-forest font-mono mt-0.5">
                {currencyPrefix}{activePoint.item.value.toLocaleString('en-IN')}{unitSuffix}
              </span>
              {activePoint.item.metadata && (
                <span className="text-[9px] text-textLight font-medium">
                  {activePoint.item.metadata}
                </span>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

