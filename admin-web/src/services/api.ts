import {
  AdminStats,
  UserItem,
  RideItem,
  ReportItem,
  BookingItem,
  AuditLogItem,
  RevenueStats,
  PlatformConfig,
} from '../types/admin';

export const BASE_URL = (import.meta as any).env?.VITE_API_URL || '/api/v1';
export const SOCKET_URL =
  (import.meta as any).env?.VITE_SOCKET_URL ||
  (typeof window !== 'undefined' ? window.location.origin : 'http://127.0.0.1:5000');

export class ApiError extends Error {
  status: number;
  data?: any;
  constructor(message: string, status: number, data?: any) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.data = data;
  }
}

function getAuthHeader(): Record<string, string> {
  const token = typeof window !== 'undefined' ? localStorage.getItem('sahyan_admin_token') : null;
  return token ? { Authorization: `Bearer ${token}` } : {};
}

async function requestWithTimeout<T>(
  url: string,
  options: RequestInit = {},
  timeoutMs: number = 15000
): Promise<T> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const res = await fetch(url, {
      ...options,
      signal: controller.signal,
      headers: {
        'Accept': 'application/json',
        ...getAuthHeader(),
        ...(options.headers || {}),
      },
    });

    clearTimeout(timeoutId);

    if (!res.ok) {
      if (res.status === 401) {
        if (typeof window !== 'undefined') {
          localStorage.removeItem('sahyan_admin_token');
          localStorage.removeItem('sahyan_admin_user');
          window.dispatchEvent(new CustomEvent('sahyan_auth_expired'));
        }
        throw new ApiError('Your administrative session has expired. Please sign in again.', 401);
      }

      let errorMsg = `Server error (${res.status})`;
      let errorData: any = null;
      try {
        errorData = await res.json();
        errorMsg = errorData.message || errorData.error || errorMsg;
      } catch {
        errorMsg = res.statusText || errorMsg;
      }
      throw new ApiError(errorMsg, res.status, errorData);
    }

    const json = await res.json();
    return json.data !== undefined ? json.data : json;
  } catch (err: any) {
    clearTimeout(timeoutId);
    if (err.name === 'AbortError') {
      throw new ApiError('Request timed out. The backend server took too long to respond.', 408);
    }
    if (err instanceof ApiError) {
      throw err;
    }
    throw new ApiError(
      err.message || 'Unable to connect to the Sahyān backend API service.',
      0
    );
  }
}

export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  pages: number;
  limit: number;
}

