/**
 * Reusable utility for Google encoded polyline manipulation,
 * geographic distance calculations, point-to-segment projections,
 * and route overlap evaluation.
 */

/**
 * Calculate Haversine distance in kilometers between two coordinates
 */
function calculateDistanceKm(lat1, lon1, lat2, lon2) {
  if (lat1 === lat2 && lon1 === lon2) return 0;

  const R = 6371; // Earth's radius in km
  const toRad = Math.PI / 180;
  const dLat = (lat2 - lat1) * toRad;
  const dLon = (lon2 - lon1) * toRad;

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * toRad) *
      Math.cos(lat2 * toRad) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * Decode a Google Maps encoded polyline string into an array of coordinate objects
 * @param {string} encoded - Encoded polyline string
 * @returns {Array<{latitude: number, longitude: number}>}
 */
function decodePolyline(encoded) {
  if (!encoded || typeof encoded !== 'string') return [];

  const points = [];
  let index = 0;
  const len = encoded.length;
  let lat = 0;
  let lng = 0;

  while (index < len) {
    let b;
    let shift = 0;
    let result = 0;
    do {
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20 && index < len);
    const dlat = (result & 1) !== 0 ? ~(result >> 1) : result >> 1;
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      if (index >= len) break;
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20 && index < len);
    const dlng = (result & 1) !== 0 ? ~(result >> 1) : result >> 1;
    lng += dlng;

    points.push({
      latitude: lat / 1e5,
      longitude: lng / 1e5,
    });
  }

  return points;
}

/**
 * Encode an array of coordinate objects into a Google Maps encoded polyline string
 * @param {Array<{latitude: number, longitude: number}>} points
 * @returns {string}
 */
function encodePolyline(points) {
  if (!Array.isArray(points) || points.length === 0) return '';

  let str = '';
  let prevLat = 0;
  let prevLng = 0;

  function encodeValue(val) {
    let v = val < 0 ? ~(val << 1) : val << 1;
    while (v >= 0x20) {
      str += String.fromCharCode((0x20 | (v & 0x1f)) + 63);
      v >>= 5;
    }
    str += String.fromCharCode(v + 63);
  }

  for (const pt of points) {
    const lat = Math.round(pt.latitude * 1e5);
    const lng = Math.round(pt.longitude * 1e5);

    encodeValue(lat - prevLat);
    encodeValue(lng - prevLng);

    prevLat = lat;
    prevLng = lng;
  }

  return str;
}

/**
 * Calculate total length of a polyline in kilometers
 */
function calculateRouteLengthKm(points) {
  if (!Array.isArray(points) || points.length < 2) return 0;
  let total = 0;
  for (let i = 0; i < points.length - 1; i++) {
    total += calculateDistanceKm(
      points[i].latitude,
      points[i].longitude,
      points[i + 1].latitude,
      points[i + 1].longitude
    );
  }
  return total;
}

/**
 * Sample an evenly spaced subset of points along a polyline
 * @param {Array<{latitude: number, longitude: number}>} points
 * @param {number} maxSamples
 */
function samplePoints(points, maxSamples = 25) {
  if (!Array.isArray(points) || points.length === 0) return [];
  if (points.length <= maxSamples) return points;

  const sampled = [];
  const step = (points.length - 1) / (maxSamples - 1);

  for (let i = 0; i < maxSamples; i++) {
    const idx = Math.min(Math.round(i * step), points.length - 1);
    sampled.push(points[idx]);
  }

  return sampled;
}

/**
 * Perpendicular distance from a point to a line segment in kilometers
 */
function distancePointToSegmentKm(p, a, b) {
  const segLengthSq =
    Math.pow(b.latitude - a.latitude, 2) + Math.pow(b.longitude - a.longitude, 2);

  if (segLengthSq === 0) {
    return calculateDistanceKm(p.latitude, p.longitude, a.latitude, a.longitude);
  }

  // Projection parameter t of point p onto line segment a-b
  let t =
    ((p.latitude - a.latitude) * (b.latitude - a.latitude) +
      (p.longitude - a.longitude) * (b.longitude - a.longitude)) /
    segLengthSq;

  t = Math.max(0, Math.min(1, t));

  const projLat = a.latitude + t * (b.latitude - a.latitude);
  const projLng = a.longitude + t * (b.longitude - a.longitude);

  return calculateDistanceKm(p.latitude, p.longitude, projLat, projLng);
}

