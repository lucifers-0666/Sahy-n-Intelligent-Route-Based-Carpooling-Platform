const dns = require('dns');
dns.setServers(['8.8.8.8', '8.8.4.4']);
const path = require('path');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');

dotenv.config({ path: path.join(__dirname, '../.env') });

const User = require('../src/models/User');
const Vehicle = require('../src/models/Vehicle');
const Ride = require('../src/models/Ride');
const Booking = require('../src/models/Booking');
const { encodePolyline } = require('../src/utils/polylineUtils');

/**
 * Generate intermediate interpolated coordinates between two points for realistic polylines
 */
function interpolatePoints(p1, p2, count = 5) {
  const points = [];
  for (let i = 0; i <= count; i++) {
    const fraction = i / count;
    points.push({
      latitude: Number((p1.lat + fraction * (p2.lat - p1.lat)).toFixed(6)),
      longitude: Number((p1.lng + fraction * (p2.lng - p1.lng)).toFixed(6)),
    });
  }
  return points;
}

function buildRoutePolyline(waypoints) {
  const allPoints = [];
  for (let i = 0; i < waypoints.length - 1; i++) {
    const segment = interpolatePoints(waypoints[i], waypoints[i + 1], 6);
    if (i > 0) segment.shift(); // avoid duplicate join points
    allPoints.push(...segment);
  }
  return encodePolyline(allPoints);
}

