import React, { useState } from 'react';
import { MapPin, Navigation, Car, Shield, Activity, Info, CheckCircle2 } from 'lucide-react';
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
}

const NODES: CorridorNode[] = [
  { id: 'gdn', name: 'Gandhinagar (InfoCity)', code: 'GDN', x: 260, y: 55, activeTrips: 18, matchScore: 96, status: 'high_demand' },
  { id: 'ahm', name: 'Ahmedabad (SG Highway Hub)', code: 'AHM', x: 250, y: 130, activeTrips: 42, matchScore: 94, status: 'optimal' },
  { id: 'rjk', name: 'Rajkot (Ring Road)', code: 'RJK', x: 90, y: 170, activeTrips: 14, matchScore: 88, status: 'moderate' },
  { id: 'and', name: 'Anand / Nadiad Tollway', code: 'AND', x: 295, y: 195, activeTrips: 12, matchScore: 92, status: 'optimal' },
  { id: 'bar', name: 'Vadodara (Expressway)', code: 'BDQ', x: 340, y: 245, activeTrips: 28, matchScore: 94, status: 'optimal' },
  { id: 'sur', name: 'Surat (Ring Road NH48)', code: 'ST', x: 350, y: 350, activeTrips: 22, matchScore: 91, status: 'optimal' },
];

interface VehicleBreadcrumb {
  id: string;
  driverName: string;
  vehicle: string;
  corridor: string;
  x: number;
  y: number;
  status: string;
}

const VEHICLES: VehicleBreadcrumb[] = [
  { id: 'v1', driverName: 'Vikramjit Singh', vehicle: 'Hyundai Creta', corridor: 'AHM - BDQ Expressway', x: 290, y: 185, status: 'Cruising · 88 km/h' },
  { id: 'v2', driverName: 'Priya Sharma', vehicle: 'Tata Nexon EV', corridor: 'AHM - GDN Metro', x: 255, y: 90, status: 'Smooth Traffic · 65 km/h' },
  { id: 'v3', driverName: 'Karan Dave', vehicle: 'Maruti Brezza', corridor: 'BDQ - ST Corridor', x: 345, y: 295, status: 'On Schedule · 80 km/h' },
  { id: 'v4', driverName: 'Mehul Shah', vehicle: 'Honda City', corridor: 'AHM - RJK Highway', x: 170, y: 150, status: 'Toll Passed · 75 km/h' },
];

