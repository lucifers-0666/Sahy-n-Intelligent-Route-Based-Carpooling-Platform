# Sahyān — Route Search Data Source & Telematics Audit Report

## Executive Summary

This audit establishes the exact origin and lifecycle of all data categories used in the Sahyān route-search experience across the Flutter client and Node.js/Express backend. Every item below has been audited directly against source code and executed test suites.

---

## 1. Category-by-Category Source Breakdown

### Category 1: Current Device Location

* **Source File & Function:**
  * Client: `frontend/lib/core/location/data/providers/geolocator_provider.dart` (`GeolocatorProvider.getCurrentPosition`, `checkPermission`, `requestPermission`)
  * Caller: `frontend/lib/features/home/presentation/screens/home_screen.dart` (`_loadGrantedUserLocation`) and `frontend/lib/features/home/presentation/widgets/hero_search_card.dart` (`_handleGpsCurrentLocation`)
* **Actual Data Source:**
  * Real mobile hardware GPS sensors via the `geolocator` Flutter plugin (`geolocator_android` / `geolocator_apple`).
* **API Endpoint or Database Collection:**
  * Device OS Location Subsystem (Android LocationManager / FusedLocationProviderClient, iOS CoreLocation). No backend endpoint invoked for device GPS fix.
* **Verification Status:**
  * Verified in code and widget tests (`test/core/location_gps_test.dart`).
* **Real Request Observed / Tested:**
  * Yes, real hardware requests execute on physical devices. In automated widget tests, `GeolocatorPlatform` is mocked/stubbed to return `Position` coordinates.
* **Fallback / Mock Source:**
  * If location services are disabled, permissions are denied, or GPS fix times out (4-second timeout), falls back to `AppRegion.fallbackCity` (`'Nagpur'`), `AppRegion.fallbackLatitude` (`21.1458`), and `AppRegion.fallbackLongitude` (`79.0882`) configured in `frontend/lib/app/config/app_region.dart`.
* **Production Configuration Requirements:**
  * Requires `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` in AndroidManifest.xml and `NSLocationWhenInUseUsageDescription` in Info.plist.

---

### Category 2: City Autocomplete & Address Suggestions

* **Source File & Function:**
  * Client: `frontend/lib/features/home/presentation/widgets/hero_search_card.dart` (`_fetchPredictions`) and `frontend/lib/features/rides/presentation/widgets/location_search_bottom_sheet.dart` (`_fetchPredictions`)
  * Backend Controller: `backend/src/controllers/rideController.js` (`autocompletePlaces`)
  * Backend Service: `backend/src/services/location/nominatimService.js` (`autocompletePlaces`)
* **Actual Data Source:**
  * OpenStreetMap (OSM) Nominatim Free Geocoding API (`https://nominatim.openstreetmap.org/search?format=json&q=...`).
* **API Endpoint or Database Collection:**
  * Backend Endpoint: `GET /api/v1/rides/places/autocomplete?input=<query>`
  * External Service: OpenStreetMap Nominatim REST API with mandatory platform User-Agent (`Sahyan-Carpooling-Platform/1.0`).
* **Verification Status:**
  * Verified in code, backend controller tests, and client widget tests (`route_geometry_test.dart`).
* **Real Request Observed / Tested:**
  * Yes, real HTTP GET requests observed when backend is connected. In automated Flutter widget tests, network client returns 400 or is intercepted, triggering the graceful local fallback.
* **Fallback / Mock Source:**
  * Client Fallback: When offline or query is under 2 characters, matches against `IndiaPopularHubs.popularHubs` and curated regional hubs (`Ahmedabad Junction`, `Vadodara Central Bus Station`, `Surat Central Ring Road`, `Rajkot Kalawad Road`, `Gandhinagar Infocity`, `Bhuj Bus Station`).
* **Production Configuration Requirements:**
  * No Google Cloud Billing, API keys, or credit cards required. Conforms to OpenStreetMap Usage Policy with 1-request-per-second throttling and in-memory LRU cache (250 entries).

---

### Category 3: Destination Hubs & Known Landmarks

