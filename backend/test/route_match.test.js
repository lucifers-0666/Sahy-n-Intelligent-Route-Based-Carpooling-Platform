const test = require('node:test');
const assert = require('node:assert');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../src/app');
const User = require('../src/models/User');
const Vehicle = require('../src/models/Vehicle');
const Ride = require('../src/models/Ride');
const polylineUtils = require('../src/utils/polylineUtils');
const routeMatchService = require('../src/services/routeMatchService');

// Coordinate hubs for Gujarat
const BHUJ = { latitude: 23.2420, longitude: 69.6669 };
const ANJAR = { latitude: 23.1132, longitude: 70.0278 };
const GANDHIDHAM = { latitude: 23.0753, longitude: 70.1337 };
const AHMEDABAD = { latitude: 23.0225, longitude: 72.5714 };
const RAJKOT = { latitude: 22.3039, longitude: 70.8022 };
const SURAT = { latitude: 21.1702, longitude: 72.8311 };

test('Intelligent Route Match Engine - Polyline and Geometric Utilities', async (t) => {
  await t.test('calculateDistanceKm returns accurate distance between coordinates', () => {
    // Distance between Bhuj and Anjar is approx 41 km
    const dist = polylineUtils.calculateDistanceKm(
      BHUJ.latitude,
      BHUJ.longitude,
      ANJAR.latitude,
      ANJAR.longitude
    );
    assert(dist > 35 && dist < 45, `Expected ~41km, got ${dist}`);

    // Identical coordinates return 0
    const zeroDist = polylineUtils.calculateDistanceKm(
      BHUJ.latitude,
      BHUJ.longitude,
      BHUJ.latitude,
      BHUJ.longitude
    );
    assert.strictEqual(zeroDist, 0);
  });

  await t.test('decodePolyline and encodePolyline roundtrip preserves points', () => {
    const originalPoints = [BHUJ, ANJAR, GANDHIDHAM, AHMEDABAD];
    const encoded = polylineUtils.encodePolyline(originalPoints);
    assert(typeof encoded === 'string' && encoded.length > 0);

    const decoded = polylineUtils.decodePolyline(encoded);
    assert.strictEqual(decoded.length, originalPoints.length);

    for (let i = 0; i < originalPoints.length; i++) {
      assert(Math.abs(decoded[i].latitude - originalPoints[i].latitude) < 0.0001);
      assert(Math.abs(decoded[i].longitude - originalPoints[i].longitude) < 0.0001);
    }
  });

  await t.test('decodePolyline safely handles null/undefined/empty string', () => {
    assert.deepStrictEqual(polylineUtils.decodePolyline(''), []);
    assert.deepStrictEqual(polylineUtils.decodePolyline(null), []);
    assert.deepStrictEqual(polylineUtils.decodePolyline(undefined), []);
  });

  await t.test('minDistanceToPolylineKm accurately identifies nearest point', () => {
    const route = [BHUJ, ANJAR, GANDHIDHAM, AHMEDABAD];
    // Anjar is directly on this route
    const match = polylineUtils.minDistanceToPolylineKm(ANJAR, route);
    assert(match.distanceKm < 0.1, `Expected <0.1km, got ${match.distanceKm}`);
  });

  await t.test('calculateRouteOverlap detects high overlap for subsegment and low for diverging', () => {
    // Driver route: Bhuj -> Anjar -> Gandhidham -> Ahmedabad
    const driverRoute = [
      BHUJ,
      { latitude: 23.18, longitude: 69.85 },
      ANJAR,
      GANDHIDHAM,
      { latitude: 23.05, longitude: 71.35 },
      AHMEDABAD,
    ];

    // Passenger: Anjar -> Ahmedabad (along the driver route)
    const passengerOnRoute = [
      ANJAR,
      GANDHIDHAM,
      { latitude: 23.05, longitude: 71.35 },
      AHMEDABAD,
    ];

    const overlapGood = polylineUtils.calculateRouteOverlap({
      passengerPoints: passengerOnRoute,
      driverPoints: driverRoute,
      toleranceKm: 5,
    });
    assert(overlapGood.overlapPercentage >= 80, `Expected >= 80%, got ${overlapGood.overlapPercentage}`);

    // Passenger: Bhuj -> Rajkot (diverges from Gandhidham down to Rajkot)
    const passengerDiverging = [
      BHUJ,
      ANJAR,
      RAJKOT,
    ];

    const overlapPoor = polylineUtils.calculateRouteOverlap({
      passengerPoints: passengerDiverging,
      driverPoints: driverRoute,
      toleranceKm: 5,
    });
    assert(overlapPoor.overlapPercentage < overlapGood.overlapPercentage);
  });
});

