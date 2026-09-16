# Sahyān GPS & Live Location Architecture

This document details the architectural design, algorithmic rationale, security protocols, and operational workflows of the Sahyān telematics and GPS subsystem.

---

## 1. System Architecture Overview

```text
+------------------------+
|   DEVICE GPS HARDWARE  | (Geolocator / FusedLocationProviderClient)
+-----------+------------+
            |
            v Raw GPS: lat, lng, acc, speed, heading, timestamp
+-----------+------------+
| LOCATION PREPROCESSOR  |
| - Timestamp Freshness  | (Drop stale > 30s or future packets)
| - Accuracy Threshold   | (Filter accuracy > 50m / confidence tiering)
| - Outlier Rejection    | (Physically impossible jump: distance / time)
| - Coordinate Smoothing | (Exponential Moving Average filter)
+-----------+------------+
            |
            v Normalized Location Model
+-----------+------------+
|   TELEMATICS PIPELINE  |
| - Haversine Distance   | (Tracked cumulative GPS distance O(1))
| - Spatial Projection   | (Nearest point on polyline, progress %)
| - Off-Route Detection  | (Effective deviation > threshold)
+-----+--------------+---+
      |              |
      v              v Off-Route trigger or manual refresh
+-----+------+ +-----+-----------------+
| Socket.IO  | | Route Engine Adapter  |
| Telematics | | (Google Routes API /  |
| (JWT Auth) | |  Mock Provider)       |
+-----+------+ +-----+-----------------+
      |              |
      |              v Road Geometry, ETA & Traffic
      |        +-----+-----------------+
      |        | Sahyān Match Engine   |
      |        | Multi-Factor Score    |
      |        +-----------------------+
      v
+-----+----------------+
| Passenger UI / Map   |
| - Bearing Arrow      |
| - Smooth Interp      |
| - Status (Live/Stale)|
+----------------------+
```

---

## 2. Mathematical & Algorithmic Rationale

### 2.1 Haversine Distance vs. Dijkstra Algorithm

#### Why Haversine Distance for Live GPS?
Live GPS tracking requires frequent distance calculation between consecutive coordinate fixes $P_1(\phi_1, \lambda_1)$ and $P_2(\phi_2, \lambda_2)$ on the spherical Earth surface.

Formula:
$$\Delta\phi = \phi_2 - \phi_1, \quad \Delta\lambda = \lambda_2 - \lambda_1$$
$$a = \sin^2\left(\frac{\Delta\phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta\lambda}{2}\right)$$
$$c = 2 \cdot \arctan2\left(\sqrt{a}, \sqrt{1-a}\right)$$
$$d = R \cdot c \quad (R = 6,371,000 \text{ m})$$

* **Computational Complexity**: $O(1)$ constant time and $O(1)$ memory.
* **Execution Characteristics**: Sub-microsecond calculation suitable for execution on low-end Android mobile processors without UI thread stutter.

#### Why NOT Dijkstra for Live GPS Tracking?
* Dijkstra is a single-source shortest path algorithm designed for static weighted graph structures $G = (V, E)$.
* Its computational complexity is $O(|E| + |V| \log |V|)$ using a Fibonacci heap.
* Maintaining a complete real-time in-memory road graph of highway networks inside a mobile client application consumes excessive memory, requires extensive offline map storage, and does not capture dynamic live traffic conditions.
* Dijkstra is unnecessary for measuring point-to-point displacement, distance to nearest polyline segments, or cumulative traveled distance.

### 2.2 Google Routes API v2 for Road Routing
* Utilized exclusively for road-network pathfinding, corridor geometry generation, traffic-aware travel duration, and toll estimations via Google Routes API v2 (`POST /directions/v2:computeRoutes` and `POST /distanceMatrix/v2:computeRouteMatrix`).
* Requests specify strict field masks (`X-Goog-FieldMask: routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline,routes.description,routes.routeLabels`) and map vehicle modes to `DRIVE` (sedan/SUV/EV) and `TWO_WHEELER` (motorcycle).
* Kept strictly separated from high-frequency GPS acquisition to protect API quotas.

