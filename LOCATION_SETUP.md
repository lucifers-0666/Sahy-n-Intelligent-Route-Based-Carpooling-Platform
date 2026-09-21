# Sahyan - Location, Map, and Routing Subsystem Documentation

## Overview

Sahyan is an intelligent route-based carpooling platform designed for intercity and daily commuter corridors. This document details the location, map rendering, geocoding, route calculation, route matching, and real-time telematics architecture implemented for the MCA major project.

The system is engineered to run on a 100% free and open-source foundation with zero credit card requirements, zero debit card requirements, and zero paid billing accounts.

---

## 1. Technologies Used

| Layer | Technology | Role | Cost / Requirement |
|---|---|---|---|
| Map Rendering | flutter_map (v7.0.2) + latlong2 | OpenStreetMap vector/raster tile rendering in Flutter | Free, Open Source, No API Key, No Card |
| Tile Provider | OpenStreetMap Public Standard Tiles | Cartographic map tiles (`tile.openstreetmap.org`) | Free, Fair Use, No API Key, No Card |
| Geocoding / Search | Nominatim (OpenStreetMap) | Location search, address autocomplete, reverse geocoding | Free, Fair Use, No API Key, No Card |
| Route Calculation | OSRM (Open Source Routing Machine) | Turn-by-turn road network routing and distance/duration | Free, Open Source, No API Key, No Card |
| Device GPS | Geolocator Flutter Plugin | Phone GPS hardware interrogation (fine & coarse GPS) | Native Device Hardware, Free |
| Real-Time Streaming | Socket.IO Client / Server | Live driver telematics broadcast to passenger room | Self-hosted on Node.js, Free |
| Database & Geospatial | MongoDB (Mongoose 2dsphere) | Ride geospatial indexing, GeoJSON storage, and queries | Free tier / Self-hosted, Free |

---

## 2. Why Each Technology Was Selected

1. **flutter_map & OpenStreetMap**:
   - Replaces proprietary Google Maps Flutter SDK which requires billing account activation and credit card verification in Google Cloud Console.
   - Operates natively without requiring an API key.
   - Provides smooth multi-touch pan, zoom, custom Flutter widget markers, and multi-layer polylines.

2. **OSRM (Open Source Routing Machine)**:
   - Provides actual road geometry (encoded polylines), actual driving distance, and actual travel duration based on OpenStreetMap road networks.
   - Eliminates fake straight or synthetic curved lines while maintaining zero cost.

3. **Nominatim**:
   - Open-source search and reverse geocoding engine operated by the OpenStreetMap Foundation.
   - Supports search across Indian cities, towns, and highway corridors without payment credentials.

4. **Geolocator**:
   - Direct integration with Android LocationManager and FusedLocationProviderClient.
   - Delivers real device hardware coordinates with heading, speed, and accuracy metrics.

5. **Socket.IO with JWT Authentication**:
   - Full-duplex WebSocket channel with fail-closed security.
   - Reuses stored route geometry so real-time driver movement does not trigger external routing API calls on every GPS coordinate fix.

---

## 3. How GPS Works

1. **Hardware Interrogation**:
   - When requested, `GeolocatorProvider` queries `isLocationServiceEnabled()` to ensure the user has enabled location services on their Android device.
2. **Permission Workflow**:
   - Checks permission status using `checkPermission()`.
   - If denied, prompts user using `requestPermission()`.
   - Handles `granted`, `denied`, and `deniedForever` gracefully with informative UI dialogs.
3. **Accuracy & Distance Filtering**:
   - Foreground streaming uses high accuracy with a 5-meter distance threshold (`distanceFilter: 5`).
   - Telemetry points are converted into strongly typed `LocationPoint` models containing latitude, longitude, speed (converted from m/s to km/h), heading (0 to 359 degrees), and timestamp.
4. **No Synthetic / Fake Data**:
   - Real hardware coordinates are utilized. If GPS hardware is unavailable or disabled, the application displays an explicit status notification rather than manufacturing fake coordinates.

---

## 4. How Map Rendering Works

1. **FlutterMap Architecture**:
   - Integrated inside `SahyanRouteMap` (`lib/shared/widgets/sahyan_route_map.dart`).
   - Uses `TileLayer` with OpenStreetMap URL template:
     `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
   - Configured with `userAgentPackageName: 'com.sahyan.app'` conforming to OpenStreetMap Tile Usage Policy.
2. **Layer Hierarchy**:
   - Bottom: OpenStreetMap raster tiles.
   - Middle: `PolylineLayer` rendering the dual-tone route line (mint translucent glow backing with pine dark primary route).
   - Top: `MarkerLayer` rendering interactive Flutter widget pins for pickup (origin), destination (drop), intermediate stopovers, and the live driver marker.
3. **Driver Position Interpolation**:
   - Incoming GPS points from Socket.IO trigger a 1500ms `AnimationController` with `Curves.easeInOut`.
   - Positions and headings are interpolated between successive GPS fixes to ensure smooth on-screen vehicle rotation and transit.
4. **Headless Test Support**:
   - Headless unit and widget tests automatically render an internal vector fallback canvas (`_SayanVectorRoutePainter`), allowing 100% of test suites to pass without live internet tile requests.

---

## 5. How Location Search Works

1. **Search Input & Debounce**:
   - Located in `LocationSearchBottomSheet` (`lib/features/rides/presentation/widgets/location_search_bottom_sheet.dart`).
   - User keystrokes are debounced by 400 milliseconds to prevent excessive network calls.
2. **Dual-Tier Resolution**:
   - Tier 1 (Instant): Curated Gujarat transport corridor hubs (Iscon Cross Roads, Kalawad Road, Majura Gate, Alkapuri, Jubilee Ground, GIFT City, Limbdi Toll Plaza, Chotila Circle).
   - Tier 2 (Network): Backend proxy endpoint `GET /api/v1/rides/places/autocomplete?input=...` queries Nominatim.
3. **Rate Limiting & In-Memory Cache**:
   - The backend `nominatimService.js` enforces a rate limit (maximum 1 request per second) and an LRU in-memory cache with a 24-hour TTL to respect OpenStreetMap servers.
4. **Structured Model**:
   - All results conform to `SelectedLocation` / `LocationModel` with explicit `name`, `address`, `city`, `latitude`, `longitude`, and `placeId`.

---

## 6. How Route Calculation Works

1. **Route Request**:
   - Frontend calls `POST /api/v1/rides/route/calculate` with origin and destination coordinates.
2. **OSRM Provider**:
   - Backend `OsrmRouteProvider` queries the public OSRM driving engine:
     `https://router.project-osrm.org/route/v1/driving/{lng1},{lat1};{lng2},{lat2}?overview=full&geometries=polyline`
