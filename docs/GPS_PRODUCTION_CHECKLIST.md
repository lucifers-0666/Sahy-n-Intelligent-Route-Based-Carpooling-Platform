# Sahyān GPS & Live Location Production Checklist

This checklist must be audited prior to any staging or production deployment of the Sahyān carpooling application.

---

## 1. Google Cloud Platform & Routing Credentials

* [ ] **API Keys Separated**:
  * [ ] Mobile Maps SDK key (restricted to Android package name and SHA-1 certificate fingerprint).
  * [ ] Web Maps JavaScript key (restricted to production domain HTTP referrers).
  * [ ] Server-Side Routes API key (restricted to production backend server IP addresses).
* [ ] **API Restrictions**:
  * [ ] Mobile Key restricted strictly to **Maps SDK for Android** and **Maps SDK for iOS**.
  * [ ] Server Key restricted strictly to **Routes API**, **Directions API**, and **Places API**.
* [ ] **Quotas & Alerts**:
  * [ ] Daily request caps configured in Google Cloud Console.
  * [ ] Billing budget alerts set at 50%, 75%, 90%, and 100% thresholds.
  * [ ] Response field masks (`X-Goog-FieldMask`) verified on all Google Routes API calls to avoid overbilling.

---

## 2. Android Mobile Client Configuration

* [ ] **Permissions Manifest (`AndroidManifest.xml`)**:
  * [ ] `ACCESS_FINE_LOCATION` declared for precision GPS fixes.
  * [ ] `ACCESS_COARSE_LOCATION` declared for network fallback.
  * [ ] `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_LOCATION` configured if background driver navigation is enabled.
* [ ] **Permission State Machine**:
  * [ ] App handles `denied` state gracefully with contextual explanation.
  * [ ] App handles `deniedForever` by presenting direct button to open Android application settings.
  * [ ] App detects `locationServiceDisabled` and prompts user to toggle device GPS.
* [ ] **Simulation Disabled**:
  * [ ] Simulated GPS strictly gated behind `kDebugMode` or web test builds; production Android native builds execute real hardware GPS only.

---

## 3. Backend & Telematics Security

* [ ] **Socket.IO Authentication**:
  * [ ] Handshake middleware verifies valid JWT in `socket.handshake.auth.token` or authorization headers.
  * [ ] Unauthenticated socket connections are rejected with 401.
* [ ] **Ride Authorization**:
  * [ ] `driver_location_update` verifies authenticated user ID equals assigned driver ID for the active ride.
  * [ ] Unauthorized client role claims (`role=driver` in payload) are rejected.
* [ ] **Payload Sanitization**:
  * [ ] Latitude and longitude validated as finite numbers within [-90, 90] and [-180, 180].
  * [ ] Timestamp freshness validated; coordinates older than 60 seconds rejected.
* [ ] **MongoDB Persistence**:
  * [ ] GPS telemetry stream is NOT written directly to MongoDB on every packet; only significant checkpoint coordinates or ride completion milestones are persisted.

---

## 4. Performance & Telematics Lifecycle

* [ ] **Stream Cleanup**:
  * [ ] Location stream cancelled when driver marks trip completed or cancelled.
  * [ ] Location stream cancelled when driver logs out or disposes driver active ride screen.
  * [ ] Socket room left when passenger closes live tracking screen.
* [ ] **Adaptive Frequency**:
  * [ ] Distance filter configured (5 meters minimum displacement).
  * [ ] Stale location detection configured (<10s Live, 10-30s Degraded, >30s Stale).
* [ ] **Rerouting Throttling**:
  * [ ] Off-route rerouting throttled to minimum 15-30 second intervals and 50-100 meter deviations.
