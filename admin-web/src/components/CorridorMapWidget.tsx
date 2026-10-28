import React, { useState } from 'react';
import {
  Navigation,
  Car,
  Shield,
  Activity,
  CheckCircle2,
  TrendingUp,
  MapPin,
  Compass,
  Radio,
  Zap,
} from 'lucide-react';
import { Badge } from './ui/Badge';

interface CorridorNode {
  id: string;
  name: string;
  code: string;
  x: number;
  y: number;
  activeTrips: number;
  matchScore: number;
  status: 'optimal' | 'moderate' | 'high_demand';
  description: string;
}

const NODES: CorridorNode[] = [
  {
    id: 'gdn',
    name: 'Gandhinagar (InfoCity)',
    code: 'GDN',
    x: 260,
    y: 55,
    activeTrips: 18,
    matchScore: 96,
    status: 'high_demand',
    description: 'Tech park commuter hub with peak morning sharing index',
  },
  {
    id: 'ahm',
    name: 'Ahmedabad (SG Highway Hub)',
    code: 'AHM',
    x: 250,
    y: 130,
    activeTrips: 42,
    matchScore: 94,
    status: 'optimal',
    description: 'Central transit axis connecting Ring Road and expressway feeders',
  },
  {
    id: 'rjk',
    name: 'Rajkot (Ring Road)',
    code: 'RJK',
    x: 90,
    y: 170,
    activeTrips: 14,
    matchScore: 88,
    status: 'moderate',
    description: 'Saurashtra corridor feeder with regular weekend intercity carpools',
  },
  {
    id: 'and',
    name: 'Anand / Nadiad Tollway',
    code: 'AND',
    x: 295,
    y: 195,
    activeTrips: 12,
    matchScore: 92,
    status: 'optimal',
    description: 'Expressway toll station with instant fast-tag & corridor checkpoints',
  },
  {
    id: 'bar',
    name: 'Vadodara (Expressway)',
    code: 'BDQ',
    x: 340,
    y: 245,
    activeTrips: 28,
    matchScore: 94,
    status: 'optimal',
    description: 'NE1 National Expressway artery with highest carpool density',
  },
  {
    id: 'sur',
    name: 'Surat (Ring Road NH48)',
    code: 'ST',
    x: 350,
    y: 350,
    activeTrips: 22,
    matchScore: 91,
    status: 'optimal',
    description: 'Diamond & textile business transit line toward South Gujarat',
  },
];

interface VehicleBreadcrumb {
  id: string;
  driverName: string;
  vehicle: string;
  corridor: string;
  x: number;
  y: number;
  speed: string;
  matchRate: string;
  status: string;
}

const VEHICLES: VehicleBreadcrumb[] = [
  {
    id: 'v1',
    driverName: 'Vikramjit Singh',
    vehicle: 'Hyundai Creta',
    corridor: 'AHM - BDQ Expressway',
    x: 290,
    y: 185,
    speed: '88 km/h',
    matchRate: '98% match',
    status: 'Cruising NE-1',
  },
  {
    id: 'v2',
    driverName: 'Priya Sharma',
    vehicle: 'Tata Nexon EV',
    corridor: 'AHM - GDN Metro Corridor',
    x: 255,
    y: 90,
    speed: '62 km/h',
    matchRate: '95% match',
    status: 'Smooth Traffic',
  },
  {
    id: 'v3',
    driverName: 'Karan Dave',
    vehicle: 'Maruti Brezza',
    corridor: 'BDQ - ST Corridor',
    x: 345,
    y: 295,
    speed: '78 km/h',
    matchRate: '92% match',
    status: 'Approaching Ankleshwar',
  },
  {
    id: 'v4',
    driverName: 'Mehul Shah',
    vehicle: 'Honda City',
    corridor: 'AHM - RJK Highway',
    x: 170,
    y: 150,
    speed: '74 km/h',
    matchRate: '89% match',
    status: 'Limbdi Toll Crossed',
  },
];

