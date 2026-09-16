# Sahyān GPS & Live Location Troubleshooting Guide

This guide provides diagnostic procedures and resolution workflows for common GPS, telematics, and mapping issues.

---

## 1. GPS Fix & Permission Issues

### 1.1 Permission Denied Forever
* **Symptom**: `Geolocator.checkPermission()` returns `LocationPermission.deniedForever`.
* **Cause**: User clicked "Don't ask again" in the Android permission dialog.
* **Resolution**:
  1. Navigate user to `AppSettings.openAppSettings()` via UI prompt.
  2. Await return from background lifecycle and re-execute `GpsDiagnosticService.runDiagnostics()`.

### 1.2 Location Services Disabled
* **Symptom**: `Geolocator.isLocationServiceEnabled()` returns `false`.
* **Cause**: Device GPS / Location toggle is disabled in system quick settings.
* **Resolution**: Call `Geolocator.openLocationSettings()` and prompt user to enable High Accuracy location mode.

### 1.3 Inaccurate or Jittery Coordinates
* **Symptom**: Marker jumps wildly across city blocks when vehicle is stationary.
* **Cause**: Low GPS signal in urban canyons or tunnel environments (accuracy > 50 meters).
* **Resolution**:
  * The `LocationPreprocessor` automatically rejects fixes with accuracy > 50 meters or physical speed violations.
  * Coordinates are smoothed using the Exponential Moving Average filter ($\alpha = 0.65$).

---

## 2. Telematics & Socket.IO Issues

### 2.1 Unauthorized Driver Location Update
* **Symptom**: Socket emits error `{ "message": "Unauthorized: only the assigned driver may broadcast location." }`.
* **Cause**: Socket connected with a passenger JWT or a user ID that does not match `ride.driver`.
* **Resolution**:
  * Verify driver authentication token before starting `DriverLocationService`.
  * Ensure `joinRideRoom` is executed with the verified driver user token.

### 2.2 Reconnect Spam and Stale Coordinate Bursts
* **Symptom**: Upon regaining cell coverage, passenger receives a sudden burst of outdated driver markers.
* **Cause**: Unbounded offline queue flushing expired telemetry.
* **Resolution**:
  * Bounded queue limit (10 items maximum).
  * Filter drops packets older than 60 seconds on reconnect.

---

## 3. Routing & Quota Errors

### 3.1 HTTP 429 Too Many Requests from Google Routes API
* **Symptom**: Backend logs report `OVER_QUERY_LIMIT` or `RESOURCE_EXHAUSTED`.
* **Cause**: Route recalculation triggered on every GPS packet.
* **Resolution**:
  * Verify reroute throttler is active (minimum interval 20s, minimum deviation 80m).
  * Check `LocationCacheService` hit rates in backend.

### 3.2 False Positive Off-Route Detections
* **Symptom**: Driver reported as off-route while driving in valid highway lanes.
* **Cause**: GPS inaccuracy (e.g. 25m drift) exceeding a tight raw distance threshold.
* **Resolution**:
  * Effective deviation calculation subtracts GPS accuracy uncertainty:
    $$\text{effectiveDeviation} = \max(0, \text{rawDeviation} - \text{gpsAccuracy})$$
  * Rerouting only triggers if $\text{effectiveDeviation} > 60\text{ meters}$ for 3 consecutive fixes.
