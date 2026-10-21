const https = require('https');
const osrmRouteProvider = require('./location/providers/osrmRouteProvider');

/**
 * Google Maps / Routes Platform Routing Service
 *
 * Provides real road turn-by-turn driving polylines with automated fallback
 * to high-precision OSRM driving engine.
 */
class GoogleMapsService {
  constructor() {
    this.apiKey = process.env.GOOGLE_MAPS_API_KEY || '';
  }

  isGoogleConfigured() {
    return Boolean(this.apiKey && this.apiKey.trim().length > 0);
  }

  /**
   * Calculate driving route with real road turn-by-turn polyline.
   * If Google Maps API Key is available, uses Google Directions API.
   * Otherwise falls back to OSRM (Open Source Routing Machine).
   */
  async calculateRoute(origin, destination, options = {}) {
    if (this.isGoogleConfigured()) {
      try {
        const googleResult = await this._calculateGoogleRoute(origin, destination, options);
        if (googleResult && googleResult.success) {
          return googleResult;
        }
      } catch (err) {
        console.warn('[GoogleMapsService] Google Directions failed, falling back to OSRM:', err.message);
      }
    }

    // High-precision OSRM Real Road Engine
    return await osrmRouteProvider.calculateRoute(origin, destination, options);
  }

  _calculateGoogleRoute(origin, destination, options = {}) {
    return new Promise((resolve, reject) => {
      const originStr = `${origin.latitude},${origin.longitude}`;
      const destStr = `${destination.latitude},${destination.longitude}`;
      let waypointsStr = '';

      const intermediate = options.waypoints || options.stopovers || [];
      if (Array.isArray(intermediate) && intermediate.length > 0) {
        const wpCoords = intermediate
          .filter(wp => !isNaN(wp.latitude) && !isNaN(wp.longitude))
          .map(wp => `${wp.latitude},${wp.longitude}`);
        if (wpCoords.length > 0) {
          waypointsStr = `&waypoints=${encodeURIComponent(wpCoords.join('|'))}`;
        }
      }

      const url = `https://maps.googleapis.com/maps/api/directions/json?origin=${encodeURIComponent(originStr)}&destination=${encodeURIComponent(destStr)}${waypointsStr}&mode=driving&key=${encodeURIComponent(this.apiKey)}`;

      https.get(url, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          try {
            const body = JSON.parse(data);
            if (body.status !== 'OK' || !body.routes || body.routes.length === 0) {
              return resolve({
                success: false,
                error: body.status,
                message: body.error_message || 'No route found via Google Directions',
              });
            }

            const primary = body.routes[0];
            let totalDist = 0;
            let totalDur = 0;
            for (const leg of primary.legs || []) {
              totalDist += leg.distance ? leg.distance.value : 0;
              totalDur += leg.duration ? leg.duration.value : 0;
            }

            const encodedPolyline = primary.overview_polyline ? primary.overview_polyline.points : '';
            resolve({
              success: true,
              apiKeyConfigured: true,
              provider: 'GoogleMaps',
              distanceMeters: totalDist,
              durationSeconds: totalDur,
              distanceText: `${(totalDist / 1000).toFixed(1)} km`,
              durationText: `${Math.round(totalDur / 60)} mins`,
              encodedPolyline,
              startAddress: origin.name || '',
              endAddress: destination.name || '',
              summary: primary.summary || 'Highway Corridor',
            });
          } catch (e) {
            reject(e);
          }
        });
      }).on('error', reject);
    });
  }
}

module.exports = new GoogleMapsService();