export const CorridorMapWidget: React.FC = () => {
  const [selectedNode, setSelectedNode] = useState<CorridorNode>(NODES[1]);
  const [selectedVehicle, setSelectedVehicle] = useState<VehicleBreadcrumb | null>(null);

  return (
    <div className="card p-6 shadow-xs overflow-hidden relative">
      {/* Widget Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-5">
        <div>
          <div className="flex items-center space-x-2">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping" />
            <h2 className="text-sm font-bold text-textMain flex items-center space-x-2">
              <Navigation className="w-4 h-4 text-forest" />
              <span>Interactive Highway Corridor & Live Telemetry Map</span>
            </h2>
          </div>
          <p className="text-xs text-textMuted mt-1">
            Geospatial route network, real-time vehicle breadcrumbs, and corridor match densities across Gujarat.
          </p>
        </div>

        <div className="flex items-center space-x-2 shrink-0">
          <span className="flex items-center space-x-1.5 text-xs text-emerald-800 bg-emerald-50 px-3 py-1 rounded-full border border-emerald-200/80 font-bold">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            <span>OSRM Engine Live</span>
          </span>
          <span className="flex items-center space-x-1.5 text-xs text-textMain bg-surface px-3 py-1 rounded-full border border-surface-subtle font-bold">
            <Car className="w-3.5 h-3.5 text-forest" />
            <span>{VEHICLES.length} Tracked Vehicles</span>
          </span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        {/* Interactive SVG Canvas */}
        <div className="lg:col-span-2 relative bg-gradient-to-br from-surface/80 via-white to-surface rounded-2xl border border-surface-subtle p-4 flex items-center justify-center overflow-hidden shadow-inner">
          {/* Subtle background coordinate grid */}
          <div
            className="absolute inset-0 opacity-[0.03] pointer-events-none"
            style={{
              backgroundImage:
                'radial-gradient(#0B5D4B 1px, transparent 1px), radial-gradient(#0B5D4B 1px, transparent 1px)',
              backgroundSize: '24px 24px',
            }}
          />

          <svg
            viewBox="0 0 450 400"
            className="w-full h-auto max-h-[360px] select-none relative z-10"
          >
            <defs>
              <linearGradient id="corridorGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#0B5D4B" stopOpacity="0.8" />
                <stop offset="50%" stopColor="#10B981" stopOpacity="0.9" />
                <stop offset="100%" stopColor="#084C3A" stopOpacity="0.8" />
              </linearGradient>

              <filter id="corridorGlow" x="-20%" y="-20%" width="140%" height="140%">
                <feDropShadow dx="0" dy="2" stdDeviation="4" floodColor="#3DDC97" floodOpacity="0.4" />
              </filter>
            </defs>

            {/* Highway Route Lines with Outer Glow Track */}
            <g strokeLinecap="round">
              {/* Gandhinagar to Ahmedabad */}
              <line x1="260" y1="55" x2="250" y2="130" stroke="#A7E8D2" strokeWidth="8" opacity="0.3" />
              <line x1="260" y1="55" x2="250" y2="130" stroke="#0B5D4B" strokeWidth="3.5" strokeDasharray="6 3" />

              {/* Ahmedabad to Rajkot */}
              <line x1="250" y1="130" x2="90" y2="170" stroke="#A7E8D2" strokeWidth="7" opacity="0.25" />
              <line x1="250" y1="130" x2="90" y2="170" stroke="#0B5D4B" strokeWidth="3" strokeDasharray="5 3" />

              {/* Ahmedabad to Anand/Nadiad */}
              <line x1="250" y1="130" x2="295" y2="195" stroke="#3DDC97" strokeWidth="9" opacity="0.3" />
              <line x1="250" y1="130" x2="295" y2="195" stroke="#0B5D4B" strokeWidth="4.5" />

              {/* Anand to Vadodara */}
              <line x1="295" y1="195" x2="340" y2="245" stroke="#3DDC97" strokeWidth="9" opacity="0.3" />
              <line x1="295" y1="195" x2="340" y2="245" stroke="#0B5D4B" strokeWidth="4.5" />

              {/* Vadodara to Surat */}
              <line x1="340" y1="245" x2="350" y2="350" stroke="#3DDC97" strokeWidth="9" opacity="0.3" />
              <line x1="340" y1="245" x2="350" y2="350" stroke="#0B5D4B" strokeWidth="4.5" />
            </g>

            {/* Live Vehicle Breadcrumb Markers */}
            {VEHICLES.map((v) => {
              const isVehicleSelected = selectedVehicle?.id === v.id;
              return (
                <g
                  key={v.id}
                  className="cursor-pointer transition-transform duration-200"
                  onClick={() => setSelectedVehicle(v)}
                >
                  {/* Pulsing ring */}
                  <circle
                    cx={v.x}
                    cy={v.y}
                    r={isVehicleSelected ? 12 : 9}
                    fill="#3DDC97"
                    opacity="0.35"
                    className="animate-pulse"
                  />
                  {/* Vehicle dot */}
                  <circle
                    cx={v.x}
                    cy={v.y}
                    r={isVehicleSelected ? 5.5 : 4}
                    fill={isVehicleSelected ? '#D97706' : '#059669'}
                    stroke="#FFFFFF"
                    strokeWidth="1.5"
                  />
                </g>
              );
            })}

            {/* Hub Corridor Nodes */}
            {NODES.map((node) => {
              const isSelected = selectedNode.id === node.id;
              return (
                <g
                  key={node.id}
                  className="cursor-pointer group"
                  onClick={() => {
                    setSelectedNode(node);
                    setSelectedVehicle(null);
                  }}
                >
                  {/* Selection Glow */}
                  {isSelected && (
                    <circle
                      cx={node.x}
                      cy={node.y}
                      r="18"
                      fill="#0B5D4B"
                      opacity="0.15"
                      className="animate-pulse"
                    />
                  )}

                  {/* Outer circle */}
                  <circle
                    cx={node.x}
                    cy={node.y}
                    r={isSelected ? '10' : '7.5'}
                    fill={isSelected ? '#0B5D4B' : '#FFFFFF'}
                    stroke="#0B5D4B"
                    strokeWidth={isSelected ? '3' : '2'}
                    className="transition-all duration-300 group-hover:scale-125"
                  />

                  {/* Inner dot */}
                  <circle
                    cx={node.x}
                    cy={node.y}
                    r={isSelected ? '3.5' : '2.5'}
                    fill={isSelected ? '#A7E8D2' : '#0B5D4B'}
                  />

                  {/* Node Label Pill */}
                  <rect
                    x={node.x - 18}
                    y={node.y + 12}
                    width="36"
                    height="16"
                    rx="8"
                    fill={isSelected ? '#0B5D4B' : '#FFFFFF'}
                    stroke="#E8F0EC"
                    strokeWidth="1"
                    className="shadow-2xs"
                  />
                  <text
                    x={node.x}
                    y={node.y + 23}
                    textAnchor="middle"
                    fill={isSelected ? '#FFFFFF' : '#12352E'}
                    fontSize="9"
                    fontWeight="800"
                    fontFamily="JetBrains Mono, monospace"
                  >
                    {node.code}
                  </text>
                </g>
              );
            })}
          </svg>

          {/* Map Canvas Legend */}
          <div className="absolute bottom-3 left-3 flex items-center space-x-3 bg-white/90 backdrop-blur-md px-3 py-1.5 rounded-xl border border-surface-subtle text-[10px] font-semibold text-textMuted shadow-2xs">
            <span className="flex items-center space-x-1">
              <span className="w-2.5 h-1 bg-forest rounded-full" />
              <span>Carpool Corridor</span>
            </span>
            <span className="flex items-center space-x-1">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              <span>Live Vehicle</span>
            </span>
          </div>
        </div>

        {/* Right Detail Inspection Panel */}
        <div className="space-y-4">
          {/* Selected Node or Vehicle Card */}
          {selectedVehicle ? (
            <div className="p-4 rounded-2xl bg-gradient-to-br from-amber-50/60 to-white border border-amber-200/80 shadow-xs space-y-3 animate-fade-in">
              <div className="flex items-center justify-between">
                <span className="text-[10px] font-bold text-amber-800 uppercase tracking-wider bg-amber-100/80 px-2 py-0.5 rounded-full">
                  Tracked Driver
                </span>
                <span className="text-xs font-mono font-bold text-amber-900">{selectedVehicle.speed}</span>
              </div>
              <div>
                <h3 className="text-sm font-extrabold text-textMain">{selectedVehicle.driverName}</h3>
                <p className="text-xs text-textMuted mt-0.5">{selectedVehicle.vehicle}</p>
              </div>
              <div className="p-2.5 rounded-xl bg-white border border-amber-100 text-xs space-y-1">
                <div className="flex justify-between text-textMuted">
                  <span>Corridor:</span>
                  <span className="font-semibold text-textMain">{selectedVehicle.corridor}</span>
                </div>
                <div className="flex justify-between text-textMuted">
                  <span>Telemetry:</span>
                  <span className="font-semibold text-emerald-700">{selectedVehicle.status}</span>
                </div>
                <div className="flex justify-between text-textMuted">
                  <span>Route Match:</span>
                  <span className="font-bold text-forest">{selectedVehicle.matchRate}</span>
                </div>
              </div>
            </div>
          ) : (
            <div className="p-4 rounded-2xl bg-white border border-surface-subtle shadow-xs space-y-3 animate-fade-in">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <MapPin className="w-4 h-4 text-forest" />
                  <span className="text-xs font-bold text-textMain">{selectedNode.name}</span>
                </div>
                <span className="px-2 py-0.5 rounded-full bg-forest-light text-forest font-mono text-[10px] font-extrabold">
                  {selectedNode.code}
                </span>
              </div>

              <p className="text-[11px] text-textMuted leading-relaxed">
                {selectedNode.description}
              </p>

              <div className="grid grid-cols-2 gap-2 pt-1 font-mono">
                <div className="p-2.5 rounded-xl bg-surface border border-surface-subtle">
                  <div className="text-[10px] text-textMuted uppercase font-sans font-bold">Active Trips</div>
                  <div className="text-lg font-extrabold text-forest mt-0.5">{selectedNode.activeTrips}</div>
                </div>
                <div className="p-2.5 rounded-xl bg-surface border border-surface-subtle">
                  <div className="text-[10px] text-textMuted uppercase font-sans font-bold">Match Score</div>
                  <div className="text-lg font-extrabold text-emerald-700 mt-0.5">{selectedNode.matchScore}%</div>
                </div>
              </div>
            </div>
          )}

          {/* Quick Corridor Selection Tabs */}
          <div className="space-y-1.5">
            <span className="text-[11px] font-bold text-textMuted uppercase tracking-wider block px-1">
              Select Highway Hub
            </span>
            <div className="grid grid-cols-2 gap-1.5">
              {NODES.map((n) => (
                <button
                  key={n.id}
                  onClick={() => {
                    setSelectedNode(n);
                    setSelectedVehicle(null);
                  }}
                  className={`px-3 py-2 rounded-xl text-xs font-bold transition-all text-left truncate cursor-pointer ${
                    selectedNode.id === n.id && !selectedVehicle
                      ? 'bg-forest text-white shadow-xs'
                      : 'bg-white hover:bg-surface border border-surface-subtle text-textMain'
                  }`}
                >
                  {n.name.split(' ')[0]} ({n.code})
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
