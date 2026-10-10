import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { ShieldCheck, Lock, Mail, AlertCircle, ArrowRight } from 'lucide-react';

export const LoginScreen: React.FC = () => {
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setError('Please provide both administrator email and password.');
      return;
    }

    setLoading(true);
    setError(null);
    try {
      await login(email, password);
    } catch (err: any) {
      setError(err.message || 'Login failed. Please verify credentials.');
    } finally {
      setLoading(false);
    }
  };

  const handleQuickFill = () => {
    setEmail('admin@sahyan.app');
    setPassword('AdminPassword123!');
    setError(null);
  };

  return (
    <div className="min-h-screen bg-surface flex flex-col items-center justify-center p-4">
      <div className="w-full max-w-md bg-white rounded-3xl p-8 border border-surface-subtle shadow-md space-y-6">
        {/* Brand header */}
        <div className="text-center space-y-2">
          <div className="w-14 h-14 rounded-2xl bg-forest-dark text-white font-extrabold text-2xl flex items-center justify-center mx-auto shadow-md shadow-forest/20">
            S
          </div>
          <div className="inline-block px-3 py-1 rounded-full bg-forest-light text-forest text-xs font-bold uppercase tracking-wider">
            Sahyān Operations Console
          </div>
          <h1 className="text-2xl font-extrabold text-textMain tracking-tight">
            Administrative Sign In
          </h1>
          <p className="text-xs text-textMuted font-medium">
            Restricted to authorized fleet operators, safety officers, and system administrators.
          </p>
        </div>

        {/* Error notification */}
        {error && (
          <div className="p-3.5 bg-rose-50 border border-rose-200 rounded-2xl flex items-start space-x-2.5 text-xs text-rose-800 animate-in fade-in">
            <AlertCircle className="w-4 h-4 shrink-0 text-rose-600 mt-0.5" />
            <span>{error}</span>
          </div>
        )}

        {/* Login Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold text-textMain mb-1.5">
              Admin Email Address
            </label>
            <div className="relative">
              <Mail className="w-4 h-4 text-textMuted absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="email"
                required
                placeholder="admin@sahyan.app"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full bg-surface pl-10 pr-4 py-2.5 text-xs rounded-xl border border-surface-subtle focus:outline-none focus:border-forest text-textMain font-medium"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-textMain mb-1.5">
              Secure Password
            </label>
            <div className="relative">
              <Lock className="w-4 h-4 text-textMuted absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="password"
                required
                placeholder="••••••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full bg-surface pl-10 pr-4 py-2.5 text-xs rounded-xl border border-surface-subtle focus:outline-none focus:border-forest text-textMain font-medium"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 bg-forest hover:bg-forest-dark text-white font-bold text-xs rounded-xl transition-all shadow-sm hover:shadow-md cursor-pointer flex items-center justify-center space-x-2"
          >
            <span>{loading ? 'Authenticating...' : 'Sign In to Admin OS'}</span>
            {!loading && <ArrowRight className="w-4 h-4" />}
          </button>
        </form>

        {/* Demo Credentials Quick-Fill */}
        <div className="pt-2 border-t border-surface-subtle">
          <button
            type="button"
            onClick={handleQuickFill}
            className="w-full py-2 px-3 rounded-xl border border-dashed border-gray-300 hover:border-forest text-textMuted hover:text-forest text-[11px] font-bold transition-colors cursor-pointer"
          >
            Fill Root Admin Credentials (admin@sahyan.app)
          </button>
        </div>

        <div className="text-center text-[11px] text-textMuted">
          Protected by SHA-256 JWT role validation and strict fail-closed authorization.
        </div>
      </div>
    </div>
  );
};
