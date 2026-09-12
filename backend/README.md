# Sahyān / RouteShare — Backend API (Phase 1 MVP)

Backend REST API for **Sahyān / RouteShare**, an Intelligent Route-Based Carpooling Platform.

## Stack Overview

- **Runtime**: Node.js (v18+)
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT (JSON Web Tokens) with bcrypt password hashing
- **Testing**: Node.js Native Test Runner (`node:test`, `node:assert`) + `mongodb-memory-server`

---

## Getting Started

### 1. Prerequisites

- Node.js (v18.x or later)
- MongoDB instance (Local MongoDB or MongoDB Atlas)
- npm (v9+)

### 2. Installation

Navigate to the `backend/` directory and install dependencies:

```bash
cd backend
npm install
```

### 3. Environment Configuration

Create a `.env` file from the provided `.env.example`:

```bash
cp .env.example .env
```

Configure your environment variables:

| Variable | Description | Example |
| :--- | :--- | :--- |
| `PORT` | Server listening port | `5000` |
| `NODE_ENV` | Environment mode | `development` / `production` |
| `MONGODB_URI` | MongoDB connection URI | `mongodb://127.0.0.1:27017/sahyan` |
| `JWT_SECRET` | Secret key for JWT signing | `your_secure_random_jwt_secret_key_here` |
| `JWT_EXPIRES_IN` | JWT token expiry | `7d` |
| `GOOGLE_MAPS_API_KEY` | Google Maps API Key for routing | `your_google_maps_api_key_here` |

### 4. Running the Server

#### Development Mode (with hot-reload):
```bash
npm run dev
```

#### Production Mode:
```bash
npm start
```

### 5. Running Automated Tests

Run the full suite of automated tests:

```bash
npm test
```

Or run the dedicated Phase 1 Core MVP test suite:

```bash
node --test test/phase1_mvp.test.js
```

---

## Health Check

Verify the API status:

- **Endpoint**: `GET /api/health` (also mounted at `GET /api/v1/health`)
- **Sample Response**:

```json
{
  "success": true,
  "message": "RouteShare API is running",
  "status": "OK",
  "service": "Sahyān Carpooling API Server",
  "version": "1.0.0",
  "data": {
    "environment": "development"
  },
  "timestamp": "2026-09-12T15:00:00.000Z"
}
```

---

## Core API Endpoints

All endpoints are dual-mounted under `/api` and `/api/v1` for seamless backwards compatibility.

### 1. Authentication (`/api/auth`)

| Method | Endpoint | Access | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/register` | Public | Register new user (validates email, phone, password policy) |
| `POST` | `/api/auth/login` | Public | Login with email/phone & password, returns JWT and user profile |
| `GET` | `/api/auth/me` | Authenticated | Retrieve authenticated user profile without sensitive fields |
| `POST` | `/api/auth/send-otp` | Public | Generate and send cryptographic OTP |
| `POST` | `/api/auth/verify-otp` | Public | Verify OTP and activate mobile verification |

### 2. Vehicle Management (`/api/vehicles`)

| Method | Endpoint | Access | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/vehicles` | Driver | Register a new vehicle & activate driver capability |
| `GET` | `/api/vehicles` | Driver | Get all vehicles owned by the authenticated driver |
| `GET` | `/api/vehicles/:id` | Driver (Owner) | Get details of a specific vehicle |
| `PUT`/`PATCH` | `/api/vehicles/:id` | Driver (Owner) | Update vehicle details |
| `DELETE` | `/api/vehicles/:id` | Driver (Owner) | Delete vehicle (blocked if active scheduled ride exists) |

### 3. Ride Management & Search (`/api/rides`)

| Method | Endpoint | Access | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/rides` | Driver | Create / offer a new carpooling ride |
| `GET` | `/api/rides` | Public / Optional | List upcoming scheduled rides with pagination & filters |
| `GET` | `/api/rides/my-rides` | Driver | Get all rides created by the authenticated driver |
| `GET` | `/api/rides/:id` | Public | Get single ride details with populated driver and vehicle |
| `PUT`/`PATCH` | `/api/rides/:id` | Driver (Owner) | Update scheduled ride details |
| `DELETE` | `/api/rides/:id` | Driver (Owner) | Cancel a scheduled ride and release bookings |
| `GET` | `/api/rides/search` | Public / Optional | Search upcoming rides by proximity, polyline overlap & seats |

### 4. Booking Workflow & Concurrency (`/api/bookings`)

| Method | Endpoint | Access | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/bookings` | Passenger | Create pending booking request (atomically reserves seats) |
| `GET` | `/api/bookings/my-bookings` | Passenger | List all bookings requested by authenticated passenger |
| `GET` | `/api/bookings/:id` | Passenger/Driver | Get detailed booking information |
| `GET` | `/api/bookings/driver/requests` | Driver | View incoming booking requests across driver's offered rides |
| `PATCH` | `/api/bookings/:id/status` | Driver (Owner) | Accept (`confirmed`/`accepted`) or reject (`rejected`) request |
| `PATCH` | `/api/bookings/:id/cancel` | Passenger/Driver | Cancel a pending or confirmed booking, restoring seats |

---

## Seat Capacity & Integrity Model

To eliminate double-booking race conditions in concurrent traffic, Sahyān employs the **Request-Reservation Model**:

1. **Pending Booking Request**:
   - `availableSeats` on the ride is decremented atomically via conditional MongoDB update (`availableSeats: { $gte: seats }`).
   - If available seats are insufficient, the request is rejected with `409 Conflict`.
2. **Booking Approval**:
   - When the driver confirms/accepts a booking, `bookedSeats` is incremented.
   - `availableSeats` is **not** decremented a second time.
3. **Booking Cancellation / Rejection**:
   - If a pending request is rejected or cancelled, the reserved seats are returned to `availableSeats`.
   - If a confirmed booking is cancelled, `availableSeats` is restored and `bookedSeats` is decremented.
   - Seat counts are strictly bounded (`0 <= availableSeats <= totalSeats`).

---

## Postman Collection

A complete Postman collection and environment template are included:

- **Collection**: `postman/RouteShare-Phase-1.postman_collection.json`
- **Environment Example**: `postman/RouteShare-Phase-1.postman_environment.json.example`

### To Run in Postman:
1. Import `postman/RouteShare-Phase-1.postman_collection.json`.
2. Import `postman/RouteShare-Phase-1.postman_environment.json.example` as a new environment.
3. Start the server (`npm run dev`).
4. Run requests in sequential order (Registration -> Login -> Vehicle -> Ride -> Search -> Booking -> Confirm -> Cancel).

---

## Phase 1 Limitations (Deferred to Phase 2)

The following advanced features are deliberately out of scope for Phase 1 MVP stabilization and deferred to Phase 2:

1. **Digital Payments & Escrow**: Payment gateway integration (Razorpay / Stripe) and automated driver payouts.
2. **Real-Time GPS Tracking**: WebSockets / Socket.io live driver location broadcast on map.
3. **In-App Messaging**: Real-time driver-passenger socket chat.
4. **Push Notifications**: Firebase Cloud Messaging (FCM) push notifications.
5. **Admin Moderation Dashboard**: Superuser role-based access control, analytics dashboard, and identity document approval queues.
6. **External SMS Gateway**: Third-party SMS gateway (Twilio / MSG91); in Phase 1 cryptographic OTP is verified server-side.
