const LocationProcessor = require('./locationProcessor');
const { decodePolyline } = require('../../utils/polylineUtils');

/**
 * Route Progress and Off-Route Detection Service
 */
class RouteProgressService {
  /**
   * Project a point onto a line segment [p1, p2] and return perpendicular distance and projection factor t
   */
  static projectOntoSegment(point, p1, p2) {
    const lat = point.latitude;
    const lng = point.longitude;
    const x1 = p1.latitude;
    const y1 = p1.longitude;
    const x2 = p2.latitude;
    const y2 = p2.longitude;

    const dx = x2 - x1;
    const dy = y2 - y1;

    if (dx === 0 && dy === 0) {
      return {
        distanceMeters: LocationProcessor.haversineDistance(lat, lng, x1, y1),
        t: 0,
        projLat: x1,
        projLng: y1,
      };
    }

    // Normalized projection factor t clamped to [0, 1]
    const t = Math.max(0, Math.min(1, ((lat - x1) * dx + (lng - y1) * dy) / (dx * dx + dy * dy)));
    const projLat = x1 + t * dx;
    const projLng = y1 + t * dy;

    return {
      distanceMeters: LocationProcessor.haversineDistance(lat, lng, projLat, projLng),
      t,
      projLat,
      projLng,
    };
  }

  /**
   * Calculate route progress and off-route deviation for a driver location
   * @param {Object} currentPosition - { latitude, longitude, accuracy }
   * @param {string} encodedPolyline - Google encoded polyline string
   * @param {Object} destination - { latitude, longitude }
   * @param {Object} options - { offRouteThresholdMeters }
   */
  static evaluateProgress(currentPosition, encodedPolyline, destination, options = {}) {
    const offRouteThreshold = options.offRouteThresholdMeters || 80.0;
    const points = decodePolyline(encodedPolyline);

    if (!points || points.length === 0) {
      const remainingDirect = LocationProcessor.haversineDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        destination.latitude,
        destination.longitude
      );
      return {
        distanceRemainingMeters: remainingDirect,
        totalDistanceMeters: remainingDirect,
        progressFraction: 0.0,
        offRoute: false,
        nearestSegmentIndex: 0,
        deviationMeters: 0,
        effectiveDeviationMeters: 0,
      };
    }

    if (points.length === 1) {
      const remainingDirect = LocationProcessor.haversineDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        points[0].latitude,
        points[0].longitude
      );
      return {
        distanceRemainingMeters: remainingDirect,
        totalDistanceMeters: 0,
        progressFraction: 1.0,
        offRoute: false,
        nearestSegmentIndex: 0,
        deviationMeters: Math.round(remainingDirect),
        effectiveDeviationMeters: 0,
      };
    }

    let minDistance = Infinity;
    let nearestIndex = 0;
    let bestProj = null;

    // Find nearest point/segment along polyline
    for (let i = 0; i < points.length - 1; i++) {
      const proj = this.projectOntoSegment(currentPosition, points[i], points[i + 1]);
      if (proj.distanceMeters < minDistance) {
        minDistance = proj.distanceMeters;
        nearestIndex = i;
        bestProj = proj;
      }
    }

    // Effective deviation takes GPS accuracy uncertainty into account
    const accuracy = currentPosition.accuracy || 10.0;
    const effectiveDeviation = Math.max(0, minDistance - accuracy);
    const offRoute = effectiveDeviation > offRouteThreshold;

    // Calculate remaining distance: from projected point to points[nearestIndex + 1], then remaining segments
    let remainingPolylineDistance = 0;
    if (bestProj) {
      remainingPolylineDistance += LocationProcessor.haversineDistance(
        bestProj.projLat,
        bestProj.projLng,
        points[nearestIndex + 1].latitude,
        points[nearestIndex + 1].longitude
      );
    }
    for (let i = nearestIndex + 1; i < points.length - 1; i++) {
      remainingPolylineDistance += LocationProcessor.haversineDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude
      );
    }

    // Calculate total polyline distance
    let totalPolylineDistance = 0;
    for (let i = 0; i < points.length - 1; i++) {
      totalPolylineDistance += LocationProcessor.haversineDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude
      );
    }

    const progressFraction = totalPolylineDistance > 0
      ? Math.max(0, Math.min(1, 1 - (remainingPolylineDistance / totalPolylineDistance)))
      : 0;

    return {
      distanceRemainingMeters: Math.round(remainingPolylineDistance),
      totalDistanceMeters: Math.round(totalPolylineDistance),
      progressFraction: Math.round(progressFraction * 1000) / 1000,
      offRoute,
      deviationMeters: Math.round(minDistance),
      effectiveDeviationMeters: Math.round(effectiveDeviation),
      nearestSegmentIndex: nearestIndex,
    };
  }
}

module.exports = RouteProgressService;
