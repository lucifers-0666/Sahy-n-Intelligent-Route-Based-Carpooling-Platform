const https = require('https');

/**
 * Free & Open-Source OpenStreetMap Nominatim Geocoding and Places Service
 *
 * Implements:
 * - Place autocomplete / address search
 * - Reverse geocoding (coordinates -> readable address)
 * - In-memory caching to minimize external network requests
 * - Rate limiting queue conforming to OpenStreetMap Usage Policy (max 1 req/sec)
 * - Zero API key, zero Google Cloud billing, zero credit card requirement
 */
class NominatimService {
  constructor() {
    this.baseUrl = 'https://nominatim.openstreetmap.org';
    this.cache = new Map();
    this.maxCacheSize = 250;
    this.lastRequestTimestamp = 0;
    this.minRequestIntervalMs = 1000; // 1 second interval to respect OSM community guidelines
  }

  isConfigured() {
    return true; // Completely free, no API key needed
  }

  /**
   * Helper to perform HTTPS GET requests with mandatory Nominatim User-Agent
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
          'User-Agent': 'Sahyan-Carpooling-MCA-Project/1.0 (contact: mca-carpooling@college.edu)',
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
            reject(new Error(`Failed to parse Nominatim JSON: ${data.slice(0, 100)}`));
          }
        });
      });

      req.on('error', (err) => {
        reject(err);
      });

      req.setTimeout(8000, () => {
        req.destroy();
        reject(new Error('Nominatim geocoding request timed out'));
      });

      req.end();
    });
  }

  /**
   * Rate-limited request throttle
   */
  async _throttledGet(url) {
    const now = Date.now();
    const timeSinceLast = now - this.lastRequestTimestamp;
    if (timeSinceLast < this.minRequestIntervalMs) {
      const delay = this.minRequestIntervalMs - timeSinceLast;
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
    this.lastRequestTimestamp = Date.now();
    return this._get(url);
  }

  /**
   * Autocomplete places search using OpenStreetMap Nominatim
   * @param {string} input - search text query
   * @returns {Promise<Object>}
   */
  async autocompletePlaces(input) {
    const query = String(input || '').trim();
    if (query.length < 2) {
      return { success: true, predictions: [], apiKeyConfigured: true, isFreeOpenSource: true };
    }

    const cacheKey = `search:${query.toLowerCase()}`;
    if (this.cache.has(cacheKey)) {
      return {
        success: true,
        predictions: this.cache.get(cacheKey),
        cached: true,
        apiKeyConfigured: true,
        isFreeOpenSource: true,
      };
    }

    try {
      const url = `${this.baseUrl}/search?q=${encodeURIComponent(query)}&format=json&addressdetails=1&limit=6&countrycodes=in`;
      const response = await this._throttledGet(url);

      if (response.statusCode === 200 && Array.isArray(response.body)) {
        const predictions = response.body.map((item) => {
          const address = item.address || {};
          const cityOrDistrict = address.city || address.town || address.village || address.state_district || address.county || '';
          const state = address.state || '';

          let mainText = item.name;
          if (!mainText || mainText === item.display_name) {
            mainText = cityOrDistrict || (item.display_name ? item.display_name.split(',')[0].trim() : query);
          }

          let secondaryText = item.display_name;
          if (cityOrDistrict && state) {
            secondaryText = `${cityOrDistrict}, ${state}, India`;
          }

          return {
            placeId: String(item.osm_id || item.place_id || ''),
            description: item.display_name || '',
            mainText,
            secondaryText,
            latitude: parseFloat(item.lat),
            longitude: parseFloat(item.lon),
            type: item.type || 'place',
          };
        });

        // Store in cache with LRU eviction
        if (this.cache.size >= this.maxCacheSize) {
          const oldestKey = this.cache.keys().next().value;
          this.cache.delete(oldestKey);
        }
        this.cache.set(cacheKey, predictions);

        return {
          success: true,
          apiKeyConfigured: true,
          isFreeOpenSource: true,
          predictions,
        };
      }

      return {
        success: false,
        error: 'NOMINATIM_ERROR',
        message: 'Could not fetch location suggestions from OpenStreetMap.',
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

  /**
   * Reverse geocode coordinates to human-readable address
   * @param {number} latitude
   * @param {number} longitude
   */
  async reverseGeocode(latitude, longitude) {
    const lat = Number(latitude);
    const lon = Number(longitude);
    if (isNaN(lat) || isNaN(lon)) {
      return { success: false, error: 'INVALID_COORDINATES' };
    }

    const cacheKey = `rev:${lat.toFixed(4)},${lon.toFixed(4)}`;
    if (this.cache.has(cacheKey)) {
      return { success: true, result: this.cache.get(cacheKey), cached: true };
    }

    try {
      const url = `${this.baseUrl}/reverse?lat=${lat}&lon=${lon}&format=json&addressdetails=1`;
      const response = await this._throttledGet(url);

      if (response.statusCode === 200 && response.body) {
        const item = response.body;
        const address = item.address || {};
        const formatted = {
          placeId: String(item.osm_id || item.place_id || ''),
          name: item.name || address.road || address.suburb || address.city || 'Current Location',
          address: item.display_name || '',
          city: address.city || address.town || address.village || address.state_district || '',
          state: address.state || '',
          latitude: lat,
          longitude: lon,
        };

        if (this.cache.size >= this.maxCacheSize) {
          const oldestKey = this.cache.keys().next().value;
          this.cache.delete(oldestKey);
        }
        this.cache.set(cacheKey, formatted);

        return { success: true, result: formatted };
      }

      return { success: false, error: 'REVERSE_GEOCODE_FAILED' };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }
}

module.exports = new NominatimService();
