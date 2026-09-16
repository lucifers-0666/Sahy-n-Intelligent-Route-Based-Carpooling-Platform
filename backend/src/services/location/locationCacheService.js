/**
 * Location and Route Cache Service with Geographic Coordinate Quantization
 */
class LocationCacheService {
  constructor(defaultTtlSeconds = 900) {
    this.defaultTtlMs = defaultTtlSeconds * 1000;
    /** @type {Map<string, { data: any, expiresAt: number }>} */
    this.cache = new Map();
  }

  /**
   * Quantize coordinate to 3 decimal places (~110m grid cell) for route caching
   */
  _quantizeCoord(val) {
    return (Math.round(val * 1000) / 1000).toFixed(3);
  }

  generateRouteKey(origin, destination, options = {}) {
    const origCell = `${this._quantizeCoord(origin.latitude)},${this._quantizeCoord(origin.longitude)}`;
    const destCell = `${this._quantizeCoord(destination.latitude)},${this._quantizeCoord(destination.longitude)}`;
    const traffic = options.trafficAware ? 't1' : 't0';
    return `route:${origCell}:${destCell}:${traffic}`;
  }

  get(key) {
    const entry = this.cache.get(key);
    if (!entry) return null;
    if (Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      return null;
    }
    return entry.data;
  }

  set(key, data, ttlSeconds) {
    const ttlMs = (ttlSeconds != null ? ttlSeconds : this.defaultTtlMs / 1000) * 1000;
    this.cache.set(key, {
      data,
      expiresAt: Date.now() + ttlMs,
    });
  }

  clear() {
    this.cache.clear();
  }

  size() {
    return this.cache.size;
  }
}

module.exports = new LocationCacheService();