* **Source File & Function:**
  * Backend: `backend/src/controllers/rideController.js` (`KNOWN_HUBS`, `resolveHubCoordinates`)
  * Frontend: `frontend/lib/features/rides/presentation/widgets/location_search_bottom_sheet.dart` (`IndiaPopularHubs.popularHubs`)
  * Frontend: `frontend/lib/features/home/presentation/widgets/hero_search_card.dart` (`_curatedHubs`)
* **Actual Data Source:**
  * Curated geographical lookup tables containing verified intercity transport hubs, highway junctions, and transit terminals.
* **API Endpoint or Database Collection:**
  * In-memory static dictionary in Node.js backend (`KNOWN_HUBS`) and Flutter frontend (`IndiaPopularHubs`).
  * Used by `GET /api/v1/rides/search` to resolve coordinates when a passenger searches by city/hub text without explicit GPS latitude/longitude.
* **Verification Status:**
  * Verified in code and unit tests (`npm test` in backend, `route_geometry_test.dart` in frontend).
* **Real Request Observed / Tested:**
  * Yes, backend test `GET /api/v1/rides/search - city text query resolves via known hub coordinates` tests this deterministic resolution directly.
* **Fallback / Mock Source:**
  * Contains 23 Gujarat transit hubs (Ahmedabad, Vadodara, Surat, Rajkot, Bhuj, Gandhinagar, GIFT City, ISCON Cross Road, Kalawad Road, Morbi, Mehsana, etc.) and 8 nationwide railway/bus terminals (Mumbai CSMT, Pune Junction, New Delhi, Jaipur, Bengaluru KBS, Mysuru, Nagpur Zero Mile, Hyderabad MGBS).
* **Production Configuration Requirements:**
  * None; runs locally with zero external network dependencies.

---

### Category 4: Frequent Corridors

* **Source File & Function:**
  * Backend: `backend/src/controllers/rideController.js` (`getCorridors`)
  * Frontend Repository/Provider: `frontend/lib/features/rides/presentation/rides_provider.dart` (`corridorsProvider`)
  * Frontend Dashboard: `frontend/lib/features/home/presentation/screens/home_screen.dart` (`_quickCorridors`)
* **Actual Data Source:**
  * Hybrid: Seeded base highway corridors combined with live MongoDB aggregation of active driver trips.
* **API Endpoint or Database Collection:**
  * Backend Endpoint: `GET /api/v1/rides/corridors`
  * Database Collection: MongoDB `rides` collection (`Ride.find({ status: { $in: ['active', 'boarding'] } })`).
* **Verification Status:**
  * Verified in backend source code (`rideController.js:1540-1654`) and frontend `rides_provider.dart:23-88`.
* **Real Request Observed / Tested:**
  * Tested via integration routes.
* **Fallback / Mock Source:**
  * When MongoDB has no active rides, `getCorridors` returns the verified base highway corridors:
    * Ahmedabad -> Rajkot (NH47, 214 km, base price ₹320)
    * Surat -> Vadodara (NH48, 152 km, base price ₹210)
    * Bhuj -> Ahmedabad (NH947, 332 km, base price ₹388)
    * Rajkot -> Surat (NH47, 420 km, base price ₹520)
    * Morbi -> Rajkot (SH24, 68 km, base price ₹120)
  * Frontend Fallback: If network is unreachable, `corridorsProvider` provides `Ahmedabad → Vadodara`, `Mumbai → Pune`, `Delhi → Jaipur`, `Bengaluru → Mysuru`.
  * Search Card Default: `HeroSearchCard.popularCorridors` defaults to `Bhuj → Ahmd (₹150)`, `Ahmedabad → Vadodara (₹150)`, `Surat → Mumbai (₹380)`, `Gandhinagar → Ahmedabad (₹80)`, `Rajkot → Ahmedabad (₹250)`.
* **Production Configuration Requirements:**
  * MongoDB connection string (`MONGODB_URI`).

---

### Category 5: Displayed Seat Prices & Cost Sharing

