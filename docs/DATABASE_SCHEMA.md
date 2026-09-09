# Database Schema Design — Sahyān

## MongoDB Collections & Schemas (Stabilized MCA Architecture)

---

## 1. Users Collection (`User.js`)

Stores user accounts, credentials, verification status, driver capability, and emergency contacts.

```javascript
{
  _id: ObjectId,
  name: String,                   // Required, trimmed (2-50 characters)
  email: String,                  // Unique, lowercase, indexed
  phone: String,                  // Unique, +91 formatted, indexed
  password: String,               // Hashed with bcryptjs (select: false)
  profileImage: String,
  city: String,                   // Default: 'Ahmedabad'
  isVerified: Boolean,            // Default: false (set to true upon successful OTP verification)
  isDriver: Boolean,              // Computed based on registered vehicle count
  role: String,                   // 'user' | 'admin' (default: 'user')
  bio: String,                    // Max 500 characters
  rating: {
    average: Number,              // Default: 4.8
    count: Number                 // Default: 0
  },
  emergencyContacts: [{
    _id: ObjectId,
    name: String,
    phone: String,
    relationship: String
  }],
  preferences: {
    notifications: Boolean,       // Default: true
    allowSmoking: Boolean,        // Default: false
    allowPets: Boolean            // Default: false
  },
  otpInfo: {
    code: String,                 // 6-digit cryptographic OTP
    expiresAt: Date,              // 10 minutes expiry
    attempts: Number,             // Max 5 requests per 10 min window
    verificationAttempts: Number, // Max 5 verification attempts
    lastRequestedAt: Date
  },
  resetPasswordInfo: {
    token: String,                // SHA256 hashed reset token
    expiresAt: Date               // 15 minutes expiry
  },
  createdAt: Date,
  updatedAt: Date
}
```

### Indexes:
- `{ email: 1 }` (unique)
- `{ phone: 1 }` (unique)

---

## 2. Vehicles Collection (`Vehicle.js`)

Stores vehicles registered by users for offering carpool rides.

```javascript
{
  _id: ObjectId,
  ownerId: ObjectId,              // Reference to User._id, indexed
  make: String,                   // e.g. 'Maruti', 'Hyundai', 'Tata'
  model: String,                  // e.g. 'Swift Dzire', 'Nexon'
  year: Number,                   // e.g. 2022
  color: String,                  // e.g. 'Silver', 'White'
  registrationNumber: String,     // Normalized uppercase without dashes/spaces, unique
  seatCapacity: Number,           // 1 to 8 seats
  vehicleType: String,            // 'sedan' | 'hatchback' | 'suv' | 'other'
  status: String,                 // 'active' | 'inactive' (default: 'active')
  createdAt: Date,
  updatedAt: Date
}
```

### Indexes:
- `{ ownerId: 1 }`
- `{ registrationNumber: 1 }` (unique)

---

## 3. Rides Collection (`Ride.js`)

Stores scheduled rides offered by drivers with origin, destination, Google Maps route polyline, seat allocation, and lifecycle states.

```javascript
{
  _id: ObjectId,
  driverId: ObjectId,             // Reference to User._id, indexed
  vehicleId: ObjectId,            // Reference to Vehicle._id
  origin: {
    address: String,              // Human-readable pickup location
    city: String,
    location: {
      type: 'Point',
      coordinates: [Number, Number] // GeoJSON [longitude, latitude]
    }
  },
  destination: {
    address: String,              // Human-readable dropoff location
    city: String,
    location: {
      type: 'Point',
      coordinates: [Number, Number] // GeoJSON [longitude, latitude]
    }
  },
  route: {
    encodedPolyline: String,      // Google Maps encoded polyline
    distanceMeters: Number,
    durationSeconds: Number
  },
  departureTime: Date,            // Scheduled departure timestamp
  availableSeats: Number,         // Currently unbooked seats
  totalSeats: Number,             // Initial capacity offered
  bookedSeats: Number,            // Number of confirmed seats
  contributionPerSeat: Number,    // Cost contribution in INR
  status: String,                 // 'scheduled' | 'boarding' | 'active' | 'completed' | 'cancelled'
  pickupPolicy: String,           // 'exact' | 'nearby' (default: 'nearby')
  amenities: [String],            // e.g. ['AC', 'Luggage Space', 'Music']
  notes: String,
  createdAt: Date,
  updatedAt: Date
}
```

### Indexes:
- `{ 'origin.location': '2dsphere' }`
- `{ 'destination.location': '2dsphere' }`
- `{ driverId: 1 }`
- `{ status: 1 }`
- `{ departureTime: 1 }`

---

## 4. Bookings Collection (`Booking.js`)

Tracks passenger seat reservations, pickup/dropoff points, fare contributions, and driver confirmation status.

```javascript
{
  _id: ObjectId,
  rideId: ObjectId,               // Reference to Ride._id, indexed
  passengerId: ObjectId,          // Reference to User._id, indexed
  driverId: ObjectId,             // Reference to User._id, indexed
  seatsBooked: Number,            // Number of seats requested (1 to availableSeats)
  totalContribution: Number,      // contributionPerSeat * seatsBooked
  status: String,                 // 'pending' | 'accepted' | 'rejected' | 'cancelled' | 'completed'
  pickupLocation: {
    address: String,
    coordinates: [Number, Number] // [longitude, latitude]
  },
  dropoffLocation: {
    address: String,
    coordinates: [Number, Number] // [longitude, latitude]
  },
  cancellationReason: String,
  createdAt: Date,
  updatedAt: Date
}
```

### Indexes:
- `{ rideId: 1 }`
- `{ passengerId: 1 }`
- `{ driverId: 1 }`
- `{ status: 1 }`

---

**Document Version**: 3.0 (Stabilized Architecture)  
**Last Updated**: September 2026
