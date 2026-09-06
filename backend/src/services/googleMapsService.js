const https = require('https');

/**
 * Service for Google Maps Platform Directions and Places API
 */
class GoogleMapsService {
  constructor() {
    this.apiKey = process.env.GOOGLE_MAPS_API_KEY || '';
  }

  isConfigured() {
    const key = process.env.GOOGLE_MAPS_API_KEY || '';
    return key.length > 0 && key !== 'your_google_maps_api_key_here';
  }

  /**
   * Helper to perform HTTPS GET requests
   */
  _get(url) {
    return new Promise((resolve, reject) => {
      https
        .get(url, (res) => {
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
        })
        .on('error', (err) => {
          reject(err);
        });
    });
  }

  /**
   * Calculate route using Google Directions API
   * @param {Object} origin - { latitude, longitude, name }
   * @param {Object} destination - { latitude, longitude, name }
   */
  async calculateRoute(origin, destination) {
    if (!this.isConfigured()) {
      return {
        success: false,
        error: 'GOOGLE_MAPS_KEY_NOT_CONFIGURED',
        message: 'Google Maps API key is not configured. Set GOOGLE_MAPS_API_KEY in backend/.env to calculate live routes.',
        apiKeyConfigured: false,
      };
    }

    const key = process.env.GOOGLE_MAPS_API_KEY;
    const originParam = `${origin.latitude},${origin.longitude}`;
    const destParam = `${destination.latitude},${destination.longitude}`;
    const url = `https://maps.googleapis.com/maps/api/directions/json?origin=${encodeURIComponent(
      originParam
    )}&destination=${encodeURIComponent(destParam)}&mode=driving&key=${key}`;

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
          durationSeconds: leg.duration.value,
          distanceText: leg.distance.text,
          durationText: leg.duration.text,
          encodedPolyline: route.overview_polyline ? route.overview_polyline.points : '',
          startAddress: leg.start_address,
          endAddress: leg.end_address,
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

  /**
   * Autocomplete place search using Google Places Autocomplete API
   * @param {string} input - search text query
   */
  async autocompletePlaces(input) {
    if (!this.isConfigured()) {
      return {
        success: false,
        error: 'GOOGLE_MAPS_KEY_NOT_CONFIGURED',
        message: 'Google Maps API key is not configured. Set GOOGLE_MAPS_API_KEY in backend/.env',
        apiKeyConfigured: false,
        predictions: [],
      };
    }

    const key = process.env.GOOGLE_MAPS_API_KEY;
    const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(
      input
    )}&components=country:in&key=${key}`;

    try {
      const response = await this._get(url);

      if (response.status === 'OK') {
        const predictions = (response.predictions || []).map((p) => ({
          description: p.description,
          placeId: p.place_id,
          mainText: p.structured_formatting ? p.structured_formatting.main_text : p.description,
          secondaryText: p.structured_formatting ? p.structured_formatting.secondary_text : '',
        }));

        return {
          success: true,
          apiKeyConfigured: true,
          predictions,
        };
      }

      return {
        success: false,
        error: response.status,
        message: response.error_message || `Places API returned status: ${response.status}`,
        predictions: [],
      };
    } catch (err) {
      return {
        success: false,
        error: 'NETWORK_ERROR',
        message: err.message,
        predictions: [],
      };
    }
  }
}

module.exports = new GoogleMapsService();
