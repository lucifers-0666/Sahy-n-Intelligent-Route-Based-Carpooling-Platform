/**
 * Backward compatibility alias for RouteCalculationService.
 * Google Maps integration has been removed in favor of OSRM / OpenStreetMap.
 */
const routeCalculationService = require('./routeCalculationService');

module.exports = routeCalculationService;
