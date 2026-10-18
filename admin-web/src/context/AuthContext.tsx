import React, { createContext, useContext, useState, useEffect } from 'react';
import { adminApi } from '../services/api';

interface AdminUser {
  id: string;
  name: string;
  email: string;
  role: string;
}

interface AuthContextType {
  user: AdminUser | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<AdminUser | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const savedToken = localStorage.getItem('sahyan_admin_token');
    const savedUserStr = localStorage.getItem('sahyan_admin_user');

    if (savedToken && savedUserStr) {
      try {
        const savedUser = JSON.parse(savedUserStr);
        const ADMIN_ROLES = ['admin', 'super_admin', 'safety_officer', 'support_lead'];
        if (ADMIN_ROLES.includes(savedUser.role)) {
          setToken(savedToken);
          setUser(savedUser);
        } else {
          localStorage.removeItem('sahyan_admin_token');
          localStorage.removeItem('sahyan_admin_user');
        }
      } catch {
        localStorage.removeItem('sahyan_admin_token');
        localStorage.removeItem('sahyan_admin_user');
      }
    }
    setIsLoading(false);
  }, []);

  const login = async (email: string, password: string) => {
    const data = await adminApi.login(email, password);
    const adminUser: AdminUser = {
      id: data.user._id,
      name: data.user.name,
      email: data.user.email,
      role: data.user.role,
    };

    localStorage.setItem('sahyan_admin_token', data.token);
    localStorage.setItem('sahyan_admin_user', JSON.stringify(adminUser));
    setToken(data.token);
    setUser(adminUser);
  };

  const logout = () => {
    localStorage.removeItem('sahyan_admin_token');
    localStorage.removeItem('sahyan_admin_user');
    setToken(null);
    setUser(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isAuthenticated: !!token && !!user,
        isLoading,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