export const adminApi = {
  async login(email: string, password: string) {
    const data = await requestWithTimeout<{
      token: string;
      user: { _id: string; name: string; email: string; role: string };
    }>(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });

    const ADMIN_ROLES = ['admin', 'super_admin', 'safety_officer', 'support_lead'];
    if (!ADMIN_ROLES.includes(data.user.role)) {
      throw new ApiError('Access denied. Administrator privileges required.', 403);
    }
    return data;
  },

  async getStats(): Promise<AdminStats> {
    return requestWithTimeout<AdminStats>(`${BASE_URL}/admin/stats`);
  },

  async getUsers(params?: {
    status?: string;
    search?: string;
    page?: number;
    limit?: number;
  }): Promise<UserItem[]> {
    const searchParams = new URLSearchParams();
    if (params?.status) searchParams.set('status', params.status);
    if (params?.search) searchParams.set('search', params.search);
    if (params?.page) searchParams.set('page', String(params.page));
    searchParams.set('limit', String(params?.limit || 100));

    const query = searchParams.toString() ? `?${searchParams.toString()}` : '';
    const payload = await requestWithTimeout<any>(`${BASE_URL}/admin/users${query}`);
    if (Array.isArray(payload)) return payload;
    if (payload && Array.isArray(payload.users)) return payload.users;
    return [];
  },

  async getUsersPaginated(params?: {
    status?: string;
    search?: string;
    page?: number;
    limit?: number;
  }): Promise<PaginatedResult<UserItem>> {
    const searchParams = new URLSearchParams();
    if (params?.status) searchParams.set('status', params.status);
    if (params?.search) searchParams.set('search', params.search);
    searchParams.set('page', String(params?.page || 1));
    searchParams.set('limit', String(params?.limit || 20));

    const query = searchParams.toString() ? `?${searchParams.toString()}` : '';
    const payload = await requestWithTimeout<any>(`${BASE_URL}/admin/users${query}`);
    const items = Array.isArray(payload) ? payload : (payload?.users || []);
    const pagination = payload?.pagination || {};
    return {
      items,
      total: pagination.total ?? items.length,
      page: pagination.page ?? (params?.page || 1),
      pages: pagination.pages ?? 1,
      limit: pagination.limit ?? (params?.limit || 20),
    };
  },

  async verifyDriver(userId: string, action: 'approve' | 'reject', reason?: string): Promise<UserItem> {
    const status = action === 'approve' ? 'approved' : 'rejected';
    const payload = await requestWithTimeout<any>(`${BASE_URL}/admin/users/${userId}/verify`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status, reason: reason || '' }),
    });
    return payload?.user || payload;
  },

  async suspendDriver(userId: string, reason: string): Promise<UserItem> {
    const payload = await requestWithTimeout<any>(`${BASE_URL}/admin/users/${userId}/suspend`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ reason }),
    });
    return payload?.data?.user || payload?.user || payload;
  },

  async reactivateDriver(userId: string, reason?: string): Promise<UserItem> {
    const payload = await requestWithTimeout<any>(`${BASE_URL}/admin/users/${userId}/reactivate`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ reason: reason || 'Reactivated by administrator' }),
    });
    return payload?.data?.user || payload?.user || payload;
  },

  async getRides(params?: {
    status?: string;
    search?: string;
    page?: number;
    limit?: number;
  }): Promise<RideItem[]> {
    const searchParams = new URLSearchParams();
    if (params?.status && params.status !== 'all') searchParams.set('status', params.status);
    if (params?.search) searchParams.set('search', params.search);
    if (params?.page) searchParams.set('page', String(params.page));
    searchParams.set('limit', String(params?.limit || 100));

    const query = searchParams.toString() ? `?${searchParams.toString()}` : '';
    const payload = await requestWithTimeout<any>(`${BASE_URL}/admin/rides${query}`);
    if (Array.isArray(payload)) return payload;
    if (payload && Array.isArray(payload.rides)) return payload.rides;
    return [];
  },

  async getRidesPaginated(params?: {
    status?: string;
    search?: string;
    page?: number;
    limit?: number;
  }): Promise<PaginatedResult<RideItem>> {
    const searchParams = new URLSearchParams();
    if (params?.status && params.status !== 'all') searchParams.set('status', params.status);
    if (params?.search) searchParams.set('search', params.search);
    searchParams.set('page', String(params?.page || 1));
    searchParams.set('limit', String(params?.limit || 20));

    const query = searchParams.toString() ? `?${searchParams.toString()}` : '';
    const payload = await requestWithTimeout<any>(`${BASE_URL}/admin/rides${query}`);
    const items = Array.isArray(payload) ? payload : (payload?.rides || []);
    const pagination = payload?.pagination || {};
    return {
      items,
      total: pagination.total ?? items.length,
      page: pagination.page ?? (params?.page || 1),
      pages: pagination.pages ?? 1,
      limit: pagination.limit ?? (params?.limit || 20),
    };
  },

  async moderateRide(rideId: string, action: 'cancel', reason: string): Promise<RideItem> {
    const payload = await requestWithTimeout<any>(`${BASE_URL}/admin/rides/${rideId}/moderate`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action, reason }),
    });
    return payload?.ride || payload;
  },

  async getReports(params?: {
    status?: string;
    type?: string;
    page?: number;
    limit?: number;
  }): Promise<ReportItem[]> {
    const searchParams = new URLSearchParams();
    if (params?.status && params.status !== 'all') searchParams.set('status', params.status);
    if (params?.type) searchParams.set('type', params.type);
    if (params?.page) searchParams.set('page', String(params.page));
    searchParams.set('limit', String(params?.limit || 100));

    const query = searchParams.toString() ? `?${searchParams.toString()}` : '';
    const payload = await requestWithTimeout<any>(`${BASE_URL}/admin/reports${query}`);
    if (Array.isArray(payload)) return payload;
    if (payload && Array.isArray(payload.reports)) return payload.reports;
    return [];
  },

  async resolveReport(
    reportId: string,
    status: 'resolved' | 'dismissed' | 'investigating',
    notes: string
  ): Promise<ReportItem> {
    const payload = await requestWithTimeout<any>(`${BASE_URL}/admin/reports/${reportId}/resolve`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status, notes }),
    });
    return payload?.report || payload;
  },

  async getBookings(params?: {
    status?: string;
    paymentStatus?: string;
    page?: number;
    limit?: number;
  }): Promise<BookingItem[]> {
    const searchParams = new URLSearchParams();
    if (params?.status && params.status !== 'all') searchParams.set('status', params.status);
    if (params?.paymentStatus && params.paymentStatus !== 'all') {
      searchParams.set('paymentStatus', params.paymentStatus);
    }
    if (params?.page) searchParams.set('page', String(params.page));
    searchParams.set('limit', String(params?.limit || 100));

    const query = searchParams.toString() ? `?${searchParams.toString()}` : '';
    const payload = await requestWithTimeout<any>(`${BASE_URL}/admin/bookings${query}`);
    if (Array.isArray(payload)) return payload;
    if (payload && Array.isArray(payload.bookings)) return payload.bookings;
    return [];
  },

  async getBookingsPaginated(params?: {
    status?: string;
    paymentStatus?: string;
    page?: number;
    limit?: number;
  }): Promise<PaginatedResult<BookingItem>> {
    const searchParams = new URLSearchParams();
    if (params?.status && params.status !== 'all') searchParams.set('status', params.status);
    if (params?.paymentStatus && params.paymentStatus !== 'all') {
      searchParams.set('paymentStatus', params.paymentStatus);
    }
    searchParams.set('page', String(params?.page || 1));
    searchParams.set('limit', String(params?.limit || 20));

    const query = searchParams.toString() ? `?${searchParams.toString()}` : '';
    const payload = await requestWithTimeout<any>(`${BASE_URL}/admin/bookings${query}`);
    const items = Array.isArray(payload) ? payload : (payload?.bookings || []);
    const pagination = payload?.pagination || {};
    return {
      items,
      total: pagination.total ?? items.length,
      page: pagination.page ?? (params?.page || 1),
      pages: pagination.pages ?? 1,
      limit: pagination.limit ?? (params?.limit || 20),
    };
  },

  async getAuditLogs(params?: {
    page?: number;
    limit?: number;
    action?: string;
  }): Promise<{ logs: AuditLogItem[]; total: number; totalPages: number; page: number }> {
    const searchParams = new URLSearchParams();
    if (params?.page) searchParams.set('page', String(params.page));
    if (params?.limit) searchParams.set('limit', String(params.limit));
    if (params?.action && params.action !== 'all') searchParams.set('action', params.action);

    const query = searchParams.toString() ? `?${searchParams.toString()}` : '';
    return requestWithTimeout<{ logs: AuditLogItem[]; total: number; totalPages: number; page: number }>(
      `${BASE_URL}/admin/audit-logs${query}`
    );
  },

  async getRevenueStats(): Promise<RevenueStats> {
    return requestWithTimeout<RevenueStats>(`${BASE_URL}/admin/revenue-stats`);
  },

  async getPlatformConfig(): Promise<PlatformConfig> {
    return requestWithTimeout<PlatformConfig>(`${BASE_URL}/admin/config`);
  },

  async updatePlatformConfig(updates: Partial<PlatformConfig> & { reason?: string }): Promise<PlatformConfig> {
    return requestWithTimeout<PlatformConfig>(`${BASE_URL}/admin/config`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updates),
    });
  },

  async unmaskPii(
    resourceId: string,
    fieldName: string,
    reason: string
  ): Promise<{ resourceId: string; fieldName: string; unmaskedValue: any }> {
    return requestWithTimeout<{ resourceId: string; fieldName: string; unmaskedValue: any }>(
      `${BASE_URL}/admin/audit/unmask-pii`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ resourceId, fieldName, reason }),
      }
    );
  },

  async forceRefundBooking(bookingId: string, reason: string): Promise<any> {
    return requestWithTimeout<any>(`${BASE_URL}/admin/bookings/${bookingId}/force-refund`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ reason }),
    });
  },

  async getDisputeCases(params?: {
    status?: string;
    page?: number;
    limit?: number;
    search?: string;
  }): Promise<{ data: any[]; total: number; page: number; totalPages: number }> {
    const searchParams = new URLSearchParams();
    if (params?.status && params.status !== 'all') searchParams.set('status', params.status);
    if (params?.page) searchParams.set('page', String(params.page));
    if (params?.limit) searchParams.set('limit', String(params.limit));
    if (params?.search) searchParams.set('search', params.search);

    const query = searchParams.toString() ? `?${searchParams.toString()}` : '';
    const res = await requestWithTimeout<any>(`${BASE_URL}/admin/disputes${query}`);
    return {
      data: Array.isArray(res) ? res : (res?.data || []),
      total: res?.total || (Array.isArray(res) ? res.length : 0),
      page: res?.page || (params?.page || 1),
      totalPages: res?.totalPages || 1,
    };
  },

  async resolveDisputeCase(bookingId: string, resolution: string, notes?: string): Promise<any> {
    return requestWithTimeout<any>(`${BASE_URL}/admin/disputes/${bookingId}/resolve`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ resolution, notes: notes || '' }),
    });
  },

  async getUserAppeals(): Promise<any[]> {
    const payload = await requestWithTimeout<any>(`${BASE_URL}/admin/appeals`);
    return Array.isArray(payload) ? payload : [];
  },

  async reviewUserAppeal(
    userId: string,
    appealIndex: number,
    action: 'approve' | 'reject',
    reviewerNotes?: string
  ): Promise<any> {
    return requestWithTimeout<any>(`${BASE_URL}/admin/appeals/${userId}/${appealIndex}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action, reviewerNotes: reviewerNotes || '' }),
    });
  },

  async getFraudRiskSignals(params?: {
    riskTier?: string;
    page?: number;
    limit?: number;
  }): Promise<{ data: any[]; total: number; page: number; totalPages: number }> {
    const searchParams = new URLSearchParams();
    if (params?.riskTier && params.riskTier !== 'all') searchParams.set('riskTier', params.riskTier);
    if (params?.page) searchParams.set('page', String(params.page));
    if (params?.limit) searchParams.set('limit', String(params.limit));

    const query = searchParams.toString() ? `?${searchParams.toString()}` : '';
    const res = await requestWithTimeout<any>(`${BASE_URL}/admin/fraud/signals${query}`);
    return {
      data: Array.isArray(res) ? res : (res?.data || []),
      total: res?.total || (Array.isArray(res) ? res.length : 0),
      page: res?.page || (params?.page || 1),
      totalPages: res?.totalPages || 1,
    };
  },

  // Developer aliases
  getDisputes(params?: any) {
    return this.getDisputeCases(params);
  },
  resolveDispute(bookingId: string, resolution: string, notes?: string) {
    return this.resolveDisputeCase(bookingId, resolution, notes);
  },
  getFraudSignals(params?: any) {
    return this.getFraudRiskSignals(params);
  },
  getAppeals() {
    return this.getUserAppeals();
  },
  reviewAppeal(userId: string, appealIndex: number, action: 'approve' | 'reject', reviewerNotes?: string) {
    return this.reviewUserAppeal(userId, appealIndex, action, reviewerNotes);
  },
};

