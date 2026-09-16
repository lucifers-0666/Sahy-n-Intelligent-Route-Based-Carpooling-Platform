/**
 * Location Preprocessing & Validation Utility for Backend Telematics
 */
class LocationProcessor {
  /**
   * Pure mathematical Haversine distance in meters
   */
  static haversineDistance(lat1, lon1, lat2, lon2) {
    const R = 6371000; // Earth radius in meters
    const toRad = (deg) => (deg * Math.PI) / 180.0;
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  /**
   * Validate raw telemetry payload structure and values
   * @param {Object} payload
   * @returns {{ valid: boolean, error?: string, sanitized?: Object }}
   */
  static validatePayload(payload) {
    if (!payload || typeof payload !== 'object') {
      return { valid: false, error: 'Payload must be a non-null object' };
    }

    const { rideId, latitude, longitude, accuracy, speed, heading, timestamp } = payload;

    if (!rideId || typeof rideId !== 'string') {
      return { valid: false, error: 'rideId is required and must be a string' };
    }

    const lat = Number(latitude);
    const lng = Number(longitude);

    if (isNaN(lat) || lat < -90 || lat > 90) {
      return { valid: false, error: 'latitude must be a number between -90 and 90' };
    }

    if (isNaN(lng) || lng < -180 || lng > 180) {
      return { valid: false, error: 'longitude must be a number between -180 and 180' };
    }

    const acc = accuracy != null ? Number(accuracy) : 10.0;
    const spd = speed != null ? Math.max(0, Number(speed)) : 0.0;
    const hdg = heading != null ? ((Number(heading) % 360) + 360) % 360 : 0.0;

    let time = new Date();
    if (timestamp) {
      const parsedTime = new Date(timestamp);
      if (!isNaN(parsedTime.getTime())) {
        // Drop coordinates older than 60 seconds or in the future > 30s
        const ageSec = (Date.now() - parsedTime.getTime()) / 1000;
        if (ageSec > 60) {
          return { valid: false, error: 'STALE_COORDINATE: older than 60 seconds' };
        }
        if (ageSec < -30) {
          return { valid: false, error: 'INVALID_TIMESTAMP: timestamp is in the future' };
        }
        time = parsedTime;
      }
    }

    return {
      valid: true,
      sanitized: {
        rideId,
        latitude: lat,
        longitude: lng,
        accuracy: acc,
        speed: spd,
        heading: hdg,
        timestamp: time.toISOString(),
      },
    };
  }

  /**
   * Check if consecutive coordinate jump is an outlier (exceeds physical speed limit)
   */
  static isOutlier(prevPoint, currentPoint, maxSpeedKmh = 160) {
    if (!prevPoint) return false;
    const distMeters = this.haversineDistance(
      prevPoint.latitude,
      prevPoint.longitude,
      currentPoint.latitude,
      currentPoint.longitude
    );
    const timeDeltaSec = (new Date(currentPoint.timestamp).getTime() - new Date(prevPoint.timestamp).getTime()) / 1000;
    if (timeDeltaSec <= 0) return distMeters > 50;

    const speedMps = distMeters / timeDeltaSec;
    const speedKmh = speedMps * 3.6;
    return speedKmh > maxSpeedKmh;
  }
}

module.exports = LocationProcessor;
