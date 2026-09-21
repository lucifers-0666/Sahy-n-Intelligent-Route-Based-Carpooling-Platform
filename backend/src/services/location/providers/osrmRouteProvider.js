const https = require('https');
const RouteProvider = require('../routeProvider');

/**
 * Free & Open-Source OSRM (Open Source Routing Machine) Provider Implementation
 *
 * Directly interfaces with the public OSRM driving profile:
 * https://router.project-osrm.org/route/v1/driving/
 *
 * Features:
 * - 100% Free / Open Source (OpenStreetMap road network data)
 * - Zero API key required
 * - Zero Google Cloud / billing / credit card required
 * - Real turn-by-turn driving polylines, highway geometries, distances and durations
 */
class OsrmRouteProvider extends RouteProvider {
  constructor(baseUrl = 'https://router.project-osrm.org') {
    super();
    this.baseUrl = baseUrl.replace(/\/+$/, '');
  }

  isConfigured() {
    return true;
  }

  /**
   * Helper to perform HTTPS GET requests with custom User-Agent
   */
  _get(url) {
    return new Promise((resolve, reject) => {
      const parsed = new URL(url);
      const reqOptions = {
        hostname: parsed.hostname,
        path: parsed.pathname + parsed.search,
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Sahyan-Carpooling-Platform/1.0 (mca-college-project)',
        },
      };

      const req = https.request(reqOptions, (res) => {
        let data = '';
        res.on('data', (chunk) => {
          data += chunk;
        });
        res.on('end', () => {
          try {
            const parsedJson = JSON.parse(data);
            resolve({ statusCode: res.statusCode, body: parsedJson });
          } catch (err) {
            reject(new Error(`Invalid JSON response from OSRM: ${data.slice(0, 100)}`));
          }
        });
      });

      req.on('error', (err) => {
        reject(err);
      });

      req.setTimeout(8000, () => {
        req.destroy();
        reject(new Error('OSRM routing request timed out after 8 seconds'));
      });

      req.end();
    });
  }

  /**
   * Calculate driving route between origin and destination via OSRM
   * @param {Object} origin - { latitude, longitude, name }
   * @param {Object} destination - { latitude, longitude, name }
   * @param {Object} options - { waypoints, stopovers }
   * @returns {Promise<Object>}
   */
  async calculateRoute(origin, destination, options = {}) {
    try {
      const originLat = Number(origin.latitude);
      const originLon = Number(origin.longitude);
      const destLat = Number(destination.latitude);
      const destLon = Number(destination.longitude);

      if (isNaN(originLat) || isNaN(originLon) || isNaN(destLat) || isNaN(destLon)) {
        return {
          success: false,
          error: 'INVALID_COORDINATES',
          message: 'Origin and destination coordinates must be valid numbers.',
        };
      }

      // Semicolon-separated longitude,latitude pairs for OSRM format: lon,lat;lon,lat
      const coordSegments = [`${originLon},${originLat}`];

      const intermediate = options.waypoints || options.stopovers || [];
      if (Array.isArray(intermediate)) {
        for (const wp of intermediate) {
          const wLat = Number(wp.latitude);
          const wLon = Number(wp.longitude);
          if (!isNaN(wLat) && !isNaN(wLon)) {
            coordSegments.push(`${wLon},${wLat}`);
          }
        }
      }

      coordSegments.push(`${destLon},${destLat}`);

      const coordString = coordSegments.join(';');
      const url = `${this.baseUrl}/route/v1/driving/${coordString}?overview=full&geometries=polyline&steps=true&annotations=distance,duration`;

      const response = await this._get(url);

      if (response.statusCode !== 200 || !response.body || response.body.code !== 'Ok' || !response.body.routes || response.body.routes.length === 0) {
        return {
          success: false,
          error: 'ROUTING_FAILED',
          message: response.body && response.body.message ? response.body.message : 'No driving route found between coordinates.',
        };
      }

      const primaryRoute = response.body.routes[0];
      const distanceMeters = Math.round(primaryRoute.distance || 0);
      const durationSeconds = Math.round(primaryRoute.duration || 0);
      const encodedPolyline = primaryRoute.geometry || '';

      const distanceKm = (distanceMeters / 1000).toFixed(1);
      const hours = Math.floor(durationSeconds / 3600);
      const minutes = Math.round((durationSeconds % 3600) / 60);
      const durationText = hours > 0 ? `${hours}h ${minutes}m` : `${minutes} mins`;

      let summary = 'Highway Corridor';
      if (primaryRoute.legs && primaryRoute.legs.length > 0 && primaryRoute.legs[0].summary) {
        summary = primaryRoute.legs[0].summary;
      }

      return {
        success: true,
        apiKeyConfigured: true,
        isFreeOpenSource: true,
        provider: 'OSRM',
        distanceMeters,
        durationSeconds,
        distanceText: `${distanceKm} km`,
        durationText,
        encodedPolyline,
        startAddress: origin.name || 'Origin',
        endAddress: destination.name || 'Destination',
        summary,
      };
    } catch (err) {
      return {
        success: false,
        error: 'OSRM_SERVICE_ERROR',
        message: `Failed to calculate route: ${err.message}`,
      };
    }
  }

  /**
   * Calculate distance matrix between multiple points using OSRM Table Service
   */
  async calculateRouteMatrix(origins, destinations) {
    try {
      const allPoints = [];
      const originIndices = [];
      const destIndices = [];

      origins.forEach((o, i) => {
        allPoints.push(`${o.longitude},${o.latitude}`);
        originIndices.push(i);
      });

      const offset = origins.length;
      destinations.forEach((d, j) => {
        allPoints.push(`${d.longitude},${d.latitude}`);
        destIndices.push(offset + j);
      });

      const coordString = allPoints.join(';');
      const sourcesParam = originIndices.join(';');
      const destinationsParam = destIndices.join(';');
      const url = `${this.baseUrl}/table/v1/driving/${coordString}?sources=${sourcesParam}&destinations=${destinationsParam}&annotations=duration,distance`;

      const response = await this._get(url);

      if (response.statusCode === 200 && response.body && response.body.code === 'Ok') {
        const rows = response.body.distances.map((rowDistances, rIdx) => {
          const elements = rowDistances.map((dist, cIdx) => {
            const dur = response.body.durations ? response.body.durations[rIdx][cIdx] : 0;
            return {
              status: dist !== null ? 'OK' : 'ZERO_RESULTS',
              distance: { value: Math.round(dist || 0) },
              duration: { value: Math.round(dur || 0) },
            };
          });
          return { elements };
        });

        return { success: true, rows };
      }

      return { success: false, error: 'MATRIX_CALCULATION_FAILED' };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }
}

module.exports = OsrmRouteProvider;