export const CorridorMapWidget: React.FC = () => {
  const [selectedNode, setSelectedNode] = useState<CorridorNode>(NODES[1]);
  const [selectedVehicle, setSelectedVehicle] = useState<VehicleBreadcrumb | null>(null);

  return (
    <div className="card p-6 shadow-xs overflow-hidden">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-4">
        <div>
          <h2 className="text-sm font-bold text-textMain flex items-center space-x-2">
            <Navigation className="w-4 h-4 text-forest" />
            <span>Interactive Highway Corridor & Live Telemetry Map</span>
          </h2>
          <p className="text-[11px] text-textMuted mt-0.5">
            Geospatial route network, real-time vehicle breadcrumbs, and corridor match densities across Gujarat.
          </p>
        </div>

        <div className="flex items-center space-x-2 shrink-0">
          <span className="flex items-center space-x-1.5 text-[11px] text-textMuted bg-surface px-2.5 py-1 rounded-full border border-surface-subtle font-medium">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            <span>OSRM Engine Live</span>
          </span>
          <span className="flex items-center space-x-1.5 text-[11px] text-textMuted bg-surface px-2.5 py-1 rounded-full border border-surface-subtle font-medium">
            <Car className="w-3 h-3 text-forest" />
            <span>{VEHICLES.length} Tracked Vehicles</span>
          </span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-center">
        {/* Interactive SVG Canvas */}
        <div className="lg:col-span-2 relative bg-gradient-to-b from-surface/60 to-surface rounded-2xl border border-surface-subtle p-3 flex items-center justify-center overflow-hidden">
          <svg
            viewBox="0 0 450 400"
            className="w-full h-auto max-h-[360px] select-none"
            style={{ filter: 'drop-shadow(0 2px 4px rgba(0,0,0,0.02))' }}
          >
            <defs>
              {/* Route Gradients */}
              <linearGradient id="corridorGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#0B5D4B" stopOpacity="0.8" />
                <stop offset="50%" stopColor="#10B981" stopOpacity="0.9" />
                <stop offset="100%" stopColor="#084C3A" stopOpacity="0.8" />
              </linearGradient>
              <linearGradient id="activePulse" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stopColor="#0B5D4B" />
                <stop offset="100%" stopColor="#A7E8D2" />
              </linearGradient>
            </defs>

            {/* Highway Route Lines */}
            {/* Gandhinagar to Ahmedabad */}
            <line x1="260" y1="55" x2="250" y2="130" stroke="#0B5D4B" strokeWidth="4" strokeLinecap="round" strokeDasharray="6 4" opacity="0.7" />
            {/* Ahmedabad to Rajkot */}
            <line x1="250" y1="130" x2="90" y2="170" stroke="#0B5D4B" strokeWidth="3.5" strokeLinecap="round" strokeDasharray="5 3" opacity="0.6" />
            {/* Ahmedabad to Anand/Nadiad */}
            <line x1="250" y1="130" x2="295" y2="195" stroke="#0B5D4B" strokeWidth="5" strokeLinecap="round" />
            {/* Anand to Vadodara */}
            <line x1="295" y1="195" x2="340" y2="245" stroke="#0B5D4B" strokeWidth="5" strokeLinecap="round" />
            {/* Vadodara to Surat */}
            <line x1="340" y1="245" x2="350" y2="350" stroke="#0B5D4B" strokeWidth="4.5" strokeLinecap="round" strokeDasharray="8 4" opacity="0.8" />

            {/* Highway Badges on Map */}
            <text x="215" y="100" fill="#084C3A" fontSize="9" fontWeight="bold" opacity="0.8">NH147</text>
            <text x="165" y="142" fill="#084C3A" fontSize="9" fontWeight="bold" opacity="0.8">NH47</text>
            <text x="315" y="170" fill="#0B5D4B" fontSize="10" fontWeight="bold">NE1 Expressway</text>
            <text x="355" y="300" fill="#084C3A" fontSize="9" fontWeight="bold" opacity="0.8">NH48</text>

            {/* Vehicle Breadcrumb Pointers */}
            {VEHICLES.map((v) => {
              const isSelected = selectedVehicle?.id === v.id;
              return (
                <g
                  key={v.id}
                  transform={`translate(${v.x}, ${v.y})`}
                  className="cursor-pointer transition-transform hover:scale-125"
                  onClick={() => setSelectedVehicle(v)}
                >
                  <circle r={isSelected ? "9" : "7"} fill="#084C3A" className="animate-ping opacity-40" />
                  <circle r={isSelected ? "8" : "6"} fill="#0B5D4B" stroke="#ffffff" strokeWidth="2" />
                  <path d="M -3 -3 L 3 0 L -3 3 Z" fill="#ffffff" />
                  <text
                    x="9"
                    y="3"
                    fontSize="8"
                    fontWeight="bold"
                    fill="#12352E"
                    className="pointer-events-none drop-shadow-xs"
                  >
                    {v.driverName.split(' ')[0]}
                  </text>
                </g>
              );
            })}

            {/* Corridor Hub Nodes */}
            {NODES.map((node) => {
              const isSelected = selectedNode.id === node.id;
              return (
                <g
                  key={node.id}
                  transform={`translate(${node.x}, ${node.y})`}
                  className="cursor-pointer transition-transform hover:scale-110"
                  onClick={() => setSelectedNode(node)}
                >
                  <circle
                    r={isSelected ? "14" : "10"}
                    fill={isSelected ? "#0B5D4B" : "#ffffff"}
                    stroke="#0B5D4B"
                    strokeWidth={isSelected ? "3" : "2"}
                    className="shadow-sm transition-all"
                  />
                  <circle
                    r="4"
                    fill={isSelected ? "#A7E8D2" : "#0B5D4B"}
                  />
                  <text
                    x="0"
                    y={node.y > 300 ? "-16" : "22"}
                    textAnchor="middle"
                    fontSize="10"
                    fontWeight="bold"
                    fill={isSelected ? "#0B5D4B" : "#12352E"}
                    className="pointer-events-none select-none"
                  >
                    {node.code}
                  </text>
                </g>
              );
            })}
          </svg>

          {/* Quick Map Legend Overlay */}
          <div className="absolute bottom-2 left-2 bg-white/90 backdrop-blur-xs p-2 rounded-xl border border-surface-subtle text-[10px] space-y-1 shadow-2xs">
            <div className="flex items-center space-x-1.5 text-textMain font-semibold">
              <span className="w-2.5 h-1 bg-forest rounded" />
              <span>Dedicated Carpooling Corridor</span>
            </div>
            <div className="flex items-center space-x-1.5 text-textMuted">
              <span className="w-2 h-2 rounded-full bg-forest border border-white" />
              <span>Live Vehicle Breadcrumb</span>
            </div>
          </div>
        </div>

        {/* Node & Telemetry Inspection Panel */}
        <div className="space-y-4">
          {/* Selected Node Details Card */}
          <div className="p-4 rounded-2xl bg-surface border border-surface-subtle space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <MapPin className="w-4 h-4 text-forest" />
                <h3 className="font-bold text-textMain text-xs">{selectedNode.name}</h3>
              </div>
              <Badge variant="emerald">{selectedNode.code}</Badge>
            </div>

            <div className="grid grid-cols-2 gap-2 text-xs">
              <div className="p-2.5 bg-white rounded-xl border border-surface-subtle">
                <span className="text-[10px] text-textMuted block font-medium">Active Trips</span>
                <span className="font-bold text-forest text-sm font-mono">{selectedNode.activeTrips} in transit</span>
              </div>
              <div className="p-2.5 bg-white rounded-xl border border-surface-subtle">
                <span className="text-[10px] text-textMuted block font-medium">Route Match Avg</span>
                <span className="font-bold text-textMain text-sm font-mono">{selectedNode.matchScore}%</span>
              </div>
            </div>

            <div className="text-[11px] text-textMuted flex items-center justify-between pt-1 border-t border-surface-subtle">
              <span>Corridor Traffic:</span>
              <span className="font-bold text-emerald-700 capitalize">{selectedNode.status.replace('_', ' ')}</span>
            </div>
          </div>

          {/* Selected Vehicle or Quick Telemetry Card */}
          {selectedVehicle ? (
            <div className="p-4 rounded-2xl bg-forest-light/30 border border-forest/20 space-y-2 animate-fade-in">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <Car className="w-4 h-4 text-forest" />
                  <span className="font-bold text-textMain text-xs">{selectedVehicle.driverName}</span>
                </div>
                <Badge variant="gray">{selectedVehicle.vehicle}</Badge>
              </div>
              <div className="text-[11px] text-textMuted">
                Route: <span className="font-semibold text-textMain">{selectedVehicle.corridor}</span>
              </div>
              <div className="text-[11px] text-forest font-bold">
                Telemetry: {selectedVehicle.status}
              </div>
              <button
                onClick={() => setSelectedVehicle(null)}
                className="text-[10px] text-textMuted hover:text-textMain font-semibold cursor-pointer underline"
              >
                Clear vehicle inspection
              </button>
            </div>
          ) : (
            <div className="p-4 rounded-2xl bg-white border border-surface-subtle space-y-2 text-xs">
              <div className="flex items-center space-x-1.5 text-forest font-bold text-[11px]">
                <Activity className="w-3.5 h-3.5" />
                <span>Geospatial Route Density</span>
              </div>
              <p className="text-[11px] text-textMuted leading-relaxed">
                Click any highway node or vehicle breadcrumb on the corridor canvas to inspect live route alignment, OSRM waypoints, and passenger manifest states.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
