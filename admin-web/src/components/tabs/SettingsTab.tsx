import React from 'react';
import {
  Server,
  Database,
  Radio,
  Map,
  ShieldCheck,
  CheckCircle2,
  Lock,
} from 'lucide-react';

interface SettingsTabProps {
  dbConnected: boolean;
}

export const SettingsTab: React.FC<SettingsTabProps> = ({ dbConnected }) => {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-extrabold text-textMain tracking-tight">
          System Architecture & Operational Health
        </h1>
        <p className="text-xs text-textMuted font-medium mt-0.5">
          Diagnostics for the Node.js API, MongoDB Atlas cluster, Socket.IO telematics pipeline, and OpenStreetMap engines.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Core Backend Service */}
        <div className="bg-white p-5 rounded-2xl border border-surface-subtle shadow-xs space-y-4">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-forest-light flex items-center justify-center text-forest">
              <Server className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-sm font-bold text-textMain">Node.js Express API Subsystem</h2>
              <p className="text-[11px] text-textMuted">REST API Engine & Microservice Layer</p>
            </div>
          </div>

          <div className="space-y-2 text-xs divide-y divide-surface-subtle pt-2">
            <div className="flex justify-between py-1.5">
              <span className="text-textMuted">Service Port:</span>
              <span className="font-mono font-bold text-textMain">5000</span>
            </div>
            <div className="flex justify-between py-1.5">
              <span className="text-textMuted">Environment:</span>
              <span className="font-mono font-bold text-forest">Production / Node 24</span>
            </div>
            <div className="flex justify-between py-1.5">
              <span className="text-textMuted">Authentication Mode:</span>
              <span className="font-mono font-bold text-textMain">JWT (HS256) with Role-Based Guard</span>
            </div>
            <div className="flex justify-between py-1.5">
              <span className="text-textMuted">Fail-Closed Middleware:</span>
              <span className="text-emerald-700 font-bold flex items-center space-x-1">
                <CheckCircle2 className="w-3.5 h-3.5" />
                <span>Enforced (401/403 Strict)</span>
              </span>
            </div>
          </div>
        </div>

        {/* Database */}
        <div className="bg-white p-5 rounded-2xl border border-surface-subtle shadow-xs space-y-4">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-emerald-50 flex items-center justify-center text-emerald-700">
              <Database className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-sm font-bold text-textMain">MongoDB Database Engine</h2>
              <p className="text-[11px] text-textMuted">Geospatial 2dsphere Indexed Primary Store</p>
            </div>
          </div>

          <div className="space-y-2 text-xs divide-y divide-surface-subtle pt-2">
            <div className="flex justify-between py-1.5">
              <span className="text-textMuted">Cluster Connection:</span>
              <span className="font-bold text-emerald-700 flex items-center space-x-1">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                <span>{dbConnected ? 'Online & Synchronized' : 'Connecting'}</span>
              </span>
            </div>
            <div className="flex justify-between py-1.5">
              <span className="text-textMuted">Geospatial Indexing:</span>
              <span className="font-mono font-bold text-textMain">2dsphere on Origin/Destination</span>
            </div>
            <div className="flex justify-between py-1.5">
              <span className="text-textMuted">Database Name:</span>
              <span className="font-mono font-bold text-textMain">sahyan</span>
            </div>
            <div className="flex justify-between py-1.5">
              <span className="text-textMuted">Data Isolation:</span>
              <span className="text-emerald-700 font-bold">Strict User/Driver Isolation</span>
            </div>
          </div>
        </div>

        {/* Telematics Pipeline */}
        <div className="bg-white p-5 rounded-2xl border border-surface-subtle shadow-xs space-y-4">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-blue-50 flex items-center justify-center text-blue-700">
              <Radio className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-sm font-bold text-textMain">Socket.IO Telematics Pipeline</h2>
              <p className="text-[11px] text-textMuted">Real-Time Vehicle Position Broadcasting</p>
            </div>
          </div>

          <div className="space-y-2 text-xs divide-y divide-surface-subtle pt-2">
            <div className="flex justify-between py-1.5">
              <span className="text-textMuted">Driver Room Handshake:</span>
              <span className="font-bold text-textMain">JWT-Verified Room Join</span>
            </div>
            <div className="flex justify-between py-1.5">
              <span className="text-textMuted">Location Broadcast Rate:</span>
              <span className="font-mono font-bold text-textMain">~1.5s Interpolation Delta</span>
            </div>
            <div className="flex justify-between py-1.5">
              <span className="text-textMuted">Unauthorized Eavesdropping:</span>
              <span className="text-emerald-700 font-bold">Strictly Blocked by Room Auth</span>
            </div>
          </div>
        </div>

        {/* Open-Source Mapping Stack */}
        <div className="bg-white p-5 rounded-2xl border border-surface-subtle shadow-xs space-y-4">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-teal-50 flex items-center justify-center text-teal-700">
              <Map className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-sm font-bold text-textMain">Free & Open Mapping Infrastructure</h2>
              <p className="text-[11px] text-textMuted">Zero Paid API Billable Dependencies</p>
            </div>
          </div>

          <div className="space-y-2 text-xs divide-y divide-surface-subtle pt-2">
            <div className="flex justify-between py-1.5">
              <span className="text-textMuted">Tile Server:</span>
              <span className="font-mono font-bold text-textMain">OpenStreetMap Carto Vector Tiles</span>
            </div>
            <div className="flex justify-between py-1.5">
              <span className="text-textMuted">Routing Engine:</span>
              <span className="font-mono font-bold text-textMain">OSRM (Open Source Routing Machine)</span>
            </div>
            <div className="flex justify-between py-1.5">
              <span className="text-textMuted">Geocoding Service:</span>
              <span className="font-mono font-bold text-textMain">Nominatim Open Search Engine</span>
            </div>
            <div className="flex justify-between py-1.5">
              <span className="text-textMuted">Paid Google Maps Usage:</span>
              <span className="text-emerald-700 font-bold">0% (Completely Free & Sovereign)</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