* **Source File & Function:**
  * Quick Corridor Chips: `HeroSearchCard.popularCorridors` (`c['price']`)
  * Live Corridors API: `backend/src/controllers/rideController.js` (`getCorridors`, lines 1637-1640)
  * Search Results: `backend/src/controllers/rideController.js` (`searchRides`), `backend/src/models/Ride.js` (`contributionPerSeat`)
* **Actual Data Source:**
  * Live Ride Records: Driver's registered fuel & toll contribution per seat in MongoDB.
  * Corridor Aggregation: Dynamically calculates average contribution: `Math.round(matching.reduce((acc, curr) => acc + (curr.contributionPerSeat || c.price), 0) / matching.length)`.
  * Quick Chips: Pre-calculated non-commercial cost-sharing benchmark.
* **API Endpoint or Database Collection:**
  * `GET /api/v1/rides/corridors` and `GET /api/v1/rides/search` querying `rides` collection.
* **Verification Status:**
  * Verified in code and tests.
* **Real Request Observed / Tested:**
  * Yes, backend test `Scenario: passenger finds available ride with matching origin and destination coordinates` verifies real `contributionPerSeat` returned in payload.
* **Fallback / Mock Source:**
  * If no driver rides are active in MongoDB, returns guideline cost-sharing price (e.g. ₹150 for Ahmedabad-Vadodara, ₹320 for Ahmedabad-Rajkot).
* **Production Configuration Requirements:**
  * MongoDB `rides` collection with indexed geospatial coordinates.

---

### Category 6: Route Geometry, Distance & Durations

* **Source File & Function:**
  * Client: `frontend/lib/features/rides/domain/services/route_geometry_service.dart` (`RouteGeometryService.calculateRoute`)
  * Backend: `backend/src/controllers/rideController.js` (`calculateRoute`)
  * OSRM Client: `https://router.project-osrm.org/route/v1/driving/...`
* **Actual Data Source:**
  * Open Source Routing Machine (OSRM) driving route API over OpenStreetMap highway topology.
* **API Endpoint or Database Collection:**
  * `POST /api/v1/rides/route/calculate` or `POST /api/v1/rides/calculate-route`.
* **Verification Status:**
  * Verified in code and unit tests (`route_geometry_test.dart`).
* **Real Request Observed / Tested:**
  * Yes, real OSRM requests return encoded polylines, durationSeconds, and distanceMeters.
* **Fallback / Mock Source:**
  * In test environments or when OSRM is unreachable, `RouteGeometryService` generates a deterministic polyline connecting the points with Haversine distance. `RouteGeometryService.mockRouteProvider` allows explicit unit test injection.
* **Production Configuration Requirements:**
  * Open internet access for Project OSRM public server or self-hosted OSRM docker instance.

---

### Category 7: Date, Time & Passenger State Passing into Search

* **Source File & Function:**
  * Home State: `frontend/lib/features/home/presentation/screens/home_screen.dart` (`_selectedDate`, `_selectedTime`, `_selectedSeats`, `_handleSearch`)
  * Query Provider: `frontend/lib/features/rides/presentation/rides_provider.dart` (`rideSearchQueryProvider`, `RideSearchQuery`)
  * Search Consumer: `frontend/lib/features/rides/presentation/screens/search_results_screen.dart`
* **How It Is Passed:**
  1. On Home dashboard, user specifies departure date, time, and passenger seats (1 to 6).
  2. Tapping "Find Matching Rides" calls `_handleSearch()`.
  3. Constructs `RideSearchQuery(origin, destination, originLocation, destinationLocation, date, time, seats)`.
  4. Stores into Riverpod state notifier: `ref.read(rideSearchQueryProvider.notifier).state = query`.
  5. Navigates to `/search-results`.
  6. `search_results_screen.dart` reads `ref.watch(rideSearchQueryProvider)` and dispatches HTTP GET to `/api/v1/rides/search?originLat=...&originLng=...&departureDate=...&departureTime=...&seats=...`.
  7. Backend validates `seats` (integer between 1 and 8), filters active driver rides with `availableSeats >= seats`, and evaluates 6-factor route matching.
* **Verification Status:**
  * Verified in code and end-to-end unit/widget/integration tests.