test('Intelligent Route Match Engine - Scoring Components and Determinism', async (t) => {
  await t.test('pickup deviation scoring follows required thresholds', () => {
    // 0-1 km: 95-100
    assert.strictEqual(routeMatchService.calculatePickupScore(0), 100);
    assert(routeMatchService.calculatePickupScore(0.5) >= 95);
    // 1-3 km: 80-95
    assert(routeMatchService.calculatePickupScore(2.0) >= 80 && routeMatchService.calculatePickupScore(2.0) <= 95);
    // 3-5 km: 60-80
    assert(routeMatchService.calculatePickupScore(4.0) >= 60 && routeMatchService.calculatePickupScore(4.0) <= 80);
    // 5-10 km: 25-60
    assert(routeMatchService.calculatePickupScore(7.0) >= 25 && routeMatchService.calculatePickupScore(7.0) <= 60);
    // > 10 km: <= 25
    assert(routeMatchService.calculatePickupScore(15.0) <= 25);
  });

  await t.test('destination deviation scoring mirrors pickup curve', () => {
    assert.strictEqual(routeMatchService.calculateDestinationScore(0), 100);
    assert(routeMatchService.calculateDestinationScore(0.8) >= 95);
    assert(routeMatchService.calculateDestinationScore(2.5) >= 80);
  });

  await t.test('time compatibility degrades with minute discrepancy', () => {
    assert.strictEqual(routeMatchService.calculateTimeScore(0), 100);
    assert(routeMatchService.calculateTimeScore(10) >= 95);
    assert(routeMatchService.calculateTimeScore(25) >= 80 && routeMatchService.calculateTimeScore(25) <= 95);
    assert(routeMatchService.calculateTimeScore(45) >= 60 && routeMatchService.calculateTimeScore(45) <= 80);
    assert(routeMatchService.calculateTimeScore(90) <= 60);
  });

  await t.test('driver reliability provides neutral score for unrated driver', () => {
    // New driver with no rating history must get neutral score, not 100
    const newDriver = { rating: 0, ratingCount: 0, isVerified: false };
    const scoreNew = routeMatchService.calculateReliabilityScore(newDriver);
    assert.strictEqual(scoreNew, 70);

    // Highly rated driver gets high score
    const topDriver = { rating: 4.9, ratingCount: 20, isVerified: true };
    const scoreTop = routeMatchService.calculateReliabilityScore(topDriver);
    assert(scoreTop >= 95);
  });

  await t.test('seat availability score respects requested count', () => {
    // 1 seat requested, 5 available -> 100
    assert.strictEqual(routeMatchService.calculateSeatScore(5, 1), 100);
    // 4 seats requested, 4 available -> 80
    assert.strictEqual(routeMatchService.calculateSeatScore(4, 4), 80);
    // 3 seats requested, 2 available -> 0
    assert.strictEqual(routeMatchService.calculateSeatScore(2, 3), 0);
  });

  await t.test('evaluateRideMatch is completely deterministic', () => {
    const candidate = {
      origin: BHUJ,
      destination: AHMEDABAD,
      route: {
        encodedPolyline: polylineUtils.encodePolyline([BHUJ, ANJAR, GANDHIDHAM, AHMEDABAD]),
      },
      departureTime: new Date('2026-09-10T08:00:00Z'),
      availableSeats: 3,
      driver: { rating: 4.8, ratingCount: 15, isVerified: true },
    };

    const params = {
      passengerOrigin: ANJAR,
      passengerDestination: AHMEDABAD,
      passengerDepartureTime: new Date('2026-09-10T08:15:00Z'),
      passengerPoints: [ANJAR, GANDHIDHAM, AHMEDABAD],
      candidateRide: candidate,
      requestedSeats: 1,
    };

    const res1 = routeMatchService.evaluateRideMatch(params);
    const res2 = routeMatchService.evaluateRideMatch(params);

    assert.strictEqual(res1.score, res2.score);
    assert.strictEqual(res1.grade, res2.grade);
    assert.deepStrictEqual(res1.factors, res2.factors);
    assert.deepStrictEqual(res1.metrics, res2.metrics);
    assert.deepStrictEqual(res1.reasons, res2.reasons);
  });

  await t.test('match grades span the required score bands', () => {
    assert.strictEqual(routeMatchService.getMatchGrade(95), 'Excellent Match');
    assert.strictEqual(routeMatchService.getMatchGrade(85), 'Very Good Match');
    assert.strictEqual(routeMatchService.getMatchGrade(75), 'Good Match');
    assert.strictEqual(routeMatchService.getMatchGrade(65), 'Fair Match');
    assert.strictEqual(routeMatchService.getMatchGrade(45), 'Weak Match');
  });

  await t.test('handles candidate missing polyline gracefully without crashing', () => {
    const candidateWithoutRoute = {
      origin: BHUJ,
      destination: AHMEDABAD,
      route: null,
      departureTime: new Date('2026-09-10T08:00:00Z'),
      availableSeats: 2,
      driver: null,
    };

    const result = routeMatchService.evaluateRideMatch({
      passengerOrigin: BHUJ,
      passengerDestination: AHMEDABAD,
      passengerDepartureTime: new Date('2026-09-10T08:00:00Z'),
      candidateRide: candidateWithoutRoute,
      requestedSeats: 1,
    });

    assert(typeof result.score === 'number' && !isNaN(result.score));
    assert(typeof result.grade === 'string');
    assert(Array.isArray(result.reasons) && result.reasons.length >= 2);
  });
});