async function seedDemoCorridors() {
  console.log('[Seed] Connecting to MongoDB...');
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('[Seed] Connected successfully.');

  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash('Password123!', salt);

  // ── Drivers ─────────────────────────────────────────────────────────────
  // 1. Rohit Patel (Rajkot -> Ahmedabad Sedan)
  const driverRohit = await User.findOneAndUpdate(
    { email: 'rohit.driver@example.com' },
    {
      name: 'Rohit Patel',
      email: 'rohit.driver@example.com',
      phone: '+919876510001',
      password: hashedPassword,
      city: 'Rajkot',
      isVerified: true,
      capabilities: { canDrive: true, canRide: true },
      driverProfile: {
        licenseNumber: 'GJ0320190012345',
        onboardingStatus: 'approved',
        verifiedAt: new Date(),
      },
      rating: { average: 4.92, count: 48 },
    },
    { upsert: true, new: true }
  );

  const vehicleRohit = await Vehicle.findOneAndUpdate(
    { registrationNumber: 'GJ03AB1234' },
    {
      owner: driverRohit._id,
      registrationNumber: 'GJ03AB1234',
      vehicleType: 'sedan',
      make: 'Honda',
      model: 'City ZX',
      year: 2023,
      color: 'Pearl White',
      seatCapacity: 4,
      status: 'active',
    },
    { upsert: true, new: true }
  );

  // 2. Meet Vora (Rajkot -> Jamnagar Hatchback)
  const driverMeet = await User.findOneAndUpdate(
    { email: 'meet.driver@example.com' },
    {
      name: 'Meet Vora',
      email: 'meet.driver@example.com',
      phone: '+919876510002',
      password: hashedPassword,
      city: 'Rajkot',
      isVerified: true,
      capabilities: { canDrive: true, canRide: true },
      driverProfile: {
        licenseNumber: 'GJ0320210054321',
        onboardingStatus: 'approved',
        verifiedAt: new Date(),
      },
      rating: { average: 4.88, count: 24 },
    },
    { upsert: true, new: true }
  );

  const vehicleMeet = await Vehicle.findOneAndUpdate(
    { registrationNumber: 'GJ03CD5678' },
    {
      owner: driverMeet._id,
      registrationNumber: 'GJ03CD5678',
      vehicleType: 'hatchback',
      make: 'Maruti Suzuki',
      model: 'Swift ZXi',
      year: 2023,
      color: 'Magma Grey',
      seatCapacity: 4,
      status: 'active',
    },
    { upsert: true, new: true }
  );

  // 3. Harsh Mehta (Ahmedabad -> Surat SUV)
  const driverHarsh = await User.findOneAndUpdate(
    { email: 'harsh.driver@example.com' },
    {
      name: 'Harsh Mehta',
      email: 'harsh.driver@example.com',
      phone: '+919876510003',
      password: hashedPassword,
      city: 'Ahmedabad',
      isVerified: true,
      capabilities: { canDrive: true, canRide: true },
      driverProfile: {
        licenseNumber: 'GJ0120200088990',
        onboardingStatus: 'approved',
        verifiedAt: new Date(),
      },
      rating: { average: 4.95, count: 62 },
    },
    { upsert: true, new: true }
  );

  const vehicleHarsh = await Vehicle.findOneAndUpdate(
    { registrationNumber: 'GJ01EF3456' },
    {
      owner: driverHarsh._id,
      registrationNumber: 'GJ01EF3456',
      vehicleType: 'suv',
      make: 'Hyundai',
      model: 'Creta SX(O)',
      year: 2024,
      color: 'Titan Grey',
      seatCapacity: 4,
      status: 'active',
    },
    { upsert: true, new: true }
  );

  // 4. Jayesh Jadeja (Bhuj -> Ahmedabad SUV)
  const driverJayesh = await User.findOneAndUpdate(
    { email: 'jayesh.driver@example.com' },
    {
      name: 'Jayesh Jadeja',
      email: 'jayesh.driver@example.com',
      phone: '+919876510004',
      password: hashedPassword,
      city: 'Bhuj',
      isVerified: true,
      capabilities: { canDrive: true, canRide: true },
      driverProfile: {
        licenseNumber: 'GJ1220180077665',
        onboardingStatus: 'approved',
        verifiedAt: new Date(),
      },
      rating: { average: 4.85, count: 31 },
    },
    { upsert: true, new: true }
  );

  const vehicleJayesh = await Vehicle.findOneAndUpdate(
    { registrationNumber: 'GJ12GH7890' },
    {
      owner: driverJayesh._id,
      registrationNumber: 'GJ12GH7890',
      vehicleType: 'suv',
      make: 'Mahindra',
      model: 'XUV700 AX7',
      year: 2023,
      color: 'Midnight Black',
      seatCapacity: 6,
      status: 'active',
    },
    { upsert: true, new: true }
  );

  // 5. Divyesh Joshi (Rajkot Urban EV)
  const driverDivyesh = await User.findOneAndUpdate(
    { email: 'divyesh.driver@example.com' },
    {
      name: 'Divyesh Joshi',
      email: 'divyesh.driver@example.com',
      phone: '+919876510005',
      password: hashedPassword,
      city: 'Rajkot',
      isVerified: true,
      capabilities: { canDrive: true, canRide: true },
      driverProfile: {
        licenseNumber: 'GJ0320220033221',
        onboardingStatus: 'approved',
        verifiedAt: new Date(),
      },
      rating: { average: 4.91, count: 19 },
    },
    { upsert: true, new: true }
  );

  const vehicleDivyesh = await Vehicle.findOneAndUpdate(
    { registrationNumber: 'GJ03EV9988' },
    {
      owner: driverDivyesh._id,
      registrationNumber: 'GJ03EV9988',
      vehicleType: 'ev',
      make: 'Tata',
      model: 'Tiago EV',
      year: 2024,
      color: 'Teal Blue',
      seatCapacity: 4,
      status: 'active',
    },
    { upsert: true, new: true }
  );

  // 6. Ananya Sharma (Ahmedabad -> GIFT City EV)
  const driverAnanya = await User.findOneAndUpdate(
    { email: 'ananya.driver@example.com' },
    {
      name: 'Ananya Sharma',
      email: 'ananya.driver@example.com',
      phone: '+919876500033',
      password: hashedPassword,
      city: 'Ahmedabad',
      isVerified: true,
      capabilities: { canDrive: true, canRide: true },
      driverProfile: {
        licenseNumber: 'GJ0120220045678',
        onboardingStatus: 'approved',
        verifiedAt: new Date(),
      },
      rating: { average: 4.96, count: 42 },
    },
    { upsert: true, new: true }
  );

  const vehicleAnanya = await Vehicle.findOneAndUpdate(
    { registrationNumber: 'GJ01EV1024' },
    {
      owner: driverAnanya._id,
      registrationNumber: 'GJ01EV1024',
      vehicleType: 'ev',
      make: 'Tata',
      model: 'Nexon EV Max',
      year: 2024,
      color: 'Intensi-Teal',
      seatCapacity: 4,
      status: 'active',
    },
    { upsert: true, new: true }
  );

  // 7. Ensure Demo Passenger Riya Patel exists
  const passengerRiya = await User.findOneAndUpdate(
    { email: 'riya.passenger@example.com' },
    {
      name: 'Riya Patel',
      email: 'riya.passenger@example.com',
      phone: '+919876500099',
      password: hashedPassword,
      city: 'Ahmedabad',
      isVerified: true,
      capabilities: { canDrive: false, canRide: true },
      rating: { average: 5.0, count: 8 },
    },
    { upsert: true, new: true }
  );

  // Clean up existing stale demo rides created by seed drivers
  await Ride.deleteMany({
    driver: {
      $in: [
        driverRohit._id,
        driverMeet._id,
        driverHarsh._id,
        driverJayesh._id,
        driverDivyesh._id,
        driverAnanya._id,
      ],
    },
  });

  const now = Date.now();
  const inTwoHours = new Date(now + 2 * 3600000);
  const inFourHours = new Date(now + 4 * 3600000);
  const startedTenMinsAgo = new Date(now - 10 * 60000);
  const tomorrowMorning = new Date(now + 24 * 3600000);
  tomorrowMorning.setHours(8, 30, 0, 0);
  const tomorrowEvening = new Date(now + 24 * 3600000);
  tomorrowEvening.setHours(18, 0, 0, 0);

  // ── ROUTE A: Rajkot (Kalawad Rd) -> Limbdi -> Ahmedabad (SG Highway / Iscon) ──────
  // 214 km, ₹340 / seat, 3 open seats
  const polylineRajkotAhmedabad = buildRoutePolyline([
    { lat: 22.2810, lng: 70.7620 }, // Kalawad Road, Rajkot
    { lat: 22.3129, lng: 70.7815 }, // Madhapar Chokdi
    { lat: 22.3780, lng: 70.9520 }, // Kuvadva
    { lat: 22.4230, lng: 71.1960 }, // Chotila
    { lat: 22.5350, lng: 71.4680 }, // Sayla
    { lat: 22.5650, lng: 71.8120 }, // Limbdi
    { lat: 22.8180, lng: 72.1950 }, // Bagodara
    { lat: 23.0285, lng: 72.5068 }, // ISCON Cross Road, SG Highway, Ahmedabad
  ]);

  const rideA1 = await Ride.create({
    driver: driverRohit._id,
    vehicle: vehicleRohit._id,
    origin: {
      name: 'Kalawad Road, Rajkot',
      latitude: 22.2810,
      longitude: 70.7620,
      placeId: 'ChIJ_rajkot_kalawad',
      point: { type: 'Point', coordinates: [70.7620, 22.2810] },
    },
    destination: {
      name: 'ISCON Cross Road, SG Highway, Ahmedabad',
      latitude: 23.0285,
      longitude: 72.5068,
      placeId: 'ChIJ_ahmedabad_iscon',
      point: { type: 'Point', coordinates: [72.5068, 23.0285] },
    },
    stopovers: [
      {
        name: 'Chotila Highway Break',
        latitude: 22.4230,
        longitude: 71.1960,
        stopDurationMinutes: 10,
        point: { type: 'Point', coordinates: [71.1960, 22.4230] },
      },
      {
        name: 'Limbdi Toll Plaza',
        latitude: 22.5650,
        longitude: 71.8120,
        stopDurationMinutes: 5,
        point: { type: 'Point', coordinates: [71.8120, 22.5650] },
      },
    ],
    route: {
      encodedPolyline: polylineRajkotAhmedabad,
      distanceMeters: 214000,
      durationSeconds: 11700, // 3h 15m
    },
    departureTime: inTwoHours,
    estimatedArrivalTime: new Date(inTwoHours.getTime() + 11700000),
    totalSeats: 4,
    availableSeats: 3,
    bookedSeats: 1,
    contributionPerSeat: 340,
    pickupPolicy: 'nearby',
    status: 'scheduled',
    amenities: ['AC', 'Luggage Space', 'Music'],
    breakDisclosures: ['Toll: Limbdi (5m stop)', 'Tea break: Chotila (10m)'],
    notes: 'Toll: Limbdi (5m stop) · Tea break: Chotila (10m). Punctual departure from Kalawad Rd.',
  });

  // Reverse Route A: Ahmedabad -> Rajkot (Tomorrow Morning)
  const polylineAhmedabadRajkot = buildRoutePolyline([
    { lat: 23.0285, lng: 72.5068 },
    { lat: 22.8180, lng: 72.1950 },
    { lat: 22.5650, lng: 71.8120 },
    { lat: 22.4230, lng: 71.1960 },
    { lat: 22.3129, lng: 70.7815 },
    { lat: 22.2810, lng: 70.7620 },
  ]);

  await Ride.create({
    driver: driverRohit._id,
    vehicle: vehicleRohit._id,
    origin: {
      name: 'ISCON Cross Road, SG Highway, Ahmedabad',
      latitude: 23.0285,
      longitude: 72.5068,
      placeId: 'ChIJ_ahmedabad_iscon',
      point: { type: 'Point', coordinates: [72.5068, 23.0285] },
    },
    destination: {
      name: 'Kalawad Road, Rajkot',
      latitude: 22.2810,
      longitude: 70.7620,
      placeId: 'ChIJ_rajkot_kalawad',
      point: { type: 'Point', coordinates: [70.7620, 22.2810] },
    },
    stopovers: [
      {
        name: 'Limbdi Toll Plaza',
        latitude: 22.5650,
        longitude: 71.8120,
        stopDurationMinutes: 5,
        point: { type: 'Point', coordinates: [71.8120, 22.5650] },
      },
    ],
    route: {
      encodedPolyline: polylineAhmedabadRajkot,
      distanceMeters: 214000,
      durationSeconds: 11700,
    },
    departureTime: tomorrowMorning,
    estimatedArrivalTime: new Date(tomorrowMorning.getTime() + 11700000),
    totalSeats: 4,
    availableSeats: 2,
    bookedSeats: 2,
    contributionPerSeat: 340,
    pickupPolicy: 'nearby',
    status: 'scheduled',
    amenities: ['AC', 'Music'],
    breakDisclosures: ['Toll: Limbdi (5m stop)', 'Tea break: Chotila (10m)'],
    notes: 'Toll: Limbdi (5m stop) · Tea break: Chotila (10m)',
  });

  // ── ROUTE B: Rajkot (Madhapar Chowk) -> Dhrol -> Jamnagar (Digjam Circle) ──────
  // 92 km, ₹180 / seat, 2 open seats
  const polylineRajkotJamnagar = buildRoutePolyline([
    { lat: 22.3129, lng: 70.7815 }, // Madhapar Chowk, Rajkot
    { lat: 22.4200, lng: 70.6100 }, // Paddhari
    { lat: 22.5680, lng: 70.4150 }, // Dhrol Bypass
    { lat: 22.5000, lng: 70.2100 }, // Falla
    { lat: 22.4580, lng: 70.0480 }, // Digjam Circle, Jamnagar
  ]);

  await Ride.create({
    driver: driverMeet._id,
    vehicle: vehicleMeet._id,
    origin: {
      name: 'Madhapar Chokdi, Rajkot',
      latitude: 22.3129,
      longitude: 70.7815,
      placeId: 'ChIJ_rajkot_madhapar',
      point: { type: 'Point', coordinates: [70.7815, 22.3129] },
    },
    destination: {
      name: 'Digjam Circle, Jamnagar',
      latitude: 22.4580,
      longitude: 70.0480,
      placeId: 'ChIJ_jamnagar_digjam',
      point: { type: 'Point', coordinates: [70.0480, 22.4580] },
    },
    stopovers: [
      {
        name: 'Dhrol Bypass',
        latitude: 22.5680,
        longitude: 70.4150,
        stopDurationMinutes: 5,
        point: { type: 'Point', coordinates: [70.4150, 22.5680] },
      },
    ],
    route: {
      encodedPolyline: polylineRajkotJamnagar,
      distanceMeters: 92000,
      durationSeconds: 5400, // 1h 30m
    },
    departureTime: inFourHours,
    estimatedArrivalTime: new Date(inFourHours.getTime() + 5400000),
    totalSeats: 4,
    availableSeats: 2,
    bookedSeats: 2,
    contributionPerSeat: 180,
    pickupPolicy: 'nearby',
    status: 'scheduled',
    amenities: ['AC', 'Music'],
    breakDisclosures: ['Dhrol Bypass (5m stop)'],
    notes: 'Direct corridor via SH24 · Dhrol Bypass (5m stop). Clean Swift ride.',
  });

  // ── ROUTE C: Ahmedabad (Prahlad Nagar) -> Vadodara (Alkapuri) -> Surat (Majura Gate) ──────
  // 265 km, ₹520 / seat, 3 open seats
  const polylineAhdSurat = buildRoutePolyline([
    { lat: 23.0125, lng: 72.5110 }, // Prahlad Nagar, Ahmedabad
    { lat: 22.7500, lng: 72.8600 }, // Nadiad
    { lat: 22.5500, lng: 72.9500 }, // Anand
    { lat: 22.3110, lng: 73.1810 }, // Alkapuri, Vadodara
    { lat: 21.7000, lng: 72.9900 }, // Bharuch
    { lat: 21.4500, lng: 72.9700 }, // Ankleshwar
    { lat: 21.1820, lng: 72.8220 }, // Majura Gate, Surat
  ]);

  await Ride.create({
    driver: driverHarsh._id,
    vehicle: vehicleHarsh._id,
    origin: {
      name: 'Prahlad Nagar, SG Highway, Ahmedabad',
      latitude: 23.0125,
      longitude: 72.5110,
      placeId: 'ChIJ_ahd_prahlad',
      point: { type: 'Point', coordinates: [72.5110, 23.0125] },
    },
    destination: {
      name: 'Majura Gate, Ring Road, Surat',
      latitude: 21.1820,
      longitude: 72.8220,
      placeId: 'ChIJ_surat_majura',
      point: { type: 'Point', coordinates: [72.8220, 21.1820] },
    },
    stopovers: [
      {
        name: 'Alkapuri, Vadodara',
        latitude: 22.3110,
        longitude: 73.1810,
        stopDurationMinutes: 10,
        point: { type: 'Point', coordinates: [73.1810, 22.3110] },
      },
    ],
    route: {
      encodedPolyline: polylineAhdSurat,
      distanceMeters: 265000,
      durationSeconds: 15300, // 4h 15m
    },
    departureTime: inTwoHours,
    estimatedArrivalTime: new Date(inTwoHours.getTime() + 15300000),
    totalSeats: 4,
    availableSeats: 3,
    bookedSeats: 1,
    contributionPerSeat: 520,
    pickupPolicy: 'nearby',
    status: 'scheduled',
    amenities: ['AC', 'Luggage Space', 'Fastag', 'Music'],
    breakDisclosures: ['Vadodara Alkapuri (10m stop)'],
    notes: 'NH48 Express Corridor · Vadodara Alkapuri (10m stop). Direct to Surat.',
  });

  // ── ROUTE D: Bhuj (Jubilee Ground) -> Gandhidham -> Ahmedabad (Geeta Mandir) ──────
  // 340 km, ₹450 / seat, 2 open seats
  const polylineBhujAhd = buildRoutePolyline([
    { lat: 23.2510, lng: 69.6680 }, // Jubilee Ground, Bhuj
    { lat: 23.1132, lng: 70.0278 }, // Anjar
    { lat: 23.0760, lng: 70.1340 }, // Gandhidham
    { lat: 23.2400, lng: 70.5200 }, // Bhachau
    { lat: 23.3280, lng: 70.5280 }, // Samakhiali
    { lat: 23.0500, lng: 71.3500 }, // Dhrangadhra
    { lat: 22.9900, lng: 72.0000 }, // Sanand
    { lat: 23.0150, lng: 72.5890 }, // Geeta Mandir, Ahmedabad
  ]);

  await Ride.create({
    driver: driverJayesh._id,
    vehicle: vehicleJayesh._id,
    origin: {
      name: 'Jubilee Ground, Bhuj',
      latitude: 23.2510,
      longitude: 69.6680,
      placeId: 'ChIJ_bhuj_jubilee',
      point: { type: 'Point', coordinates: [69.6680, 23.2510] },
    },
    destination: {
      name: 'Geeta Mandir Bus Port, Ahmedabad',
      latitude: 23.0150,
      longitude: 72.5890,
      placeId: 'ChIJ_ahd_geetamandir',
      point: { type: 'Point', coordinates: [72.5890, 23.0150] },
    },
    stopovers: [
      {
        name: 'Gandhidham Junction',
        latitude: 23.0760,
        longitude: 70.1340,
        stopDurationMinutes: 15,
        point: { type: 'Point', coordinates: [70.1340, 23.0760] },
      },
      {
        name: 'Samakhiali Toll Break',
        latitude: 23.3280,
        longitude: 70.5280,
        stopDurationMinutes: 5,
        point: { type: 'Point', coordinates: [70.5280, 23.3280] },
      },
    ],
    route: {
      encodedPolyline: polylineBhujAhd,
      distanceMeters: 340000,
      durationSeconds: 21600, // 6 hours
    },
    departureTime: tomorrowMorning,
    estimatedArrivalTime: new Date(tomorrowMorning.getTime() + 21600000),
    totalSeats: 6,
    availableSeats: 2,
    bookedSeats: 4,
    contributionPerSeat: 450,
    pickupPolicy: 'nearby',
    status: 'scheduled',
    amenities: ['AC', 'Spacious Seating', 'Luggage Space'],
    breakDisclosures: ['Gandhidham (15m stop)', 'Samakhiali (5m)'],
    notes: 'Kutch-Ahmedabad Express · Gandhidham (15m stop) · Samakhiali (5m). Comfortable XUV700.',
  });

  // ── ROUTE E: Rajkot Trikon Baug -> 150 Feet Ring Road -> AIIMS Rajkot / Khandheri ──────
  // 18 km, ₹60 / seat, 3 open seats
  const polylineRajkotUrban = buildRoutePolyline([
    { lat: 22.3012, lng: 70.8022 }, // Trikon Baug, Rajkot
    { lat: 22.2980, lng: 70.7850 }, // Yagnik Road / Ring Road
    { lat: 22.2905, lng: 70.7760 }, // 150 Feet Ring Road (Indira Circle)
    { lat: 22.3129, lng: 70.7815 }, // Madhapar Chokdi
    { lat: 22.3550, lng: 70.7250 }, // AIIMS Rajkot / Khandheri
  ]);

  await Ride.create({
    driver: driverDivyesh._id,
    vehicle: vehicleDivyesh._id,
    origin: {
      name: 'Trikon Baug, Rajkot',
      latitude: 22.3012,
      longitude: 70.8022,
      placeId: 'ChIJ_rajkot_trikon',
      point: { type: 'Point', coordinates: [70.8022, 22.3012] },
    },
    destination: {
      name: 'AIIMS Rajkot / Khandheri',
      latitude: 22.3550,
      longitude: 70.7250,
      placeId: 'ChIJ_rajkot_aiims',
      point: { type: 'Point', coordinates: [70.7250, 22.3550] },
    },
    stopovers: [
      {
        name: 'Indira Circle, 150 Feet Ring Road',
        latitude: 22.2905,
        longitude: 70.7760,
        stopDurationMinutes: 2,
        point: { type: 'Point', coordinates: [70.7760, 22.2905] },
      },
    ],
    route: {
      encodedPolyline: polylineRajkotUrban,
      distanceMeters: 18000,
      durationSeconds: 1800, // 30 min
    },
    departureTime: inTwoHours,
    estimatedArrivalTime: new Date(inTwoHours.getTime() + 1800000),
    totalSeats: 4,
    availableSeats: 3,
    bookedSeats: 1,
    contributionPerSeat: 60,
    pickupPolicy: 'nearby',
    status: 'scheduled',
    amenities: ['AC', 'EV Fastlane', 'Quiet Ride'],
    breakDisclosures: ['Indira Circle (2m)'],
    notes: 'Urban EV Shuttle · Quick drop at AIIMS OPD & Khandheri. Clean Electric Car.',
  });

  // ── ROUTE F: Ahmedabad Bopal -> SG Highway -> GIFT City, Gandhinagar ──────
  // 32 km, ₹110 / seat, 2 open seats (ACTIVE / LIVE CORRIDOR)
  const polylineBopalGiftCity = buildRoutePolyline([
    { lat: 23.0182, lng: 72.4831 }, // South Bopal
    { lat: 23.0285, lng: 72.5068 }, // ISCON Cross Road, SG Highway
    { lat: 23.0504, lng: 72.5168 }, // Thaltej
    { lat: 23.0840, lng: 72.5310 }, // Gota Flyover
    { lat: 23.1287, lng: 72.5453 }, // Vaishnodevi Circle
    { lat: 23.1490, lng: 72.6280 }, // Koba Circle
    { lat: 23.1611, lng: 72.6841 }, // GIFT City Tower 1
  ]);

  const rideF = await Ride.create({
    driver: driverAnanya._id,
    vehicle: vehicleAnanya._id,
    origin: {
      name: 'South Bopal, Ahmedabad',
      latitude: 23.0182,
      longitude: 72.4831,
      placeId: 'ChIJ_ahd_bopal',
      point: { type: 'Point', coordinates: [72.4831, 23.0182] },
    },
    destination: {
      name: 'GIFT City Tower 1, Gandhinagar',
      latitude: 23.1611,
      longitude: 72.6841,
      placeId: 'ChIJ_gift_city',
      point: { type: 'Point', coordinates: [72.6841, 23.1611] },
    },
    stopovers: [
      {
        name: 'ISCON Cross Road',
        latitude: 23.0285,
        longitude: 72.5068,
        stopDurationMinutes: 5,
        point: { type: 'Point', coordinates: [72.5068, 23.0285] },
      },
      {
        name: 'Vaishnodevi Circle',
        latitude: 23.1287,
        longitude: 72.5453,
        stopDurationMinutes: 5,
        point: { type: 'Point', coordinates: [72.5453, 23.1287] },
      },
    ],
    route: {
      encodedPolyline: polylineBopalGiftCity,
      distanceMeters: 32000,
      durationSeconds: 2700, // 45m
    },
    departureTime: startedTenMinsAgo,
    estimatedArrivalTime: new Date(startedTenMinsAgo.getTime() + 2700000),
    totalSeats: 4,
    availableSeats: 2,
    bookedSeats: 2,
    contributionPerSeat: 110,
    pickupPolicy: 'nearby',
    status: 'active',
    amenities: ['AC', 'EV Fastlane', 'Music', 'No Smoking'],
    breakDisclosures: ['ISCON Cross Road (5m)', 'Vaishnodevi (5m)'],
    notes: 'GIFT City Fastlane EV · SG Highway corridor. Active now.',
  });

  // Attach a confirmed booking for Riya on Ride A1 and Ride F for live tracking demo
  await Booking.create({
    ride: rideA1._id,
    passenger: passengerRiya._id,
    requestedSeats: 1,
    contributionPerSeat: 340,
    totalContribution: 340,
    pickup: {
      name: 'Kalawad Road, Rajkot',
      latitude: 22.2810,
      longitude: 70.7620,
      point: { type: 'Point', coordinates: [70.7620, 22.2810] },
    },
    drop: {
      name: 'ISCON Cross Road, Ahmedabad',
      latitude: 23.0285,
      longitude: 72.5068,
      point: { type: 'Point', coordinates: [72.5068, 23.0285] },
    },
    status: 'accepted',
    paymentStatus: 'paid',
  });

  await Booking.create({
    ride: rideF._id,
    passenger: passengerRiya._id,
    requestedSeats: 1,
    contributionPerSeat: 110,
    totalContribution: 110,
    pickup: {
      name: 'ISCON Cross Road, Ahmedabad',
      latitude: 23.0285,
      longitude: 72.5068,
      point: { type: 'Point', coordinates: [72.5068, 23.0285] },
    },
    drop: {
      name: 'GIFT City Tower 1, Gandhinagar',
      latitude: 23.1611,
      longitude: 72.6841,
      point: { type: 'Point', coordinates: [72.6841, 23.1611] },
    },
    status: 'accepted',
    paymentStatus: 'paid',
  });

  console.log('[Seed] Demo Gujarat Corridors Seeded Successfully:');
  console.log(' - Route A: Rajkot (Kalawad Rd) -> Limbdi -> Ahmedabad (SG Highway)');
  console.log(' - Route B: Rajkot (Madhapar) -> Dhrol -> Jamnagar (Digjam Circle)');
  console.log(' - Route C: Ahmedabad (Prahlad Nagar) -> Vadodara -> Surat (Majura Gate)');
  console.log(' - Route D: Bhuj (Jubilee Ground) -> Gandhidham -> Ahmedabad (Geeta Mandir)');
  console.log(' - Route E: Rajkot Trikon Baug -> 150 Feet Ring Road -> AIIMS Rajkot');
  console.log(' - Route F: Ahmedabad Bopal -> SG Highway -> GIFT City (Active Live)');

  await mongoose.disconnect();
  console.log('[Seed] Disconnected from MongoDB.');
}

if (require.main === module) {
  seedDemoCorridors()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('[Seed Error]:', err);
      process.exit(1);
    });
}

module.exports = { seedDemoCorridors };
