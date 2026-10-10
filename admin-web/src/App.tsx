import React from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import { LoginScreen } from './screens/LoginScreen';
import { DashboardScreen } from './screens/DashboardScreen';

const RootApp: React.FC = () => {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-screen bg-surface flex flex-col items-center justify-center p-4">
        <div className="w-12 h-12 rounded-2xl bg-forest text-white font-extrabold text-xl flex items-center justify-center animate-pulse">
          S
        </div>
        <p className="text-xs font-bold text-textMuted mt-3 tracking-wider uppercase">
          Initializing Sahyān Admin OS...
        </p>
      </div>
    );
  }

  return isAuthenticated ? <DashboardScreen /> : <LoginScreen />;
};

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <RootApp />
    </AuthProvider>
  );
};
export default App;