let mongoServer;
let server;
let baseUrl;

test.before(async () => {
  try {
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri);
  } catch (err) {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/sahyan_phase7_test';
    await mongoose.connect(mongoUri);
  }

  await User.deleteMany({});
  await Vehicle.deleteMany({});
  await Ride.deleteMany({});

  server = app.listen(0);
  baseUrl = `http://localhost:${server.address().port}/api/v1`;

  // Create Drivers
  const driverTop = await User.create({
    name: 'Vikram Joshi',
    email: 'vikram.p7@example.com',
    phone: '+919876543210',
    password: 'Password123@#',
    city: 'Bhuj',
    rating: 4.8,
    ratingCount: 22,
    isVerified: true,
  });

  const driverNew = await User.create({
    name: 'Karan Shah',
    email: 'karan.p7@example.com',
    phone: '+919876543211',
    password: 'Password123@#',
    city: 'Bhuj',
    rating: 0,
    ratingCount: 0,
    isVerified: false,
  });

  const vehicleA = await Vehicle.create({
    owner: driverTop._id,
    vehicleType: 'suv',
    make: 'Hyundai',
    model: 'Creta',
    year: 2023,
    registrationNumber: 'GJ12AA1111',
    color: 'White',
    seatCapacity: 4,
    status: 'active',
  });

  const vehicleB = await Vehicle.create({
    owner: driverNew._id,
    vehicleType: 'hatchback',
    make: 'Maruti',
    model: 'Swift',
    year: 2022,
    registrationNumber: 'GJ12BB2222',
    color: 'Silver',
    seatCapacity: 4,
    status: 'active',
  });

  const baseDepTime = new Date(Date.now() + 2 * 3600 * 1000); // 2 hours from now

  // Ride 1: Bhuj -> Ahmedabad (passes Anjar), 3 seats, top driver
  const polylineBhujAhm = polylineUtils.encodePolyline([
    BHUJ,
    { latitude: 23.18, longitude: 69.85 },
    ANJAR,
    GANDHIDHAM,
    { latitude: 23.05, longitude: 71.35 },
    AHMEDABAD,
  ]);

  await Ride.create({
    driver: driverTop._id,
    vehicle: vehicleA._id,
    origin: {
      name: 'Bhuj Bus Station',
      latitude: BHUJ.latitude,
      longitude: BHUJ.longitude,
      point: { type: 'Point', coordinates: [BHUJ.longitude, BHUJ.latitude] },
    },
    destination: {
      name: 'Ahmedabad Railway Station',
      latitude: AHMEDABAD.latitude,
      longitude: AHMEDABAD.longitude,
      point: { type: 'Point', coordinates: [AHMEDABAD.longitude, AHMEDABAD.latitude] },
    },
    route: {
      encodedPolyline: polylineBhujAhm,
      distanceMeters: 380000,
      durationSeconds: 25200,
    },
    departureTime: baseDepTime,
    estimatedArrivalTime: new Date(baseDepTime.getTime() + 7 * 3600 * 1000),
    availableSeats: 3,
    totalSeats: 4,
    bookedSeats: 0,
    contributionPerSeat: 450,
    status: 'scheduled',
  });

  // Ride 2: Bhuj -> Rajkot (diverges from Ahmedabad route)
  const polylineBhujRajkot = polylineUtils.encodePolyline([
    BHUJ,
    ANJAR,
    RAJKOT,
  ]);

  await Ride.create({
    driver: driverNew._id,
    vehicle: vehicleB._id,
    origin: {
      name: 'Bhuj Bus Station',
      latitude: BHUJ.latitude,
      longitude: BHUJ.longitude,
      point: { type: 'Point', coordinates: [BHUJ.longitude, BHUJ.latitude] },
    },
    destination: {
      name: 'Rajkot Trikon Baug',
      latitude: RAJKOT.latitude,
      longitude: RAJKOT.longitude,
      point: { type: 'Point', coordinates: [RAJKOT.longitude, RAJKOT.latitude] },
    },
    route: {
      encodedPolyline: polylineBhujRajkot,
      distanceMeters: 230000,
      durationSeconds: 18000,
    },
    departureTime: new Date(baseDepTime.getTime() + 60 * 60 * 1000), // 1 hour difference
    estimatedArrivalTime: new Date(baseDepTime.getTime() + 6 * 3600 * 1000),
    availableSeats: 2,
    totalSeats: 4,
    bookedSeats: 0,
    contributionPerSeat: 350,
    status: 'scheduled',
  });
});

