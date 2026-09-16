# Sahyān (सह्यान) — Intelligent Route-Based Carpooling Platform

[![Backend Test Suite](https://img.shields.io/badge/Backend%20Tests-192%20Passed-2EC486?style=flat-square&logo=node.js)](backend/)
[![Frontend Test Suite](https://img.shields.io/badge/Frontend%20Tests-353%20Passed-2EC486?style=flat-square&logo=flutter)](frontend/)
[![Dart Analyzer](https://img.shields.io/badge/Dart%20Analyzer-0%20Issues-brightgreen?style=flat-square&logo=dart)](frontend/)
[![Architecture](https://img.shields.io/badge/Architecture-REST%20%2B%20Socket.IO%20%2B%20Escrow-1B4D3E?style=flat-square)](docs/PROJECT_REPORT.md)

**Sahyān (सह्यान)** is an enterprise-grade, peer-to-peer route-based carpooling platform connecting drivers travelling on planned routes with passengers along the same corridors. By sharing unoccupied seats, users significantly reduce commute expenses and carbon footprints without commercial taxi exploitation.

---

## 🌟 Key Features & Capabilities

- 🛣️ **Intelligent Route Matching Engine**: Polyline geometry calculations and Haversine cross-track algorithms evaluating candidate pickup/drop overlaps with explainable match grades.
- 📍 **Real-Time GPS Telematics**: Low-latency vehicle telemetry streaming (0.25 Hz) over ride-specific Socket.IO rooms with bearing rotation and dynamic ETA recalculations.
- 🔒 **Atomic Seat Inventory**: MongoDB ACID transactions preventing overbooking and race conditions during simultaneous passenger requests.
- 💳 **Escrow Payment Sandbox**: Seamless contribution checkout splitting base fares, platform safety fees, and FASTag toll allocations with automated driver settlement upon trip completion.
- 🎫 **Digital Boarding Pass**: 4-digit cryptographically verified PIN handshake between passenger and driver before trip departure.
- 🛡️ **Comprehensive Safety Center**: One-touch Emergency SOS triggers, trusted contact management, and driver KYC validation.
- 💬 **In-App Messaging & Reviews**: Contextual conversation channels per booking and bilateral star rating aggregation.
- 🖥️ **Web Admin Moderation Dashboard**: Real-time moderation portal for user document verification, ride auditing, and dispute resolution.

---

## 🏗️ Technology Stack

| Layer | Technologies |
|---|---|
| **Mobile Client** | Flutter 3.x, Dart, Riverpod State Management, GoRouter, Google Maps Flutter |
| **Backend Core** | Node.js, Express.js REST API, Socket.IO Real-Time Engine, JWT, bcryptjs |
| **Database** | MongoDB Atlas with GeoJSON 2dsphere Geospatial Indexing, Mongoose ODM |
| **Design System** | Sahyān *Luxury Light Theme* (Deep Pine `#1B4D3E`, Mint `#2EC486`, Organic Canvas `#F6F8F6`) |

---

## 📁 Repository Structure

```
Sahyān_MCA_APP/
├── backend/                   # Node.js & Express.js REST + Socket.IO Server
│   ├── src/
│   │   ├── config/            # Database & JWT configurations
│   │   ├── controllers/       # Auth, Rides, Bookings, Vehicles, Payments, Admin
│   │   ├── middleware/        # Authentication, Validation & Error Handlers
│   │   ├── models/            # User, Vehicle, Ride, Booking, Payment, Message, Review
│   │   ├── routes/            # REST API route definitions
│   │   ├── services/          # Route Match & Google Maps integration
│   │   └── utils/             # Polyline & Geometric utilities
│   └── test/                  # 192 Automated Unit & Integration Tests
│
├── frontend/                  # Flutter Cross-Platform Mobile Application
│   ├── lib/
│   │   ├── app/               # Router, Theme & Global Providers
│   │   ├── core/              # Network (ApiClient, SocketClient), Telemetry & Design System
│   │   ├── features/          # Auth, Rides, Bookings, Payments, Messages, Safety, Admin
│   │   └── shared/            # Bento Grid Widgets, Maps, Status Badges & Cards
│   └── test/                  # 353 Widget, Layout, Telematics & Payment Tests
│
└── docs/                      # Comprehensive Academic Project Documentation & Report
```

---

## 🚀 Quick Start Guide

### Prerequisites
- Node.js (v18+) & npm
- Flutter SDK (3.24+) & Dart SDK
- MongoDB instance (Local or Atlas URI)

### 1. Backend Setup & Tests
```bash
cd backend
npm install
cp .env.example .env
npm run dev

# Run all 192 automated backend tests
npm test
```

### 2. Frontend Setup & Build
```bash
cd frontend
flutter pub get

# Verify 0 analyzer issues
dart analyze lib test

# Run all 353 frontend unit & widget tests
flutter test

# Build Android Production Release APK
flutter build apk --release
```

---

## 📊 Verification & Test Summary

- **Backend Test Suite**: `192 Passed / 0 Failed` (100% Pass)
- **Frontend Test Suite**: `353 Passed / 0 Failed` (100% Pass)
- **Dart Analyzer**: `0 Issues Found` across entire project
- **Production Build**: Successfully compiled Android Release APK

---

## 📄 Academic Project Documentation
Refer to [`docs/PROJECT_REPORT.md`](docs/PROJECT_REPORT.md) for the complete MCA Major Project Report, architectural diagrams, mathematical formulations, and collection schemas.

**License**: MIT License.
