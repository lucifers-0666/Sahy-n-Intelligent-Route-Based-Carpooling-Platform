const https = require('https');
const RouteProvider = require('../routeProvider');

/**
 * Modern Google Routes API (v2) Provider Implementation
 *
 * Direct integration with:
 * - POST https://routes.googleapis.com/directions/v2:computeRoutes
 * - POST https://routes.googleapis.com/distanceMatrix/v2:computeRouteMatrix
 * Using strict response field masks and vehicle-aware emission/routing modes.
 */
class GoogleRoutesProvider extends RouteProvider {
  constructor(apiKey) {
    super();
    this.apiKey = apiKey || process.env.GOOGLE_MAPS_API_KEY || '';
  }

  isConfigured() {
    const key = this.apiKey || process.env.GOOGLE_MAPS_API_KEY || '';
    return key.length > 0 && key !== 'your_google_maps_api_key_here';
  }

  /**
   * Helper to perform HTTPS POST requests with JSON payload and custom headers
   */
  _post(url, payload, headers = {}) {
    return new Promise((resolve, reject) => {
      const parsedUrl = new URL(url);
      const dataStr = JSON.stringify(payload);

      const reqOptions = {
        hostname: parsedUrl.hostname,
        path: parsedUrl.pathname + parsedUrl.search,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(dataStr),
          'Accept': 'application/json',
          ...headers,
        },
      };

      const req = https.request(reqOptions, (res) => {
        let data = '';
        res.on('data', (chunk) => {
          data += chunk;
        });
        res.on('end', () => {
          try {
            const parsed = JSON.parse(data);
            resolve({ statusCode: res.statusCode, body: parsed });
          } catch (err) {
            reject(new Error('Invalid JSON response from Google Routes API.'));
          }
        });
      });

      req.on('error', (err) => {
        reject(err);
      });
      req.setTimeout(9000, () => {
        req.destroy(new Error('Google Routes API request timed out.'));
      });

      req.write(dataStr);
      req.end();
    });
  }

  /**
   * Helper to perform HTTPS GET requests
   */
  _get(url) {
    return new Promise((resolve, reject) => {
      const parsedUrl = new URL(url);
      const reqOptions = {
        hostname: parsedUrl.hostname,
        path: parsedUrl.pathname + parsedUrl.search,
        method: 'GET',
        headers: { 'Accept': 'application/json' },
      };

      const req = https.request(reqOptions, (res) => {
        let data = '';
        res.on('data', (chunk) => {
          data += chunk;
        });
        res.on('end', () => {
          try {
            const parsed = JSON.parse(data);
            resolve({ statusCode: res.statusCode, body: parsed });
          } catch (err) {
            reject(new Error('Invalid JSON response from Google Maps API.'));
          }
        });
      });

      req.on('error', (err) => {
        reject(err);
      });
      req.setTimeout(8000, () => {
        req.destroy(new Error('Google Maps request timed out.'));
      });
      req.end();
    });
  }

  /**
   * Parse duration string (e.g. "1245s") into integer seconds
   */
  _parseDurationSeconds(durationStr) {
    if (!durationStr) return 0;
    if (typeof durationStr === 'number') return durationStr;
    const match = durationStr.toString().match(/^(\d+(\.\d+)?)s?$/);
    if (match) {
      return Math.round(parseFloat(match[1]));
    }
    return 0;
  }

  /**
   * Map Sahyān vehicle type to Google Routes API travelMode
   */
  _mapTravelMode(vehicleType) {
    switch ((vehicleType || '').toLowerCase()) {
      case 'motorcycle':
      case 'scooter':
      case 'electric_scooter':
        return 'TWO_WHEELER';
      default:
        return 'DRIVE';
    }
  }

  /**
   * Calculate driving route using Google Routes API v2
   * @param {Object} origin - { latitude, longitude, name }
   * @param {Object} destination - { latitude, longitude, name }
   * @param {Object} options - { waypoints, trafficAware, alternatives, vehicleType, avoidTolls, avoidHighways }
   */
  async calculateRoute(origin, destination, options = {}) {
    if (!this.isConfigured()) {
      return {
        success: false,
        error: 'GOOGLE_MAPS_KEY_NOT_CONFIGURED',
        message: 'Google Maps API key is not configured. Set GOOGLE_MAPS_API_KEY in backend/.env',
        apiKeyConfigured: false,
      };
    }

    const key = this.apiKey || process.env.GOOGLE_MAPS_API_KEY;
    const url = 'https://routes.googleapis.com/directions/v2:computeRoutes';

    const travelMode = this._mapTravelMode(options.vehicleType);
    const isElectric = (options.vehicleType || '').toLowerCase() === 'ev' ||
      (options.vehicleType || '').toLowerCase() === 'electric_car';

    const requestBody = {
      origin: {
        location: {
          latLng: {
            latitude: Number(origin.latitude),
            longitude: Number(origin.longitude),
          },
        },
      },
      destination: {
        location: {
          latLng: {
            latitude: Number(destination.latitude),
            longitude: Number(destination.longitude),
          },
        },
      },
      travelMode,
      routingPreference: options.trafficAware !== false ? 'TRAFFIC_AWARE' : 'TRAFFIC_UNAWARE',
      computeAlternativeRoutes: options.alternatives === true,
      routeModifiers: {
        avoidTolls: options.avoidTolls === true,
        avoidHighways: options.avoidHighways === true,
        avoidFerries: true,
        ...(isElectric ? { vehicleInfo: { emissionType: 'ELECTRIC' } } : {}),
      },
      languageCode: 'en-US',
      units: 'METRIC',
    };

    if (Array.isArray(options.waypoints) && options.waypoints.length > 0) {
      requestBody.intermediates = options.waypoints.map((wp) => ({
        location: {
          latLng: {
            latitude: Number(wp.latitude),
            longitude: Number(wp.longitude),
          },
        },
      }));
    }

    const headers = {
      'X-Goog-Api-Key': key,
      'X-Goog-FieldMask':
        'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.description,routes.legs,routes.travelAdvisory',
    };

    try {
      const response = await this._post(url, requestBody, headers);

      if (response.statusCode === 200 && response.body && Array.isArray(response.body.routes) && response.body.routes.length > 0) {
        const primaryRoute = response.body.routes[0];
        const distanceMeters = primaryRoute.distanceMeters || 0;
        const durationSeconds = this._parseDurationSeconds(primaryRoute.duration);

        const alternatives = response.body.routes.slice(1).map((alt) => ({
          distanceMeters: alt.distanceMeters || 0,
          durationSeconds: this._parseDurationSeconds(alt.duration),
          encodedPolyline: alt.polyline ? alt.polyline.encodedPolyline : '',
          description: alt.description || 'Alternative Route',
        }));

        return {
          success: true,
          apiKeyConfigured: true,
          distanceMeters,
          durationSeconds,
          distanceText: `${(distanceMeters / 1000).toFixed(1)} km`,
          durationText: `${Math.round(durationSeconds / 60)} mins`,
          encodedPolyline: primaryRoute.polyline ? primaryRoute.polyline.encodedPolyline : '',
          summary: primaryRoute.description || 'Primary Corridor',
          startAddress: origin.name || 'Origin',
          endAddress: destination.name || 'Destination',
          alternatives,
        };
      }

      if (response.body && response.body.error) {
        return {
          success: false,
          error: response.body.error.status || 'ROUTES_API_ERROR',
          message: response.body.error.message || 'Google Routes API error.',
        };
      }

      return {
        success: false,
        error: 'ZERO_RESULTS',
        message: 'No driving route found between origin and destination.',
      };
    } catch (err) {
      return {
        success: false,
        error: 'NETWORK_ERROR',
        message: `Failed to connect to Google Routes API: ${err.message}`,
      };
    }
  }

  /**
   * Calculate distance matrix using Google Routes API v2 computeRouteMatrix
   */
  async calculateRouteMatrix(origins, destinations, options = {}) {
    if (!this.isConfigured()) {
      return { success: false, error: 'GOOGLE_MAPS_KEY_NOT_CONFIGURED' };
    }

    const key = this.apiKey || process.env.GOOGLE_MAPS_API_KEY;
    const url = 'https://routes.googleapis.com/distanceMatrix/v2:computeRouteMatrix';

    const requestBody = {
      origins: origins.map((orig) => ({
        waypoint: {
          location: {
            latLng: {
              latitude: Number(orig.latitude),
              longitude: Number(orig.longitude),
            },
          },
        },
      })),
      destinations: destinations.map((dest) => ({
        waypoint: {
          location: {
            latLng: {
              latitude: Number(dest.latitude),
              longitude: Number(dest.longitude),
            },
          },
        },
      })),
      travelMode: this._mapTravelMode(options.vehicleType),
      routingPreference: 'TRAFFIC_AWARE',
    };

    const headers = {
      'X-Goog-Api-Key': key,
      'X-Goog-FieldMask': 'originIndex,destinationIndex,status,distanceMeters,duration',
    };

    try {
      const response = await this._post(url, requestBody, headers);
      if (response.statusCode === 200) {
        return {
          success: true,
          matrix: response.body,
        };
      }
      return {
        success: false,
        error: response.body?.error?.status || 'ROUTE_MATRIX_ERROR',
        message: response.body?.error?.message,
      };
    } catch (err) {
      return { success: false, error: 'NETWORK_ERROR', message: err.message };
    }
  }

  async geocode(address) {
    if (!this.isConfigured()) {
      return { success: false, error: 'GOOGLE_MAPS_KEY_NOT_CONFIGURED' };
    }
    const key = this.apiKey || process.env.GOOGLE_MAPS_API_KEY;
    const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(
      address
    )}&components=country:in&key=${key}`;

    try {
      const response = await this._get(url);
      if (response.statusCode === 200 && response.body?.status === 'OK' && response.body.results?.length > 0) {
        const first = response.body.results[0];
        return {
          success: true,
          formattedAddress: first.formatted_address,
          latitude: first.geometry.location.lat,
          longitude: first.geometry.location.lng,
          placeId: first.place_id,
        };
      }
      return { success: false, error: response.body?.status || 'GEOCODE_ERROR' };
    } catch (err) {
      return { success: false, error: 'NETWORK_ERROR', message: err.message };
    }
  }

  async reverseGeocode(latitude, longitude) {
    if (!this.isConfigured()) {
      return { success: false, error: 'GOOGLE_MAPS_KEY_NOT_CONFIGURED' };
    }
    const key = this.apiKey || process.env.GOOGLE_MAPS_API_KEY;
    const url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${latitude},${longitude}&key=${key}`;

    try {
      const response = await this._get(url);
      if (response.statusCode === 200 && response.body?.status === 'OK' && response.body.results?.length > 0) {
        const first = response.body.results[0];
        return {
          success: true,
          formattedAddress: first.formatted_address,
          placeId: first.place_id,
        };
      }
      return { success: false, error: response.body?.status || 'REVERSE_GEOCODE_ERROR' };
    } catch (err) {
      return { success: false, error: 'NETWORK_ERROR', message: err.message };
    }
  }
}

module.exports = GoogleRoutesProvider;
