# Sahyān GPS and Routing Provider Evaluation

This document provides a comparative technical and economic evaluation of GPS positioning, mapping, and routing providers for the Sahyān carpooling platform.

---

## 1. Provider Evaluation

### 1.1 Google Maps Platform

Google Maps Platform provides high-precision global geographic data, real-time traffic analysis, enterprise-grade mapping SDKs, and the Google Routes API.

* **Maps SDK & Rendering**: Native Android and iOS vector map rendering with styling capabilities, custom marker rotation, and smooth camera animations.
* **Google Routes API**: Advanced multi-stop routing engine supporting traffic-aware calculations (`TRAFFIC_AWARE`, `TRAFFIC_AWARE_OPTIMAL`), route polyline geometry, toll data, and route alternative generation.
* **Geocoding & Places API**: Extensive Indian postal address resolution, point-of-interest indexing, and autocomplete predictions.
* **Security & Credential Restrictions**: Supports HTTP referrer restrictions for web applications and SHA-1 fingerprint package restrictions for Android applications. Server-side routing calls use IP-restricted API keys.
* **Billing & Thresholds**: Requires a Google Cloud Platform billing account. Monthly credit tiers apply as per Google Maps Platform official pricing.
* **Reference**: [Google Maps Platform Pricing](https://mapsplatform.google.com/pricing/)

### 1.2 OpenStreetMap (OSM) Ecosystem

The OpenStreetMap ecosystem comprises community-maintained map databases, vector tile servers, and open-source routing algorithms.

* **Components Evaluated**: MapLibre GL Native / Web, Leaflet, Nominatim (geocoding), OSRM (Open Source Routing Machine), GraphHopper, and Valhalla.
* **Strengths**: Zero software licensing fees for map data, complete self-hosting capability, no vendor lock-in.
* **Limitations**: Public community infrastructure (`tile.openstreetmap.org`, `nominatim.openstreetmap.org`) strictly forbids high-throughput commercial telematics in its Acceptable Use Policy.
* **Production Recommendation**: If OSM is selected, self-host an OSRM or Valhalla instance on dedicated infrastructure or utilize hosted enterprise OSM vendors (such as Stadia Maps or Geoapify).

### 1.3 Mapbox

Mapbox provides developer-focused geospatial SDKs built upon open data and proprietary traffic telemetry.

* **Maps & Directions API**: High-performance vector tile rendering, dynamic turn-by-turn navigation, and traffic-aware matrix calculations.
* **Pricing & Quotas**: Generous monthly active user (MAU) free tier on mobile SDKs; pay-per-request pricing thereafter.
* **Integration Strategy**: Suitable as a secondary pluggable provider behind Sahyān's abstract routing interface.

### 1.4 HERE Technologies

HERE Technologies specializes in automotive and commercial fleet location services.

* **Capabilities**: Accurate truck and passenger car routing, real-time lane-level traffic intelligence, offline map caching SDKs, and geocoding.
* **Developer Access**: Freemium plan with monthly transaction allowances.
* **Suitability**: Enterprise alternative for regional corridor carpooling with high reliability.

### 1.5 TomTom

TomTom provides mapping, search, and traffic analytics with strong European and Asian coverage.

* **Capabilities**: Real-time traffic, electric vehicle range routing, and route optimization.
* **Architecture Positioning**: Retained as a future pluggable option through provider abstraction.

### 1.6 GPSd (Hardware and Embedded Only)

GPSd is an open-source daemon that monitors GPS receivers attached to a host computer via serial or USB ports.

* **Scope**: Evaluated exclusively for dedicated Linux hardware, Raspberry Pi telemetry units, and embedded vehicle hardware.
* **Mobile Constraint**: Not applicable to mobile client Flutter architectures, where platform location services (Android LocationManager / FusedLocationProvider) are utilized.

---

## 2. Provider Decision Matrix

| Provider | Map Rendering | GPS Position | Geocoding | Routing Engine | Traffic Awareness | Places Autocomplete | Mobile SDK | Web Support | Offline Capability | Cost Model | Operational Complexity |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Google Maps Platform** | Excellent | Platform Native | Excellent | Advanced (Routes API) | Real-Time Live | Excellent | Native Android/iOS | Full JavaScript SDK | Tile cache only | Pay-as-you-go (Credits) | Low (Managed) |
| **OSM (Self-Hosted OSRM/Valhalla)** | Good (MapLibre) | Platform Native | Moderate (Nominatim) | High (OSRM/Valhalla) | Requires custom feed | Basic | MapLibre SDK | Full WebGL | Full offline packs | Infrastructure compute | High (DevOps maintenance) |
| **Mapbox** | Excellent | Platform Native | Very Good | Very Good | Real-Time Live | Very Good | Mapbox Maps SDK | Full GL JS | Regional offline maps | MAU / Tiered API | Low (Managed) |
| **HERE** | Very Good | Platform Native | Very Good | Very Good | Real-Time Live | Good | HERE Mobile SDK | Full Web SDK | Full vector offline | Transactional | Low (Managed) |
| **TomTom** | Good | Platform Native | Good | Good | Real-Time Live | Good | Maps SDK | Web SDK | Partial offline | Transactional | Low (Managed) |

---

## 3. Project-Scale Recommendations

### 3.1 Personal & Academic Tier (< 10,000 API requests/month)
* **Primary**: Google Maps Platform standard tier utilizing free monthly credits.
* **Device GPS**: Geolocator (Android FusedLocationProviderClient) with client-side Haversine distance calculations.
* **Telematics**: Direct Socket.IO updates to eliminate unnecessary routing queries during steady-state driving.

### 3.2 Small Commercial Tier (10,000 to 500,000 requests/month)
* **Primary**: Google Routes API with strict response field masking and localized coordinate quantization cache.
* **Optimization**: Throttle rerouting triggers to significant route deviations (greater than 50 to 100 meters) or time thresholds (greater than 20 seconds).

### 3.3 Medium to Large Commercial Tier (500,000 to 5,000,000 requests/month)
* **Primary**: Hybrid architecture using Google Routes API for initial ride offer matching and commercial validation, supplemented with self-hosted Valhalla or Mapbox routing for intra-trip tracking.

### 3.4 Enterprise Tier (5,000,000+ requests/month)
* **Primary**: Dedicated self-hosted cluster (OSRM or Valhalla on Kubernetes with OpenStreetMap road graphs), maintaining Google Maps Platform as a fallback provider for complex urban routing and Places search.

---

## 4. Architectural Selection for Sahyān

Sahyān adopts a decoupled architecture:
1. **Frontend Positioning**: Hardware GPS acquisition via device location provider with local validation, outlier rejection, and exponential moving average coordinate smoothing.
2. **Real-Time Telematics**: Socket.IO with JSON Web Token (JWT) handshake authentication and ride-level driver authorization.
3. **Point-to-Point Calculations**: Pure mathematical Haversine distance (O(1) algorithmic complexity).
4. **Road Routing and Corridor Navigation**: Google Routes API managed server-side behind a provider-independent `RouteProvider` interface.
