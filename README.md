# Sahyān (सह्यान) — Intelligent Route-Based Carpooling Platform

[![Backend Test Suite](https://img.shields.io/badge/Backend%20Tests-203%20Passed-0B5D4B?style=flat-square&logo=node.js)](backend/)
[![Frontend Test Suite](https://img.shields.io/badge/Frontend%20Tests-367%20Passed-0B5D4B?style=flat-square&logo=flutter)](frontend/)
[![Dart Analyzer](https://img.shields.io/badge/Dart%20Analyzer-0%20Issues-brightgreen?style=flat-square&logo=dart)](frontend/)
[![Architecture](https://img.shields.io/badge/Architecture-REST%20%2B%20Socket.IO%20%2B%20OSRM-0B5D4B?style=flat-square)](LOCATION_SETUP.md)

Sahyān (सह्यान) is a route-based peer-to-peer carpooling platform connecting vehicle owners travelling along predetermined highway corridors with passengers heading along the same route. By sharing unoccupied vehicle seats, drivers and passengers equitably distribute travel fuel and toll contributions, lowering carbon emissions and congestion without commercial on-demand taxi exploitation.

---

## Key Features and Capabilities

- Intelligent Route Matching Engine: Polyline geometry evaluation, cross-track displacement analysis, and multi-factor scoring (route overlap, detour deviation, departure time compatibility, driver reliability) producing deterministic Route Match Scores (0-100%).
- Free and Open-Source Geospatial Architecture: Powered by FlutterMap, OpenStreetMap raster tiles, real road network geometry via OSRM (Open Source Routing Machine), Nominatim reverse geocoding, and Geolocator GPS tracking. Zero proprietary Google Maps API keys or billing cards required.
- Real-Time GPS Telematics: Vehicle telemetry streaming over authenticated, ride-scoped Socket.IO rooms with bearing rotation, off-route detection, and dynamic ETA recomputation.
- Atomic Seat Inventory: MongoDB transaction-managed booking allocations preventing overbooking and race conditions during concurrent seat requests.
- Payment Sandbox Simulation: Academic contribution checkout splitting base ride contribution, platform trust fee, and FASTag toll allocation with automated driver escrow settlement upon trip completion.
- Digital Boarding Pass: 4-digit cryptographically verified PIN handshake between passenger and driver before trip departure.
- Safety Center and Emergency Response: Direct phone dialer launcher for National Emergency (112) and trusted emergency contacts, plus shareable live journey tracking links.
- In-App Contextual Messaging and Reviews: Ride-authorized direct communication channels and bilateral post-trip ratings.
- Web Admin Moderation Dashboard: Operations portal for driver document verification, ride auditing, and user moderation.

---

## Technology Stack

| Layer | Technologies |
|---|---|
| Mobile Client | Flutter 3.x, Dart, Riverpod State Management, GoRouter, FlutterMap, latlong2, Geolocator |
| Backend Core | Node.js, Express.js REST API, Socket.IO Real-Time Engine, JWT, bcryptjs |
| Geospatial Routing | OSRM (Open Source Routing Machine), Nominatim OpenStreetMap Geocoding |
| Database | MongoDB Atlas with GeoJSON 2dsphere Geospatial Indexing, Mongoose ODM |
| Design System | Sahyān Luxury Light / Bento UI (Deep Emerald `#0B5D4B`, Soft Mint `#A7E8D2`, Light Surface `#F2F7F4`, Plus Jakarta Sans) |

---

## Physical Android Device Networking Setup

For local development on a physical Android handset connected via USB:

1. Enable USB Debugging on your Android device (Settings > Developer Options > USB Debugging).
2. Connect your phone to your computer via USB.
3. Verify ADB detection:
   ```bash
   adb devices
   ```
4. Reverse port 5000 so the phone accesses your workstation's Express backend at localhost:
   ```bash
   adb reverse tcp:5000 tcp:5000
   ```
5. Ensure the backend is running on port 5000. The frontend automatically connects to `http://127.0.0.1:5000/api/v1` and Socket.IO at `http://127.0.0.1:5000`.

---

## Repository Structure

```
Sahyān_MCA_APP/
├── backend/                   # Node.js & Express.js REST + Socket.IO Server
│   ├── src/
│   │   ├── config/            # Database & JWT configurations
│   │   ├── controllers/       # Auth, Rides, Bookings, Vehicles, Payments, Admin, Reviews
│   │   ├── middleware/        # Authentication, Authorization, Validation & Error Handlers
│   │   ├── models/            # User, Vehicle, Ride, Booking, Payment, Message, Review
│   │   ├── routes/            # REST API route definitions
│   │   ├── services/          # Route Match Engine, OSRM Provider, Nominatim Service
│   │   └── utils/             # Polyline & Geometric algorithms
│   └── test/                  # 203 Automated Unit & Integration Tests
│
├── frontend/                  # Flutter Cross-Platform Mobile Application
│   ├── lib/
│   │   ├── app/               # Router, Theme (AppColors, AppRadii, AppTypography) & Global Providers
│   │   ├── core/              # Network (ApiClient, SocketClient), Telemetry & Design System
│   │   ├── features/          # Auth, Rides, Bookings, Payments, Messages, Safety, Admin
│   │   └── shared/            # Bento Grid Widgets, FlutterMap (SahyanRouteMap), SahyanLogo
│   └── test/                  # 367 Widget, Layout, Telematics, Route & Responsive Tests
│
└── docs/                      # MCA Major Project Documentation & Architecture Reports
```

---

## Quick Start Guide

### Prerequisites
- Node.js (v18+) & npm
- Flutter SDK (3.24+) & Dart SDK
- MongoDB instance (Local or Atlas URI)
- Android SDK & ADB (for physical device development)

### 1. Backend Setup & Tests
```bash
cd backend
npm install
cp .env.example .env
npm run dev

# Run all 203 automated backend tests
npm test
```

### 2. Frontend Setup & Build
```bash
cd frontend
flutter pub get

# Verify zero analyzer warnings
dart analyze lib

# Run all 367 frontend unit, widget, and responsive tests
flutter test

# Build Android Debug APK
flutter build apk --debug
```

---

## Verification and Test Summary

- Backend Test Suite: 203 Passed / 0 Failed (100% Pass)
- Frontend Test Suite: 367 Passed / 0 Failed (100% Pass)
- Dart Analyzer: 0 Issues Found across lib/
- Production Map Architecture: FlutterMap + OpenStreetMap + OSRM + Nominatim (Zero Google Maps dependencies)
- Official Branding: SVG single source of truth (sahyan_symbol.svg, sahyan_logo_primary.svg) rendered via flutter_svg

---

## Project Documentation
- LOCATION_SETUP.md: Complete Free/Open-Source Location and Routing Architecture Guide
- BRAND_IDENTITY.md: Official Sahyān Brand Identity, Color Specifications, and Logo Usage

License: MIT License.