/**
 * Find the minimum distance from a point to an entire polyline,
 * along with the relative fractional position (0.0 to 1.0) along the polyline.
 * @param {Object} point - { latitude, longitude }
 * @param {Array<Object>} polylinePoints
 */
function minDistanceToPolylineKm(point, polylinePoints) {
  if (!Array.isArray(polylinePoints) || polylinePoints.length === 0) {
    return { distanceKm: Infinity, segmentIndex: -1, fractionalProgress: 0 };
  }

  if (polylinePoints.length === 1) {
    return {
      distanceKm: calculateDistanceKm(
        point.latitude,
        point.longitude,
        polylinePoints[0].latitude,
        polylinePoints[0].longitude
      ),
      segmentIndex: 0,
      fractionalProgress: 0,
    };
  }

  let minDistance = Infinity;
  let bestSegment = 0;

  for (let i = 0; i < polylinePoints.length - 1; i++) {
    const dist = distancePointToSegmentKm(
      point,
      polylinePoints[i],
      polylinePoints[i + 1]
    );
    if (dist < minDistance) {
      minDistance = dist;
      bestSegment = i;
    }
  }

  const fractionalProgress =
    polylinePoints.length > 1
      ? bestSegment / (polylinePoints.length - 1)
      : 0;

  return {
    distanceKm: minDistance,
    segmentIndex: bestSegment,
    fractionalProgress,
  };
}

/**
 * Calculate route overlap percentage between passenger points and driver polyline
 * @param {Object} params
 * @param {Array<Object>} params.passengerPoints
 * @param {Array<Object>} params.driverPoints
 * @param {number} [params.toleranceKm=2.5]
 * @returns {{overlapPercentage: number, coveredCount: number, totalCount: number, isDirectionValid: boolean}}
 */
function calculateRouteOverlap({
  passengerPoints,
  driverPoints,
  toleranceKm = 2.5,
}) {
  if (
    !Array.isArray(passengerPoints) ||
    passengerPoints.length === 0 ||
    !Array.isArray(driverPoints) ||
    driverPoints.length === 0
  ) {
    return {
      overlapPercentage: 0,
      coveredCount: 0,
      totalCount: 0,
      isDirectionValid: false,
    };
  }

  // Sample passenger points if large
  const sampledPassenger = samplePoints(passengerPoints, 25);
  let coveredCount = 0;

  let firstMatchedProgress = -1;
  let lastMatchedProgress = -1;

  for (let i = 0; i < sampledPassenger.length; i++) {
    const match = minDistanceToPolylineKm(sampledPassenger[i], driverPoints);
    if (match.distanceKm <= toleranceKm) {
      coveredCount++;
      if (firstMatchedProgress === -1) {
        firstMatchedProgress = match.fractionalProgress;
      }
      lastMatchedProgress = match.fractionalProgress;
    }
  }

  const totalCount = sampledPassenger.length;
  let overlapPercentage = Math.round((coveredCount / totalCount) * 100);

  // Direction check: passenger origin must map to an earlier point on driver route than passenger destination
  const isDirectionValid =
    firstMatchedProgress === -1 ||
    lastMatchedProgress === -1 ||
    lastMatchedProgress >= firstMatchedProgress - 0.05; // 5% margin for nearby stops

  if (!isDirectionValid && overlapPercentage > 30) {
    // Reverse direction penalty
    overlapPercentage = Math.round(overlapPercentage * 0.2);
  }

  return {
    overlapPercentage: Math.max(0, Math.min(100, overlapPercentage)),
    coveredCount,
    totalCount,
    isDirectionValid,
  };
}

/**
 * Generate a sampled straight route between origin and destination
 * Used as a deterministic fallback when external routing service is offline
 */
function generateFallbackRoute(origin, destination, numPoints = 20) {
  if (!origin || !destination) return [];
  if (numPoints <= 1) return [origin];

  const points = [];
  const dLat = (destination.latitude - origin.latitude) / (numPoints - 1);
  const dLng = (destination.longitude - origin.longitude) / (numPoints - 1);

  for (let i = 0; i < numPoints; i++) {
    points.push({
      latitude: origin.latitude + dLat * i,
      longitude: origin.longitude + dLng * i,
    });
  }

  return points;
}

module.exports = {
  calculateDistanceKm,
  decodePolyline,
  encodePolyline,
  calculateRouteLengthKm,
  samplePoints,
  distancePointToSegmentKm,
  minDistanceToPolylineKm,
  calculateRouteOverlap,
  generateFallbackRoute,
};
