const osrmRouteProvider = require('./location/providers/osrmRouteProvider');

/**
 * Sahyān Route Calculation Service
 *
 * Provides real road turn-by-turn driving polylines, highway geometries,
 * distances and durations powered by high-precision OSRM (Open Source Routing Machine)
 * and OpenStreetMap road network data.
 */
class RouteCalculationService {
  constructor() {
    this.providerName = 'OSRM';
  }

  isConfigured() {
    return true;
  }

  /**
   * Calculate driving route with real road turn-by-turn polyline.
   * Directly interfaces with high-precision OSRM driving engine.
   * @param {Object} origin - { latitude, longitude, name }
   * @param {Object} destination - { latitude, longitude, name }
   * @param {Object} options - { waypoints, stopovers }
   * @returns {Promise<Object>}
   */
  async calculateRoute(origin, destination, options = {}) {
    return await osrmRouteProvider.calculateRoute(origin, destination, options);
  }
}

module.exports = new RouteCalculationService();
