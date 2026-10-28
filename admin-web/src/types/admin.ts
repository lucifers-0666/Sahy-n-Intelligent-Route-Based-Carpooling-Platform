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
  role: 'user' | 'admin' | 'super_admin' | 'safety_officer' | 'support_lead';
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
  accountStatus?: 'active' | 'suspended';
  suspensionReason?: string;
  suspendedAt?: string;
  suspendedBy?: { _id?: string; name?: string; email?: string } | string | null;
  suspensionUpdatedAt?: string;
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

export interface AuditLogItem {
  _id: string;
  action: string;
  admin?: {
    _id: string;
    name: string;
    email: string;
  };
  targetUser?: {
    _id: string;
    name: string;
    email: string;
    phone?: string;
  } | null;
  reason: string;
  metadata?: Record<string, any>;
  createdAt: string;
}

export interface EmergencyContact {
  name: string;
  phone: string;
  relationship?: string;
  isPrimary?: boolean;
}

export interface SosIncident {
  incidentId: string;
  timestamp: string;
  passenger: {
    id: string;
    name: string;
    phone: string;
    email?: string;
    emergencyContacts?: EmergencyContact[];
  };
  driver?: {
    id: string;
    name: string;
    phone: string;
  } | null;
  ride?: {
    id: string;
    origin?: { name: string };
    destination?: { name: string };
    status?: string;
  } | null;
  location: {
    latitude: number;
    longitude: number;
    address: string;
  };
  status: 'open' | 'investigating' | 'resolved' | 'dismissed';
  severity: 'critical' | 'high' | 'medium' | 'low';
  resolutionNotes?: string;
}

export interface RevenueStats {
  totalFuelShared: number;
  monthlyFuelShared: number;
  weeklyFuelShared: number;
  escrowBalance?: number;
  settledToDrivers?: number;
  safetyFeePool?: number;
  gatewayStatus?: {
    razorpayWebhook?: string;
    bankPayoutApi?: string;
    latencyMs?: number;
    status?: string;
    lastPing?: string;
  };
  totalBookings: number;
  completedBookings: number;
  recentBookings: number;
  weeklyBookings: number;
  completionRate: number;
  co2SavedKg: number;
  totalUsers: number;
  newUsersMonth: number;
  totalRides: number;
  completedRides: number;
  monthlyTrend: Array<{
    _id: { year: number; month: number };
    bookings: number;
    fuelShared: number;
  }>;
}

export interface PlatformConfig {
  maxSeatsPerRide: number;
  maxContributionPerSeat: number;
  verificationRequired: boolean;
  safetyReportAutoEscalateHours: number;
  maxRideDistanceKm: number;
  defaultCarpoolCity: string;
  maintenanceMode: boolean;
  socketTelematicsEnabled: boolean;
  pushNotificationsEnabled: boolean;
  co2SavedKgPerBooking: number;
}

export interface FraudUser {
  _id: string;
  name: string;
  email: string;
  phone: string;
  role: string;
  accountStatus: 'active' | 'suspended';
  capabilities?: {
    canDrive?: boolean;
    canRide?: boolean;
    canBookCash?: boolean;
  };
  fraudMetrics?: {
    riskScore?: number;
    riskTier?: 'low' | 'medium' | 'high' | 'critical';
    unpaidReportsCount?: number;
    cancellationsCount?: number;
    disputesLostCount?: number;
  };
  rating?: number | { average?: number; count?: number };
  createdAt: string;
}

export interface DisputeCase {
  _id: string;
  passenger?: {
    _id: string;
    name: string;
    email: string;
    phone: string;
    rating?: number;
    fraudMetrics?: any;
  };
  ride?: {
    _id: string;
    origin?: { name: string };
    destination?: { name: string };
    departureTime?: string;
    status?: string;
    driver?: {
      _id: string;
      name: string;
      email: string;
      phone: string;
      rating?: number;
    };
  };
  totalContribution: number;
  status: string;
  paymentStatus: string;
  dispute?: {
    status: string;
    driverReportedAt?: string;
    driverReason?: string;
    driverEvidenceUrl?: string;
    passengerRespondedAt?: string;
    passengerResponse?: string;
    passengerProofUrl?: string;
    resolvedAt?: string;
    resolvedBy?: any;
    resolutionNotes?: string;
  };
  createdAt: string;
}

export interface UserAppeal {
  userId: string;
  userName: string;
  userPhone: string;
  accountStatus: string;
  canBookCash?: boolean;
  appealIndex: number;
  appealId?: string;
  reason: string;
  status: 'pending' | 'approved' | 'rejected';
  submittedAt: string;
  reviewedAt?: string;
  reviewerNotes?: string;
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

export interface SupportTicketMessage {
  _id?: string;
  sender: 'user' | 'admin';
  senderId: string;
  senderName: string;
  senderRole?: string;
  message: string;
  createdAt: string;
}

export interface SupportTicketItem {
  _id: string;
  ticketNumber: string;
  user: {
    _id: string;
    name: string;
    email: string;
    phone: string;
    rating?: number;
    isVerified?: boolean;
  };
  booking?: {
    _id: string;
    pickup?: { name: string };
    drop?: { name: string };
    status?: string;
    totalContribution?: number;
    departureTime?: string;
  } | null;
  ride?: {
    _id: string;
    origin?: { name: string };
    destination?: { name: string };
    departureTime?: string;
    status?: string;
  } | null;
  category: 'ride_issue' | 'payment_inquiry' | 'driver_behavior' | 'technical_bug' | 'account_access' | 'other';
  priority: 'low' | 'medium' | 'high' | 'urgent';
  status: 'open' | 'in_progress' | 'resolved' | 'closed';
  subject: string;
  description: string;
  messages: SupportTicketMessage[];
  assignedTo?: {
    _id: string;
    name: string;
    email: string;
    role?: string;
  } | null;
  resolutionNotes?: string | null;
  resolvedAt?: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface TransactionLedgerItem {
  _id: string;
  bookingId?: {
    _id: string;
    pickup?: { name: string };
    drop?: { name: string };
    departureTime?: string;
    seats?: number;
    status?: string;
    paymentStatus?: string;
    totalContribution?: number;
  };
  passengerId?: {
    _id: string;
    name: string;
    email?: string;
    phone?: string;
  };
  driverId?: {
    _id: string;
    name: string;
    email?: string;
    phone?: string;
  };
  amount: number;
  currency: string;
  platformFee: number;
  paymentMethod: string;
  isSandbox: boolean;
  status: 'pending' | 'escrow_held' | 'settled_to_driver' | 'refunded' | 'disputed' | 'failed';
  gatewayOrderId?: string;
  gatewayReference?: string;
  verifiedBy?: string;
  createdAt: string;
}

export interface SystemTelemetryData {
  serverTime: string;
  uptimeSeconds: number;
  database: {
    status: 'healthy' | 'degraded' | 'disconnected';
    readyState: number;
    latencyMs: number | null;
    host: string;
  };
  telematics: {
    activeSocketRooms: number;
    protocol: string;
    status: string;
  };
  services: {
    smsGateway: string;
    firebaseAuth: string;
    jwtSignature: boolean;
  };
  memory: {
    rssMb: number;
    heapUsedMb: number;
    heapTotalMb: number;
  };
}

