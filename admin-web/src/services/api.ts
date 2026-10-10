import { AdminStats, UserItem, RideItem, ReportItem, BookingItem } from '../types/admin';

const BASE_URL = '/api/v1';

export class ApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

function getAuthHeader(): Record<string, string> {
  const token = localStorage.getItem('sahyan_admin_token');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

async function handleResponse<T>(res: Response): Promise<T> {
  if (!res.ok) {
    let errorMsg = 'An error occurred';
    try {
      const data = await res.json();
      errorMsg = data.message || data.error || errorMsg;
    } catch {
      errorMsg = res.statusText || errorMsg;
    }
    throw new ApiError(errorMsg, res.status);
  }
  const json = await res.json();
  return json.data !== undefined ? json.data : json;
}

export const adminApi = {
  async login(email: string, password: string) {
    const res = await fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    const data = await handleResponse<{
      token: string;
      user: { _id: string; name: string; email: string; role: string };
    }>(res);

    if (data.user.role !== 'admin') {
      throw new ApiError('Access denied. Administrator privileges required.', 403);
    }
    return data;
  },

  async getStats(): Promise<AdminStats> {
    const res = await fetch(`${BASE_URL}/admin/stats`, {
      headers: { ...getAuthHeader() },
    });
    return handleResponse<AdminStats>(res);
  },

  async getUsers(params?: { status?: string; search?: string; page?: number; limit?: number }): Promise<UserItem[]> {
    const searchParams = new URLSearchParams();
    if (params?.status) searchParams.set('status', params.status);
    if (params?.search) searchParams.set('search', params.search);
    if (params?.page) searchParams.set('page', String(params.page));
    searchParams.set('limit', String(params?.limit || 100));

    const query = searchParams.toString() ? `?${searchParams.toString()}` : '';
    const res = await fetch(`${BASE_URL}/admin/users${query}`, {
      headers: { ...getAuthHeader() },
    });
    const payload = await handleResponse<any>(res);
    if (Array.isArray(payload)) return payload;
    if (payload && Array.isArray(payload.users)) return payload.users;
    return [];
  },

  async verifyDriver(userId: string, action: 'approve' | 'reject', reason?: string): Promise<UserItem> {
    const status = action === 'approve' ? 'approved' : 'rejected';
    const res = await fetch(`${BASE_URL}/admin/users/${userId}/verify`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        ...getAuthHeader(),
      },
      body: JSON.stringify({ status, reason: reason || '' }),
    });
    const payload = await handleResponse<any>(res);
    return payload?.user || payload;
  },

  async getRides(params?: { status?: string; search?: string }): Promise<RideItem[]> {
    const searchParams = new URLSearchParams();
    if (params?.status && params.status !== 'all') searchParams.set('status', params.status);
    if (params?.search) searchParams.set('search', params.search);
    searchParams.set('limit', '100');

    const query = searchParams.toString() ? `?${searchParams.toString()}` : '';
    const res = await fetch(`${BASE_URL}/admin/rides${query}`, {
      headers: { ...getAuthHeader() },
    });
    const payload = await handleResponse<any>(res);
    if (Array.isArray(payload)) return payload;
    if (payload && Array.isArray(payload.rides)) return payload.rides;
    return [];
  },

  async moderateRide(rideId: string, action: 'cancel', reason: string): Promise<RideItem> {
    const res = await fetch(`${BASE_URL}/admin/rides/${rideId}/moderate`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        ...getAuthHeader(),
      },
      body: JSON.stringify({ action, reason }),
    });
    const payload = await handleResponse<any>(res);
    return payload?.ride || payload;
  },

  async getReports(params?: { status?: string; type?: string }): Promise<ReportItem[]> {
    const searchParams = new URLSearchParams();
    if (params?.status && params.status !== 'all') searchParams.set('status', params.status);
    if (params?.type) searchParams.set('type', params.type);
    searchParams.set('limit', '100');

    const query = searchParams.toString() ? `?${searchParams.toString()}` : '';
    const res = await fetch(`${BASE_URL}/admin/reports${query}`, {
      headers: { ...getAuthHeader() },
    });
    const payload = await handleResponse<any>(res);
    if (Array.isArray(payload)) return payload;
    if (payload && Array.isArray(payload.reports)) return payload.reports;
    return [];
  },

  async resolveReport(reportId: string, status: 'resolved' | 'dismissed' | 'investigating', notes: string): Promise<ReportItem> {
    const res = await fetch(`${BASE_URL}/admin/reports/${reportId}/resolve`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        ...getAuthHeader(),
      },
      body: JSON.stringify({ status, notes }),
    });
    const payload = await handleResponse<any>(res);
    return payload?.report || payload;
  },

  async getBookings(params?: { status?: string; paymentStatus?: string }): Promise<BookingItem[]> {
    const searchParams = new URLSearchParams();
    if (params?.status && params.status !== 'all') searchParams.set('status', params.status);
    if (params?.paymentStatus && params.paymentStatus !== 'all') searchParams.set('paymentStatus', params.paymentStatus);
    searchParams.set('limit', '100');

    const query = searchParams.toString() ? `?${searchParams.toString()}` : '';
    const res = await fetch(`${BASE_URL}/admin/bookings${query}`, {
      headers: { ...getAuthHeader() },
    });
    const payload = await handleResponse<any>(res);
    if (Array.isArray(payload)) return payload;
    if (payload && Array.isArray(payload.bookings)) return payload.bookings;
    return [];
  },
};