### 2.3 Sahyān Match Score
Carpooling compatibility is evaluated via a multi-factor weighted algorithm:
$$\text{Match Score} = w_{\text{route}} S_{\text{route}} + w_{\text{time}} S_{\text{time}} + w_{\text{pickup}} S_{\text{pickup}} + w_{\text{drop}} S_{\text{drop}} + w_{\text{rel}} S_{\text{rel}} + w_{\text{veh}} S_{\text{veh}}$$

Configured weights:
* Route overlap: 35%
* Time compatibility: 20%
* Pickup deviation: 15%
* Drop deviation: 15%
* Driver reliability: 10%
* Vehicle compatibility: 5%

---

## 3. Data Flow & Security Protocol

### 3.1 Driver to Passenger Telematics Flow
1. **Driver GPS Fix**: Android device acquires GPS coordinates via Geolocator.
2. **Local Preprocessing**:
   * **Accuracy Tiering**:
     * $\le 20\text{m}$: High confidence
     * $\le 50\text{m}$: Normal confidence
     * $50\text{--}100\text{m}$: Degraded confidence (accepted with degraded flag)
     * $> 100\text{m}$: Invalid fix (rejected)
   * **Vehicle-Aware Outlier Rejection**: Calculates displacement $\Delta d = \text{Haversine}(P_{t-1}, P_t)$ and speed $\Delta d / \Delta t$. Points exceeding vehicle-specific thresholds are rejected:
     * Motorcycle: $130\text{ km/h}$
     * Auto Rickshaw: $80\text{ km/h}$
     * Sedan / SUV / Default: $160\text{ km/h}$
   * **Coordinate Smoothing**: Exponential Moving Average ($\alpha = 0.65$).
3. **Transmission**: Compact JSON packet emitted over Socket.IO:
   ```json
   {
     "rideId": "65f01ab29c8e4a0018d45123",
     "lat": 23.0225,
     "lng": 72.5714,
     "accuracy": 8.4,
     "speed": 62.5,
     "heading": 85.0,
     "timestamp": "2026-09-16T15:30:00.000Z"
   }
   ```
4. **Backend Authorization Enforcement (Fail-Closed)**:
   * Socket connection is strictly authenticated via JWT in the handshake middleware. Missing, invalid, or expired tokens are immediately rejected with error code 401.
   * On room join and location emit, the backend strictly verifies `socket.user._id` against the ride driver and booked passenger list in MongoDB. Client-supplied role claims are ignored.
   * Database authorization errors fail closed (deny access).
5. **Passenger Broadcast**: Authorized location packet is broadcast to room `ride:<rideId>`.
6. **Passenger UI Rendering**:
   * `SayanRouteMap` receives coordinate update.
   * Marker bearing and position interpolate smoothly using `AnimationController`.
   * Stale timer monitors packet intervals ($< 10\text{s}$ Live, $10\text{--}30\text{s}$ Degraded, $> 30\text{s}$ Stale).

---

## 4. Distance Separation Architecture

The system maintains strict semantic separation between distance metrics:

1. **GPS Tracked Distance (`gpsTrackedDistance`)**:
   * Cumulative sum of validated GPS coordinate displacements: $\sum_{i=1}^n \text{Haversine}(P_{i-1}, P_i)$.
   * Represents actual physical displacement traveled by the driver.
2. **Route Remaining Distance (`routeRemainingDistance`)**:
   * Road distance from current projection point on the active polyline to the trip destination.
   * Calculated via spatial polyline projection and periodic routing engine refreshes.

---

## 5. Offline and Reconnection Strategy

* **Bounded Queue**: When network is lost, the client maintains a ring buffer of the last 10 telemetry points.
* **Exponential Backoff**: Socket client attempts reconnection at intervals of 1000ms up to 5000ms.
* **Stale Packet Dropping**: Upon reconnecting, historical buffer points older than 60 seconds are discarded to prevent burst spam. Only the latest valid fix is transmitted immediately.
* **Local Continuity**: Local distance tracking and UI map rendering continue uninterrupted using cached route geometry.

