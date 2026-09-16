const https = require('https');
const RouteProvider = require('../routeProvider');

/**
 * Google Routes API Provider implementation
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

  _get(url, headers = {}) {
    return new Promise((resolve, reject) => {
      const parsedUrl = new URL(url);
      const reqOptions = {
        hostname: parsedUrl.hostname,
        path: parsedUrl.pathname + parsedUrl.search,
        method: 'GET',
        headers: {
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
            resolve(parsed);
          } catch (err) {
            reject(new Error('Invalid JSON response from Google Maps API.'));
          }
        });
      });

      req.on('error', (err) => {
        reject(err);
      });
      req.setTimeout(8000, () => {
        req.destroy(new Error('Google Routes API request timed out.'));
      });
      req.end();
    });
  }

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
    const originParam = `${origin.latitude},${origin.longitude}`;
    const destParam = `${destination.latitude},${destination.longitude}`;
    
    let waypointsParam = '';
    if (Array.isArray(options.waypoints) && options.waypoints.length > 0) {
      const wpStr = options.waypoints
        .map((wp) => `${wp.latitude},${wp.longitude}`)
        .join('|');
      waypointsParam = `&waypoints=${encodeURIComponent(wpStr)}`;
    }

    const trafficModel = options.trafficAware ? '&departure_time=now' : '';
    const url = `https://maps.googleapis.com/maps/api/directions/json?origin=${encodeURIComponent(
      originParam
    )}&destination=${encodeURIComponent(destParam)}${waypointsParam}${trafficModel}&mode=driving&key=${key}`;

    try {
      const response = await this._get(url);

      if (response.status === 'OK' && response.routes && response.routes.length > 0) {
        const route = response.routes[0];
        const leg = route.legs && route.legs.length > 0 ? route.legs[0] : null;

        if (!leg) {
          return {
            success: false,
            error: 'NO_LEG_DATA',
            message: 'Route found but leg data is unavailable.',
          };
        }

        return {
          success: true,
          apiKeyConfigured: true,
          distanceMeters: leg.distance.value,
          durationSeconds: leg.duration_in_traffic ? leg.duration_in_traffic.value : leg.duration.value,
          distanceText: leg.distance.text,
          durationText: leg.duration_in_traffic ? leg.duration_in_traffic.text : leg.duration.text,
          encodedPolyline: route.overview_polyline ? route.overview_polyline.points : '',
          startAddress: leg.start_address,
          endAddress: leg.end_address,
          summary: route.summary || 'Primary Highway',
        };
      }

      if (response.status === 'ZERO_RESULTS') {
        return {
          success: false,
          error: 'ZERO_RESULTS',
          message: 'No driving route could be found between the selected origin and destination.',
        };
      }

      return {
        success: false,
        error: response.status || 'GOOGLE_MAPS_ERROR',
        message: response.error_message || `Google Maps API returned status: ${response.status}`,
      };
    } catch (err) {
      return {
        success: false,
        error: 'NETWORK_ERROR',
        message: `Failed to connect to Google Maps API: ${err.message}`,
      };
    }
  }

  async calculateRouteMatrix(origins, destinations) {
    if (!this.isConfigured()) {
      return {
        success: false,
        error: 'GOOGLE_MAPS_KEY_NOT_CONFIGURED',
      };
    }
    const key = this.apiKey || process.env.GOOGLE_MAPS_API_KEY;
    const originsParam = origins.map((o) => `${o.latitude},${o.longitude}`).join('|');
    const destsParam = destinations.map((d) => `${d.latitude},${d.longitude}`).join('|');
    const url = `https://maps.googleapis.com/maps/api/distancematrix/json?origins=${encodeURIComponent(
      originsParam
    )}&destinations=${encodeURIComponent(destsParam)}&mode=driving&key=${key}`;

    try {
      const response = await this._get(url);
      if (response.status === 'OK') {
        return {
          success: true,
          rows: response.rows,
        };
      }
      return { success: false, error: response.status };
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
      if (response.status === 'OK' && response.results && response.results.length > 0) {
        const first = response.results[0];
        return {
          success: true,
          formattedAddress: first.formatted_address,
          latitude: first.geometry.location.lat,
          longitude: first.geometry.location.lng,
          placeId: first.place_id,
        };
      }
      return { success: false, error: response.status };
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
      if (response.status === 'OK' && response.results && response.results.length > 0) {
        const first = response.results[0];
        return {
          success: true,
          formattedAddress: first.formatted_address,
          placeId: first.place_id,
        };
      }
      return { success: false, error: response.status };
    } catch (err) {
      return { success: false, error: 'NETWORK_ERROR', message: err.message };
    }
  }
}

module.exports = GoogleRoutesProvider;
