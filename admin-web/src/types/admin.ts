export interface AdminStats {
  totalUsers?: number;
  verifiedDrivers?: number;
  pendingVerifications?: number;
  activeRides?: number;
  activeJourneys?: number;
  scheduledRides?: number;
  completedRides?: number;
  completedBookings?: number;
  totalCarbonSavedKg?: number;
  totalCo2SavedKg?: number;
  totalFuelSharedInr?: number;
  totalFuelSplit?: number;
  openReports?: number;
  safetyReports?: {
    pending: number;
    resolved: number;
    total: number;
  };
  serverStatus?: string;
  databaseConnected?: boolean;
  systemHealth?: {
    database: string;
    uptimeSeconds?: number;
    apiVersion?: string;
  };
}

export interface DriverProfile {
  onboardingStatus?: 'not_started' | 'in_progress' | 'submitted' | 'approved' | 'rejected';
  licenseNumber?: string;
  licenseDocUrl?: string;
  rcDocUrl?: string;
  idDocUrl?: string;
  rejectionReason?: string;
  verificationRejectionReason?: string;
  verifiedAt?: string;
}

export interface VehicleInfo {
  _id?: string;
  make?: string;
  model?: string;
  year?: number;
  registrationNumber?: string;
  vehicleType?: string;
  color?: string;
  seatCapacity?: number;
}

export interface UserItem {
  _id: string;
  name: string;
  email: string;
  phone: string;
  role: 'user' | 'admin';
  isVerified: boolean;
  city?: string;
  capabilities?: {
    canDrive?: boolean;
    canRide?: boolean;
  };
  rating?: number | { average?: number; count?: number };
  totalRides?: number;
  vehicle?: VehicleInfo | null;
  driverProfile?: DriverProfile;
  createdAt: string;
}

export interface RideItem {
  _id: string;
  driver?: {
    _id: string;
    name: string;
    phone?: string;
    email?: string;
    rating?: number;
    isVerified?: boolean;
  };
  vehicle?: VehicleInfo | null;
  origin?: {
    name: string;
    coordinates?: [number, number];
  };
  destination?: {
    name: string;
    coordinates?: [number, number];
  };
  departureTime?: string;
  status: 'scheduled' | 'boarding' | 'active' | 'completed' | 'cancelled';
  availableSeats?: number;
  totalSeats?: number;
  bookedSeats?: number;
  contributionPerSeat?: number;
  pricePerSeat?: number;
  pickupPolicy?: string;
  createdAt?: string;
  moderationReason?: string;
}

export interface ReportItem {
  _id: string;
  reporter?: {
    _id: string;
    name: string;
    phone?: string;
    email?: string;
  };
  reportedUser?: {
    _id: string;
    name: string;
    phone?: string;
    email?: string;
    role?: string;
  };
  ride?: {
    _id: string;
    origin?: { name: string };
    destination?: { name: string };
    departureTime?: string;
    status?: string;
  };
  type?: string;
  title?: string;
  category?: string;
  description: string;
  severity?: 'low' | 'medium' | 'high' | 'critical';
  priority?: 'low' | 'medium' | 'high' | 'critical';
  status: 'open' | 'investigating' | 'resolved' | 'dismissed' | 'pending';
  resolutionNotes?: string;
  resolvedBy?: {
    name?: string;
  };
  resolvedAt?: string;
  createdAt: string;
}

export interface BookingItem {
  _id: string;
  passenger?: {
    _id: string;
    name: string;
    phone?: string;
    email?: string;
  };
  ride?: {
    _id: string;
    origin?: { name: string };
    destination?: { name: string };
    departureTime?: string;
    driver?: {
      _id: string;
      name: string;
      phone?: string;
      email?: string;
      rating?: number;
    };
    status?: string;
    contributionPerSeat?: number;
  };
  requestedSeats: number;
  contributionPerSeat: number;
  totalContribution: number;
  status: 'pending' | 'accepted' | 'rejected' | 'cancelled' | 'completed';
  paymentStatus: 'pending' | 'paid' | 'escrow_released' | 'refunded';
  passengerNote?: string;
  pickup?: { name: string };
  drop?: { name: string };
  createdAt: string;
}

export interface AuthState {
  token: string | null;
  adminUser: {
    id: string;
    name: string;
    email: string;
    role: string;
  } | null;
  isAuthenticated: boolean;
}