test.after(async () => {
  if (server) await server.close();
  if (mongoose.connection.readyState !== 0) await mongoose.disconnect();
  if (mongoServer) await mongoServer.stop();
});

test('Intelligent Route Match API - GET /api/v1/rides/search matches and rankings', async (t) => {
  await t.test('returns explainable match details and ranks best matching route first', async () => {
    // Passenger searching: Anjar to Ahmedabad (should match Bhuj->Ahmedabad much higher than Bhuj->Rajkot)
    const url = `${baseUrl}/rides/search?originLat=${ANJAR.latitude}&originLng=${ANJAR.longitude}&destLat=${AHMEDABAD.latitude}&destLng=${AHMEDABAD.longitude}&maxPickupDistanceKm=60&maxDropDistanceKm=60&seats=1`;

    const res = await fetch(url);
    assert.strictEqual(res.status, 200);

    const data = await res.json();
    assert.strictEqual(data.success, true);
    assert(data.results.length >= 1, 'Expected at least 1 candidate ride result');

    const topResult = data.results[0];

    // Verify structured match object is present
    assert(topResult.match, 'Expected match object in result');
    assert(typeof topResult.match.score === 'number', 'Expected numeric match score');
    assert(typeof topResult.match.grade === 'string', 'Expected string match grade');
    assert(topResult.match.factors, 'Expected factors breakdown');
    assert(typeof topResult.match.factors.routeOverlap === 'number');
    assert(typeof topResult.match.factors.pickupDeviation === 'number');
    assert(typeof topResult.match.factors.destinationDeviation === 'number');
    assert(typeof topResult.match.factors.timeCompatibility === 'number');
    assert(typeof topResult.match.factors.driverReliability === 'number');
    assert(typeof topResult.match.factors.seatAvailability === 'number');

    // Verify explainable reasons
    assert(Array.isArray(topResult.match.reasons), 'Expected array of reasons');
    assert(topResult.match.reasons.length >= 2, 'Expected at least 2 explainable reasons');

    // Backward compatibility fields
    assert(typeof topResult.pickupDistanceKm === 'number');
    assert(typeof topResult.destinationDistanceKm === 'number');
    assert(typeof topResult.departureDifferenceMinutes === 'number');

    // Verify destination alignment: Top result destination should be Ahmedabad, not Rajkot
    assert.strictEqual(topResult.ride.destination.name, 'Ahmedabad Railway Station');
    assert(topResult.match.score >= 80, `Expected score >= 80%, got ${topResult.match.score}`);
  });

  await t.test('scenario: diverging destination scores lower than direct route', async () => {
    // Search for Rajkot destination
    const url = `${baseUrl}/rides/search?originLat=${BHUJ.latitude}&originLng=${BHUJ.longitude}&destLat=${RAJKOT.latitude}&destLng=${RAJKOT.longitude}&maxPickupDistanceKm=30&maxDropDistanceKm=30&seats=1`;

    const res = await fetch(url);
    assert.strictEqual(res.status, 200);

    const data = await res.json();
    assert.strictEqual(data.success, true);

    // Bhuj -> Rajkot should be top result when passenger seeks Rajkot
    const topResult = data.results[0];
    assert.strictEqual(topResult.ride.destination.name, 'Rajkot Trikon Baug');
  });

  await t.test('returns empty results array when no rides match geospatial or seats', async () => {
    // Surat coordinates far outside search radius
    const url = `${baseUrl}/rides/search?originLat=${SURAT.latitude}&originLng=${SURAT.longitude}&destLat=${AHMEDABAD.latitude}&destLng=${AHMEDABAD.longitude}&maxPickupDistanceKm=10&maxDropDistanceKm=10&seats=1`;

    const res = await fetch(url);
    assert.strictEqual(res.status, 200);

    const data = await res.json();
    assert.strictEqual(data.success, true);
    assert.strictEqual(data.results.length, 0);
  });

  await t.test('rejects invalid coordinate inputs with 400', async () => {
    const url = `${baseUrl}/rides/search?originLat=999&originLng=0`;
    const res = await fetch(url);
    assert.strictEqual(res.status, 400);

    const data = await res.json();
    assert.strictEqual(data.success, false);
  });
});
