/**
 * Abstract RouteProvider Interface
 *
 * All routing provider implementations (Google, Mock, Mapbox, Valhalla)
 * must implement this contract.
 */
class RouteProvider {
  /**
   * Calculate driving route between origin and destination
   * @param {Object} origin - { latitude, longitude, name }
   * @param {Object} destination - { latitude, longitude, name }
   * @param {Object} options - { waypoints, trafficAware, alternatives }
   * @returns {Promise<Object>} - { success, distanceMeters, durationSeconds, encodedPolyline, startAddress, endAddress, error }
   */
  async calculateRoute(origin, destination, options = {}) {
    throw new Error('calculateRoute must be implemented by concrete RouteProvider');
  }

  /**
   * Calculate distance matrix between multiple origins and destinations
   * @param {Array<Object>} origins
   * @param {Array<Object>} destinations
   * @returns {Promise<Object>}
   */
  async calculateRouteMatrix(origins, destinations) {
    throw new Error('calculateRouteMatrix must be implemented by concrete RouteProvider');
  }

  /**
   * Geocode a human-readable address to latitude/longitude
   * @param {string} address
   * @returns {Promise<Object>}
   */
  async geocode(address) {
    throw new Error('geocode must be implemented by concrete RouteProvider');
  }

  /**
   * Reverse geocode latitude/longitude to address
   * @param {number} latitude
   * @param {number} longitude
   * @returns {Promise<Object>}
   */
  async reverseGeocode(latitude, longitude) {
    throw new Error('reverseGeocode must be implemented by concrete RouteProvider');
  }
}

module.exports = RouteProvider;
