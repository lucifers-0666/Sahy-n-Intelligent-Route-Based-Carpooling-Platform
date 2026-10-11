import React, { useState, useEffect } from 'react';
import { SosIncident } from '../types/admin';
import { UnmaskModal } from './UnmaskModal';
import {
  ShieldAlert,
  Phone,
  PhoneCall,
  MapPin,
  Clock,
  Car,
  User,
  Users,
  CheckCircle,
  Copy,
  Check,
  AlertTriangle,
  X,
  ExternalLink,
  Navigation,
} from 'lucide-react';

interface SosIncidentModalProps {
  incident: SosIncident | null;
  isOpen: boolean;
  onClose: () => void;
  onLogPoliceCall: (incidentId: string, notes?: string) => Promise<void>;
  onResolveIncident: (incidentId: string, notes?: string) => Promise<void>;
}

export const SosIncidentModal: React.FC<SosIncidentModalProps> = ({
  incident,
  isOpen,
  onClose,
  onLogPoliceCall,
  onResolveIncident,
}) => {
  const [copiedIndex, setCopiedIndex] = useState<number | null>(null);
  const [actionLoading, setActionLoading] = useState(false);
  const [policeCallLogged, setPoliceCallLogged] = useState(false);
  const [policeNotes, setPoliceNotes] = useState('');

  // PII Unmasking state
  const [unmaskOpen, setUnmaskOpen] = useState(false);
  const [unmaskTarget, setUnmaskTarget] = useState<{ id: string; field: string; label: string } | null>(null);
  const [unmaskedValues, setUnmaskedValues] = useState<Record<string, string>>({});

  // Synthesized Web Audio API Alarm
  useEffect(() => {
    if (isOpen && incident) {
      try {
        const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
        if (AudioContextClass) {
          const ctx = new AudioContextClass();
          const osc1 = ctx.createOscillator();
          const osc2 = ctx.createOscillator();
          const gain = ctx.createGain();

          osc1.type = 'sawtooth';
          osc1.frequency.setValueAtTime(880, ctx.currentTime); // A5
          osc1.frequency.exponentialRampToValueAtTime(440, ctx.currentTime + 0.3); // A4

          osc2.type = 'sine';
          osc2.frequency.setValueAtTime(660, ctx.currentTime);

          gain.gain.setValueAtTime(0.2, ctx.currentTime);
          gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.6);

          osc1.connect(gain);
          osc2.connect(gain);
          gain.connect(ctx.destination);

          osc1.start();
          osc2.start();
          osc1.stop(ctx.currentTime + 0.6);
          osc2.stop(ctx.currentTime + 0.6);
        }
      } catch {
        // AudioContext may be blocked before interaction, handled gracefully
      }
    }
  }, [isOpen, incident]);

  if (!isOpen || !incident) return null;

  const handleCopy = (text: string, idx: number) => {
    navigator.clipboard.writeText(text);
    setCopiedIndex(idx);
    setTimeout(() => setCopiedIndex(null), 2000);
  };

  const handlePoliceSubmit = async () => {
    setActionLoading(true);
    try {
      await onLogPoliceCall(incident.incidentId, policeNotes || '112 Police Emergency Dispatched from Admin Operations Command.');
      setPoliceCallLogged(true);
    } catch (err: any) {
      alert(`Failed to log police dispatch: ${err.message}`);
    } finally {
      setActionLoading(false);
    }
  };

  const handleResolve = async () => {
    setActionLoading(true);
    try {
      await onResolveIncident(incident.incidentId, 'Resolved by safety officer on duty.');
      onClose();
    } catch (err: any) {
      alert(`Failed to resolve incident: ${err.message}`);
    } finally {
      setActionLoading(false);
    }
  };

  const triggerUnmask = (resourceId: string, field: string, label: string) => {
    setUnmaskTarget({ id: resourceId, field, label });
    setUnmaskOpen(true);
  };

  const passengerPhone = unmaskedValues[`passenger_${incident.passenger.id}`] || incident.passenger.phone;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-black/70 backdrop-blur-md animate-fade-in overflow-y-auto">
      <div className="bg-stone-900 text-stone-100 rounded-3xl max-w-4xl w-full border border-rose-500/30 shadow-[0_0_50px_rgba(225,29,72,0.3)] overflow-hidden my-auto">
        {/* Flashing Urgent Top Banner */}
        <div className="bg-gradient-to-r from-rose-700 via-rose-600 to-red-700 p-4 sm:p-5 flex items-center justify-between animate-pulse">
          <div className="flex items-center space-x-3.5">
            <div className="w-12 h-12 rounded-2xl bg-white/20 backdrop-blur-sm flex items-center justify-center shrink-0 border border-white/30 text-white">
              <ShieldAlert className="w-7 h-7" />
            </div>
            <div>
              <div className="flex items-center space-x-2">
                <span className="px-2.5 py-0.5 rounded-full bg-white text-rose-700 text-[10px] font-black uppercase tracking-wider">
                  HIGH-PRIORITY SOS DISPATCH
                </span>
                <span className="text-white/80 text-xs font-semibold">
                  Incident #{incident.incidentId.slice(-6)}
                </span>
              </div>
              <h2 className="text-lg sm:text-xl font-black text-white tracking-tight mt-0.5">
                Active In-Transit Emergency Distress Alert
              </h2>
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-white/80 hover:text-white p-2 rounded-xl bg-black/20 hover:bg-black/30 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Content Grid */}
        <div className="p-5 sm:p-8 space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            {/* Left Column: Corridor & Live Trajectory Map (7 cols) */}
            <div className="lg:col-span-7 space-y-5">
              {/* Telematics & Location Card */}
              <div className="bg-stone-800/80 rounded-2xl p-4 sm:p-5 border border-stone-700/60">
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center space-x-2 text-rose-400 text-xs font-bold uppercase tracking-wider">
                    <Navigation className="w-4 h-4 animate-spin text-rose-400" />
                    <span>Real-Time Highway Corridor Telematics</span>
                  </div>
                  <span className="px-2 py-0.5 rounded-md bg-rose-500/20 text-rose-300 text-[11px] font-bold">
                    GPS Fix: ±5m Live
                  </span>
                </div>

                {/* SVG Live Corridor Trajectory Visualizer */}
                <div className="relative h-44 rounded-xl bg-stone-950/90 border border-stone-800 overflow-hidden flex flex-col justify-between p-3.5">
                  {/* Subtle Grid Lines */}
                  <div className="absolute inset-0 opacity-10 bg-[radial-gradient(#fff_1px,transparent_1px)] [background-size:16px_16px]" />

                  {/* Route Trajectory Visual */}
                  <div className="relative z-10 flex items-center justify-between text-xs font-semibold text-stone-300">
                    <div className="flex items-center space-x-1.5">
                      <div className="w-3 h-3 rounded-full bg-emerald-400 ring-4 ring-emerald-500/20" />
                      <span>{incident.ride?.origin?.name || 'Ahmedabad ISBT'}</span>
                    </div>
                    <div className="flex items-center space-x-1.5">
                      <span>{incident.ride?.destination?.name || 'Gandhinagar InfoCity'}</span>
                      <div className="w-3 h-3 rounded-full bg-rose-400 ring-4 ring-rose-500/20" />
                    </div>
                  </div>

                  {/* Center Trajectory Stream */}
                  <div className="relative z-10 my-auto py-2">
                    <div className="w-full bg-stone-800 h-2 rounded-full relative overflow-hidden">
                      <div className="bg-gradient-to-r from-emerald-500 via-amber-400 to-rose-500 h-full w-2/3" />
                    </div>
                    <div className="flex justify-between items-center text-[11px] text-stone-400 mt-2">
                      <span className="text-emerald-400 font-bold">Trip Origin</span>
                      <span className="text-amber-300 font-bold flex items-center space-x-1">
                        <MapPin className="w-3 h-3 inline text-amber-400" />
                        <span>Distress Point: {incident.location.address}</span>
                      </span>
                      <span className="text-rose-400 font-bold">Destination</span>
                    </div>
                  </div>

                  {/* Coordinates Footnote */}
                  <div className="relative z-10 flex items-center justify-between text-[11px] text-stone-500 pt-1 border-t border-stone-800/80">
                    <span>Lat: {incident.location.latitude.toFixed(5)}</span>
                    <span>Lng: {incident.location.longitude.toFixed(5)}</span>
                    <a
                      href={`https://www.openstreetmap.org/?mlat=${incident.location.latitude}&mlon=${incident.location.longitude}#map=16/${incident.location.latitude}/${incident.location.longitude}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-forest-mint hover:underline flex items-center space-x-1"
                    >
                      <span>Open OSM Map</span>
                      <ExternalLink className="w-3 h-3" />
                    </a>
                  </div>
                </div>

                {/* Distress Note */}
                <div className="mt-3 bg-rose-950/40 border border-rose-900/60 rounded-xl p-3 flex items-start space-x-2.5">
                  <AlertTriangle className="w-4 h-4 text-rose-400 shrink-0 mt-0.5" />
                  <p className="text-xs text-rose-200 leading-relaxed font-medium">
                    Passenger triggered in-ride distress button. Automatic vehicle telemetry lock engaged.
                  </p>
                </div>
              </div>

              {/* Ride & Driver Info */}
              <div className="bg-stone-800/80 rounded-2xl p-4 sm:p-5 border border-stone-700/60 space-y-3">
                <div className="text-xs font-bold text-stone-400 uppercase tracking-wider">
                  Vehicle & Driver Telemetry
                </div>
                <div className="grid grid-cols-2 gap-3 text-xs">
                  <div className="p-3 rounded-xl bg-stone-900/80 border border-stone-800">
                    <span className="text-stone-400 block text-[11px]">Designated Driver</span>
                    <span className="font-bold text-stone-100 text-sm mt-0.5 block">
                      {incident.driver?.name || 'Verified Driver'}
                    </span>
                    <span className="text-stone-400 text-[11px]">
                      {incident.driver?.phone || '+91 98****0941'}
                    </span>
                  </div>
                  <div className="p-3 rounded-xl bg-stone-900/80 border border-stone-800">
                    <span className="text-stone-400 block text-[11px]">Corridor Journey Status</span>
                    <span className="font-bold text-rose-400 text-sm mt-0.5 block uppercase">
                      Distress / Active
                    </span>
                    <span className="text-stone-400 text-[11px]">
                      Ride ID: {incident.ride?.id?.slice(-8) || 'GJ-CORRIDOR-01'}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* Right Column: Passenger & Emergency Contacts Ring (5 cols) */}
            <div className="lg:col-span-5 space-y-5">
              {/* Passenger Card with Unmasking */}
              <div className="bg-stone-800/80 rounded-2xl p-4 sm:p-5 border border-stone-700/60">
                <div className="flex items-center justify-between mb-3">
                  <span className="text-xs font-bold text-stone-400 uppercase tracking-wider">
                    Distressed Passenger
                  </span>
                  <span className="px-2 py-0.5 rounded-md bg-emerald-500/20 text-emerald-300 text-[10px] font-bold">
                    Authenticated Rider
                  </span>
                </div>

                <div className="space-y-2">
                  <div className="flex items-center space-x-3">
                    <div className="w-10 h-10 rounded-xl bg-stone-700 flex items-center justify-center font-bold text-stone-200">
                      {incident.passenger.name.slice(0, 2).toUpperCase()}
                    </div>
                    <div>
                      <h4 className="text-sm font-extrabold text-stone-100">{incident.passenger.name}</h4>
                      <p className="text-xs text-stone-400">{incident.passenger.email || 'Verified Commuter'}</p>
                    </div>
                  </div>

                  {/* Phone with Unmask */}
                  <div className="pt-2 flex items-center justify-between bg-stone-900/80 p-3 rounded-xl border border-stone-800">
                    <div>
                      <span className="text-[10px] uppercase font-bold text-stone-500 block">Phone</span>
                      <span className="text-xs font-mono font-bold text-stone-200">{passengerPhone}</span>
                    </div>
                    {!unmaskedValues[`passenger_${incident.passenger.id}`] ? (
                      <button
                        onClick={() => triggerUnmask(incident.passenger.id, 'phone', 'Passenger Phone')}
                        className="px-2.5 py-1 rounded-lg bg-stone-800 hover:bg-stone-700 text-stone-300 text-xs font-bold border border-stone-700 transition-colors"
                      >
                        Unmask PII
                      </button>
                    ) : (
                      <a
                        href={`tel:${passengerPhone}`}
                        className="p-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white transition-colors"
                      >
                        <PhoneCall className="w-4 h-4" />
                      </a>
                    )}
                  </div>
                </div>
              </div>

              {/* Emergency Contacts Ring */}
              <div className="bg-stone-800/80 rounded-2xl p-4 sm:p-5 border border-stone-700/60">
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center space-x-1.5 text-xs font-bold text-stone-400 uppercase tracking-wider">
                    <Users className="w-4 h-4 text-rose-400" />
                    <span>Passenger Safety Ring</span>
                  </div>
                  <span className="text-[11px] text-stone-500">
                    {incident.passenger.emergencyContacts?.length || 0} Contacts
                  </span>
                </div>

                <div className="space-y-2.5">
                  {incident.passenger.emergencyContacts && incident.passenger.emergencyContacts.length > 0 ? (
                    incident.passenger.emergencyContacts.map((contact, idx) => (
                      <div
                        key={idx}
                        className="bg-stone-900/90 rounded-xl p-3 border border-stone-800 flex items-center justify-between"
                      >
                        <div>
                          <div className="flex items-center space-x-1.5">
                            <span className="text-xs font-bold text-stone-200">{contact.name}</span>
                            {contact.relationship && (
                              <span className="px-1.5 py-0.5 rounded bg-stone-800 text-[10px] text-stone-400">
                                {contact.relationship}
                              </span>
                            )}
                          </div>
                          <span className="text-xs font-mono text-stone-400 mt-0.5 block">
                            {contact.phone}
                          </span>
                        </div>
                        <div className="flex items-center space-x-1.5">
                          <button
                            onClick={() => handleCopy(contact.phone, idx)}
                            className="p-2 rounded-lg bg-stone-800 hover:bg-stone-700 text-stone-300 transition-colors"
                            title="Copy Phone"
                          >
                            {copiedIndex === idx ? (
                              <Check className="w-3.5 h-3.5 text-emerald-400" />
                            ) : (
                              <Copy className="w-3.5 h-3.5" />
                            )}
                          </button>
                          <a
                            href={`tel:${contact.phone}`}
                            className="p-2 rounded-lg bg-rose-600 hover:bg-rose-500 text-white transition-colors"
                            title="Dial Contact"
                          >
                            <Phone className="w-3.5 h-3.5" />
                          </a>
                        </div>
                      </div>
                    ))
                  ) : (
                    <div className="text-center py-4 text-xs text-stone-500 bg-stone-900/60 rounded-xl border border-stone-800">
                      No personal emergency contacts registered by passenger.
                    </div>
                  )}
                </div>
              </div>

              {/* 1-Click Police Call (112) Dispatch Action */}
              <div className="bg-stone-800/80 rounded-2xl p-4 sm:p-5 border border-stone-700/60 space-y-3">
                <span className="text-xs font-bold text-stone-400 uppercase tracking-wider block">
                  Emergency Authority Dispatch
                </span>

                <div>
                  <textarea
                    rows={2}
                    value={policeNotes}
                    onChange={(e) => setPoliceNotes(e.target.value)}
                    placeholder="Police dispatch notes (e.g. PCR Van #14 routed to Highway Toll KM 38)..."
                    className="w-full px-3 py-2 rounded-xl bg-stone-950 border border-stone-700 text-xs text-stone-200 placeholder-stone-500 focus:outline-none focus:ring-1 focus:ring-rose-500 resize-none"
                  />
                </div>

                <button
                  onClick={handlePoliceSubmit}
                  disabled={actionLoading || policeCallLogged}
                  className={`w-full py-3 px-4 rounded-xl flex items-center justify-center space-x-2 text-xs font-black uppercase tracking-wider transition-all shadow-lg ${
                    policeCallLogged
                      ? 'bg-emerald-700 text-white'
                      : 'bg-rose-600 hover:bg-rose-500 text-white'
                  }`}
                >
                  {policeCallLogged ? (
                    <>
                      <CheckCircle className="w-4 h-4" />
                      <span>Police Call (112) Logged & Dispatched</span>
                    </>
                  ) : (
                    <>
                      <PhoneCall className="w-4 h-4" />
                      <span>Log Police Call (112) Dispatch</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>

          {/* Bottom Action Footer */}
          <div className="pt-4 border-t border-stone-800 flex flex-wrap items-center justify-between gap-3">
            <div className="text-xs text-stone-500 flex items-center space-x-2">
              <Clock className="w-4 h-4" />
              <span>Distress Triggered: {new Date(incident.timestamp).toLocaleTimeString()}</span>
            </div>

            <div className="flex items-center space-x-3">
              <button
                onClick={onClose}
                className="px-4 py-2 rounded-xl border border-stone-700 hover:bg-stone-800 text-stone-300 text-xs font-bold transition-colors"
              >
                Close Console
              </button>
              <button
                onClick={handleResolve}
                disabled={actionLoading}
                className="px-5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold flex items-center space-x-1.5 transition-all shadow-sm"
              >
                <CheckCircle className="w-4 h-4" />
                <span>Resolve Emergency Incident</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Unmask PII Modal */}
      {unmaskTarget && (
        <UnmaskModal
          isOpen={unmaskOpen}
          onClose={() => setUnmaskOpen(false)}
          resourceId={unmaskTarget.id}
          fieldName={unmaskTarget.field}
          fieldLabel={unmaskTarget.label}
          onSuccess={(unmaskedVal) => {
            setUnmaskedValues((prev) => ({
              ...prev,
              [`passenger_${unmaskTarget.id}`]: String(unmaskedVal),
            }));
          }}
        />
      )}
    </div>
  );
};
