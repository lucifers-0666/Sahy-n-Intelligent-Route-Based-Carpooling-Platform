const test = require('node:test');
const assert = require('node:assert/strict');
const LocationProcessor = require('../src/services/location/locationProcessor');
const LocationCacheService = require('../src/services/location/locationCacheService');
const RouteProgressService = require('../src/services/location/routeProgressService');
const MockRoutesProvider = require('../src/services/location/providers/mockRoutesProvider');
const { encodePolyline } = require('../src/utils/polylineUtils');

test('LOCATION SUBSYSTEM: Haversine distance matches known geographic displacement', () => {
  const distMeters = LocationProcessor.haversineDistance(23.0225, 72.5714, 22.3039, 70.8022);
  const distKm = distMeters / 1000.0;
  assert.ok(distKm >= 195 && distKm <= 208, `Expected distance ~200km, got ${distKm.toFixed(2)} km`);

  const zeroDist = LocationProcessor.haversineDistance(23.0225, 72.5714, 23.0225, 72.5714);
  assert.equal(zeroDist, 0);
});

test('LOCATION SUBSYSTEM: Payload validation sanitizes valid telemetry and rejects invalid data', () => {
  const valid = {
    rideId: 'ride_123',
    latitude: 23.0225,
    longitude: 72.5714,
    accuracy: 12.5,
    speed: 45.0,
    heading: 180.0,
    timestamp: new Date().toISOString(),
  };

  const res = LocationProcessor.validatePayload(valid);
  assert.equal(res.valid, true);
  assert.equal(res.sanitized.rideId, 'ride_123');
  assert.equal(res.sanitized.latitude, 23.0225);
  assert.equal(res.sanitized.heading, 180.0);

  const noRide = LocationProcessor.validatePayload({ latitude: 23.0, longitude: 72.0 });
  assert.equal(noRide.valid, false);

  const badLat = LocationProcessor.validatePayload({ rideId: 'r1', latitude: 120.0, longitude: 72.0 });
  assert.equal(badLat.valid, false);

  const oldTime = new Date(Date.now() - 120000).toISOString();
  const stale = LocationProcessor.validatePayload({ ...valid, timestamp: oldTime });
  assert.equal(stale.valid, false);
  assert.match(stale.error, /STALE_COORDINATE/);
});

test('LOCATION SUBSYSTEM: Outlier detection flags physically impossible speed jumps', () => {
  const t0 = new Date('2026-09-16T12:00:00.000Z');
  const t1 = new Date('2026-09-16T12:00:05.000Z');

  const p1 = { latitude: 23.0225, longitude: 72.5714, timestamp: t0.toISOString() };
  const pNormal = { latitude: 23.0234, longitude: 72.5714, timestamp: t1.toISOString() };
  assert.equal(LocationProcessor.isOutlier(p1, pNormal, 160), false);

  const pImpossible = { latitude: 23.2000, longitude: 72.5714, timestamp: t1.toISOString() };
  assert.equal(LocationProcessor.isOutlier(p1, pImpossible, 160), true);
});

test('LOCATION SUBSYSTEM: LocationCacheService quantizes keys and manages TTL', () => {
  LocationCacheService.clear();

  const origin = { latitude: 23.022567, longitude: 72.571412 };
  const dest = { latitude: 22.303988, longitude: 70.802245 };

  const key1 = LocationCacheService.generateRouteKey(origin, dest, { trafficAware: true });
  assert.match(key1, /^route:23\.023,72\.571:22\.304,70\.802:t1$/);

  LocationCacheService.set(key1, { distanceMeters: 219000 }, 2);
  assert.deepEqual(LocationCacheService.get(key1), { distanceMeters: 219000 });

  LocationCacheService.clear();
  assert.equal(LocationCacheService.get(key1), null);
});

test('LOCATION SUBSYSTEM: RouteProgressService calculates remaining distance and off-route state', () => {
  const origin = { latitude: 23.0225, longitude: 72.5714 };
  const midPoint = { latitude: 22.6632, longitude: 71.6868 };
  const destination = { latitude: 22.3039, longitude: 70.8022 };

  const encoded = encodePolyline([origin, midPoint, destination]);

  // Case 1: Driver exactly at origin
  const progOrigin = RouteProgressService.evaluateProgress(origin, encoded, destination);
  assert.equal(progOrigin.offRoute, false);
  assert.ok(progOrigin.progressFraction <= 0.1);

  // Case 2: Driver at midpoint
  const progMid = RouteProgressService.evaluateProgress(midPoint, encoded, destination);
  assert.equal(progMid.offRoute, false);
  assert.ok(progMid.progressFraction >= 0.35 && progMid.progressFraction <= 0.65);

  // Case 3: Driver significantly off-route (10 km away in Vadodara)
  const offRoutePos = { latitude: 22.3072, longitude: 73.1812, accuracy: 10.0 };
  const progOff = RouteProgressService.evaluateProgress(offRoutePos, encoded, destination, {
    offRouteThresholdMeters: 100.0,
  });
  assert.equal(progOff.offRoute, true);
  assert.ok(progOff.deviationMeters > 50000);
});

test('LOCATION SUBSYSTEM: MockRoutesProvider returns deterministic routes and matrix', async () => {
  const provider = new MockRoutesProvider();
  assert.equal(provider.isConfigured(), true);

  const route = await provider.calculateRoute(
    { latitude: 23.0225, longitude: 72.5714, name: 'Ahmedabad' },
    { latitude: 22.3039, longitude: 70.8022, name: 'Rajkot' }
  );

  assert.equal(route.success, true);
  assert.ok(route.distanceMeters > 200000);
  assert.ok(route.durationSeconds > 0);
  assert.ok(route.encodedPolyline.length > 0);

  const matrix = await provider.calculateRouteMatrix(
    [{ latitude: 23.0225, longitude: 72.5714 }],
    [{ latitude: 22.3039, longitude: 70.8022 }]
  );
  assert.equal(matrix.success, true);
  assert.equal(matrix.rows.length, 1);
  assert.equal(matrix.rows[0].elements.length, 1);
});
