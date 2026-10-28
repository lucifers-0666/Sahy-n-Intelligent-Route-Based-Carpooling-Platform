import React from 'react';

interface SparklineChartProps {
  data?: number[];
  color?: string;
  fillColor?: string;
  width?: number;
  height?: number;
  isPositive?: boolean;
}

export const SparklineChart: React.FC<SparklineChartProps> = ({
  data = [12, 18, 15, 24, 28, 22, 35, 30, 42],
  color = '#0B5D4B',
  fillColor,
  width = 88,
  height = 30,
  isPositive = true,
}) => {
  const strokeColor = isPositive ? '#059669' : '#DC2626';
  const resolvedColor = color || strokeColor;
  const gradientId = React.useId();

  if (!data || data.length < 2) {
    return null;
  }

  const min = Math.min(...data);
  const max = Math.max(...data);
  const range = max - min || 1;

  const padding = 2;
  const usableWidth = width - padding * 2;
  const usableHeight = height - padding * 2;

  const points = data.map((val, idx) => {
    const x = padding + (idx / (data.length - 1)) * usableWidth;
    const y = padding + usableHeight - ((val - min) / range) * usableHeight;
    return { x, y };
  });

  // Construct smooth bezier curve path
  let pathD = `M ${points[0].x} ${points[0].y}`;
  for (let i = 0; i < points.length - 1; i++) {
    const p0 = points[i];
    const p1 = points[i + 1];
    const cpX1 = p0.x + (p1.x - p0.x) / 2;
    const cpY1 = p0.y;
    const cpX2 = p0.x + (p1.x - p0.x) / 2;
    const cpY2 = p1.y;
    pathD += ` C ${cpX1} ${cpY1}, ${cpX2} ${cpY2}, ${p1.x} ${p1.y}`;
  }

  const fillD = `${pathD} L ${points[points.length - 1].x} ${height} L ${points[0].x} ${height} Z`;

  return (
    <svg width={width} height={height} className="overflow-visible select-none shrink-0">
      <defs>
        <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={fillColor || resolvedColor} stopOpacity={0.28} />
          <stop offset="100%" stopColor={fillColor || resolvedColor} stopOpacity={0.0} />
        </linearGradient>
      </defs>
      <path d={fillD} fill={`url(#${gradientId})`} />
      <path
        d={pathD}
        fill="none"
        stroke={resolvedColor}
        strokeWidth={1.8}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      {/* End point pulse */}
      <circle
        cx={points[points.length - 1].x}
        cy={points[points.length - 1].y}
        r={2.5}
        fill={resolvedColor}
      />
    </svg>
  );
};

