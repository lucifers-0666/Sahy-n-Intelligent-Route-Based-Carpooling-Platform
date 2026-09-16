const RouteProvider = require('../routeProvider');

/**
 * Deterministic Mock Route Provider for unit tests and local offline development
 */
class MockRoutesProvider extends RouteProvider {
  constructor() {
    super();
  }

  isConfigured() {
    return true;
  }

  /**
   * Calculate direct Haversine distance in meters
   */
  _calculateHaversineMeters(lat1, lon1, lat2, lon2) {
    const R = 6371000;
    const toRad = (deg) => (deg * Math.PI) / 180.0;
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  async calculateRoute(origin, destination, options = {}) {
    const directDist = this._calculateHaversineMeters(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude
    );
    // Road curvature factor 1.18x over direct Haversine distance
    const distanceMeters = Math.round(directDist * 1.18);
    // Average speed ~ 68 km/h = 18.88 m/s
    const durationSeconds = Math.round(distanceMeters / 18.88);

    // Simple polyline interpolation
    const encodedPolyline = `_p~iF~ps|U_ulLnnqC_mqNvxq` + Math.round(distanceMeters % 1000);

    return {
      success: true,
      apiKeyConfigured: true,
      distanceMeters,
      durationSeconds,
      distanceText: `${(distanceMeters / 1000).toFixed(1)} km`,
      durationText: `${Math.round(durationSeconds / 60)} mins`,
      encodedPolyline,
      startAddress: origin.name || 'Origin',
      endAddress: destination.name || 'Destination',
      summary: 'Mock Primary Highway Corridor',
    };
  }

  async calculateRouteMatrix(origins, destinations) {
    const rows = origins.map((orig) => ({
      elements: destinations.map((dest) => {
        const dist = Math.round(
          this._calculateHaversineMeters(orig.latitude, orig.longitude, dest.latitude, dest.longitude) * 1.18
        );
        return {
          status: 'OK',
          distance: { value: dist, text: `${(dist / 1000).toFixed(1)} km` },
          duration: { value: Math.round(dist / 18.88), text: `${Math.round(dist / 18.88 / 60)} mins` },
        };
      }),
    }));

    return { success: true, rows };
  }

  async geocode(address) {
    return {
      success: true,
      formattedAddress: address,
      latitude: 23.0225,
      longitude: 72.5714,
      placeId: 'mock_place_' + Buffer.from(address).toString('hex').slice(0, 8),
    };
  }

  async reverseGeocode(latitude, longitude) {
    return {
      success: true,
      formattedAddress: `Location near ${latitude.toFixed(4)}, ${longitude.toFixed(4)}`,
      placeId: 'mock_rev_place_123',
    };
  }
}

module.exports = MockRoutesProvider;