3. **Response Processing**:
   - Extracts road network distance in meters, driving duration in seconds, and Google-standard encoded polyline format (`encodedPolyline`).
4. **Flutter Rendering**:
   - Frontend decodes the polyline into a list of coordinates and renders the exact road curvature on the OpenStreetMap canvas.
5. **No Synthetic Straight-Line Curves**:
   - Real highway geometries (such as NH47, NH27, NE1) are mapped directly from real road coordinates.

---

## 7. How Live Driver Tracking Works

1. **Driver Streaming**:
   - During an active trip, the driver application activates `DriverLocationService`.
   - Hardware GPS fixes pass through `LocationPreprocessor` for outlier filtering and accuracy validation.
   - Formatted telemetry payload is emitted over Socket.IO under the event `driver:location_update`.
2. **Server Validation**:
   - Node.js server validates the driver's JWT token, verifies ride ownership, sanitizes coordinates, and checks speed realism.
3. **Passenger Reception**:
   - Sanitized location data is broadcast only to verified participants joined to the ride room (`ride:<rideId>`).
   - The passenger map receives the update and smoothly moves the vehicle marker.
4. **No Routing API Spam**:
   - Driver position updates do NOT trigger new OSRM or routing API queries. The existing stored route geometry is preserved.

---

## 8. How Route Progress Works

1. **Stored Route Preservation**:
   - The route calculated when the ride was scheduled or accepted is cached in memory and in MongoDB.
2. **Geometric Projection**:
   - The backend `RouteProgressService` and frontend `route_progress_service.dart` project the driver's current GPS coordinate to the nearest segment on the stored polyline using perpendicular cross-track distance calculations.
3. **Metrics Computed**:
   - `fractionalProgress`: Value from 0.0 to 1.0 indicating completion percentage.
   - `distanceRemainingMeters`: Cumulative distance from the projected point to the destination.
   - `etaSeconds`: Estimated arrival time based on current speed and historical corridor averages.

---

## 9. How Route Matching Works

Sahyan differentiates itself through a deterministic, explainable 6-factor route matching engine (`routeMatchService.js`), designed for transparent academic review:

1. **Route Overlap (40% Weight)**:
   - Measures the percentage of the passenger's journey that falls within a 2.5 km corridor of the driver's route polyline.
2. **Pickup Deviation (20% Weight)**:
   - Evaluates the walking or detour distance from the driver's path to the passenger's pickup location.
3. **Destination Deviation (15% Weight)**:
   - Evaluates the drop-off deviation distance.
4. **Time Compatibility (10% Weight)**:
   - Scores departure time discrepancy between driver departure and passenger target time.
5. **Driver Reliability (10% Weight)**:
   - Neutral baseline of 70/100 for new drivers, scaling upward based on verified ratings and completed trips.
6. **Seat Availability (5% Weight)**:
   - Verifies available seats meet the passenger's request.

Final scores (0 to 100) map to clear grades:
- 90 to 100: Excellent Match
- 80 to 89: Very Good Match
- 70 to 79: Good Match
- 60 to 69: Fair Match
- Below 60: Weak Match

---

## 10. Android Configuration and Permissions

In `frontend/android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    ...
</manifest>
```

- `ACCESS_FINE_LOCATION`: Required for high-precision GPS coordinate tracking during rides.
- `ACCESS_COARSE_LOCATION`: Required for network and cell-tower location fallback.
- No Google Maps API key meta-data (`com.google.android.geo.API_KEY`) is required.

---

## 11. External Service Limits and Policies

| Service | Endpoint | Policy / Limitation | Implementation Safeguard |
|---|---|---|---|
| OpenStreetMap Tiles | tile.openstreetmap.org | Respect fair use, no tile scraping, proper User-Agent | TileLayer uses caching and package User-Agent |
| OSRM Public Demo API | router.project-osrm.org | Intended for light and standard demo/project traffic | Called only on route creation, never on GPS tick |
| Nominatim Geocoding | nominatim.openstreetmap.org | Maximum 1 request per second, valid User-Agent | 400ms UI debounce + backend 1s rate limiter + 24h cache |

---

## 12. Cost and Card Requirements Confirmation

- **Requires Credit Card?**: NO.
- **Requires Debit Card?**: NO.
- **Requires Paid Billing Account?**: NO.
- **Can complete development and testing run for free?**: YES. 100% free of charge.
