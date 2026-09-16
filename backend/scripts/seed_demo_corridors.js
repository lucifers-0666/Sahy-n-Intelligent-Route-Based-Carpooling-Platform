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

  // 1. Ensure Verified Driver Karan Dave exists
  const driverKaran = await User.findOneAndUpdate(
    { email: 'karan.driver@example.com' },
    {
      name: 'Karan Dave',
      email: 'karan.driver@example.com',
      phone: '+919876500011',
      password: hashedPassword,
      city: 'Ahmedabad',
      isVerified: true,
      capabilities: { canDrive: true, canRide: true },
      driverProfile: {
        licenseNumber: 'GJ0120200012345',
        onboardingStatus: 'approved',
        verifiedAt: new Date(),
      },
      rating: { average: 4.9, count: 28 },
    },
    { upsert: true, new: true }
  );

  // 2. Ensure Karan's Vehicle exists (Sedan)
  const vehicleKaran = await Vehicle.findOneAndUpdate(
    { registrationNumber: 'GJ01CD5678' },
    {
      owner: driverKaran._id,
      registrationNumber: 'GJ01CD5678',
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

  // 3. Ensure Verified Driver Vikram Rao exists
  const driverVikram = await User.findOneAndUpdate(
    { email: 'vikram.driver@example.com' },
    {
      name: 'Vikram Rao',
      email: 'vikram.driver@example.com',
      phone: '+919876500022',
      password: hashedPassword,
      city: 'Ahmedabad',
      isVerified: true,
      capabilities: { canDrive: true, canRide: true },
      driverProfile: {
        licenseNumber: 'GJ0120210098765',
        onboardingStatus: 'approved',
        verifiedAt: new Date(),
      },
      rating: { average: 4.8, count: 19 },
    },
    { upsert: true, new: true }
  );

  // 4. Ensure Vikram's Vehicle exists (SUV)
  const vehicleVikram = await Vehicle.findOneAndUpdate(
    { registrationNumber: 'GJ01EF9012' },
    {
      owner: driverVikram._id,
      registrationNumber: 'GJ01EF9012',
      vehicleType: 'suv',
      make: 'Hyundai',
      model: 'Creta SX',
      year: 2024,
      color: 'Titan Grey',
      seatCapacity: 4,
      status: 'active',
    },
    { upsert: true, new: true }
  );

  // 5. Ensure Verified Driver Ananya Sharma exists (EV)
  const driverAnanya = await User.findOneAndUpdate(
    { email: 'ananya.driver@example.com' },
    {
      name: 'Ananya Sharma',
      email: 'ananya.driver@example.com',
      phone: '+919876500033',
      password: hashedPassword,
      city: 'Surat',
      isVerified: true,
      capabilities: { canDrive: true, canRide: true },
      driverProfile: {
        licenseNumber: 'GJ0520220045678',
        onboardingStatus: 'approved',
        verifiedAt: new Date(),
      },
      rating: { average: 5.0, count: 14 },
    },
    { upsert: true, new: true }
  );

  // 6. Ensure Ananya's Vehicle exists (Electric SUV)
  const vehicleAnanya = await Vehicle.findOneAndUpdate(
    { registrationNumber: 'GJ01EV1024' },
    {
      owner: driverAnanya._id,
      registrationNumber: 'GJ01EV1024',
      vehicleType: 'suv',
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

  // 8. Clean up existing stale demo rides created by seed drivers
  await Ride.deleteMany({
    driver: { $in: [driverKaran._id, driverVikram._id, driverAnanya._id] },
  });

  const now = Date.now();
  const inTwoHours = new Date(now + 2 * 3600000);
  const inFourHours = new Date(now + 4 * 3600000);
  const startedFifteenMinsAgo = new Date(now - 15 * 60000);
  const tomorrowMorning = new Date(now + 24 * 3600000);
  tomorrowMorning.setHours(8, 30, 0, 0);
  const tomorrowEvening = new Date(now + 24 * 3600000);
  tomorrowEvening.setHours(17, 30, 0, 0);
  const tomorrowTenAm = new Date(now + 24 * 3600000);
  tomorrowTenAm.setHours(10, 0, 0, 0);
  const dayAfterNineAm = new Date(now + 48 * 3600000);
  dayAfterNineAm.setHours(9, 0, 0, 0);

  // Corridor 1: Ahmedabad -> Rajkot (Driver: Karan Dave) - SCHEDULED TODAY
  const polylineAhdRajkot = buildRoutePolyline([
    { lat: 23.0285, lng: 72.5068 }, // ISCON Cross Road, Ahmedabad
    { lat: 22.8180, lng: 72.1950 }, // Bagodara
    { lat: 22.5650, lng: 71.8120 }, // Limbdi
    { lat: 22.5350, lng: 71.4680 }, // Sayla
    { lat: 22.4230, lng: 71.1960 }, // Chotila
    { lat: 22.3780, lng: 70.9520 }, // Kuvadva
    { lat: 22.3129, lng: 70.7815 }, // Madhapar Chokdi, Rajkot
  ]);

  const ride1 = await Ride.create({
    driver: driverKaran._id,
    vehicle: vehicleKaran._id,
    origin: {
      name: 'ISCON Cross Road, SG Highway, Ahmedabad',
      latitude: 23.0285,
      longitude: 72.5068,
      placeId: 'ChIJb_iscon_ahmedabad',
      point: { type: 'Point', coordinates: [72.5068, 23.0285] },
    },
    destination: {
      name: 'Madhapar Chokdi, Rajkot',
      latitude: 22.3129,
      longitude: 70.7815,
      placeId: 'ChIJb_madhapar_rajkot',
      point: { type: 'Point', coordinates: [70.7815, 22.3129] },
    },
    route: {
      encodedPolyline: polylineAhdRajkot,
      distanceMeters: 215000,
      durationSeconds: 13500,
    },
    departureTime: inTwoHours,
    estimatedArrivalTime: new Date(inTwoHours.getTime() + 13500000),
    totalSeats: 4,
    availableSeats: 3,
    bookedSeats: 1,
    contributionPerSeat: 350,
    pickupPolicy: 'nearby',
    status: 'scheduled',
    amenities: ['AC', 'Luggage Space', 'Music'],
    notes: 'Demo Corridor: NH47 Express Route to Rajkot. Leaving punctually from ISCON.',
  });

  // Corridor 2: Ahmedabad -> GIFT City / Gandhinagar (Driver: Vikram Rao) - ACTIVE (LIVE NOW)
  const polylineAhdGiftCity = buildRoutePolyline([
    { lat: 23.0504, lng: 72.5168 }, // Thaltej Cross Road
    { lat: 23.0840, lng: 72.5310 }, // Gota Flyover
    { lat: 23.1287, lng: 72.5453 }, // Vaishnodevi Circle
    { lat: 23.1490, lng: 72.6280 }, // Koba Circle
    { lat: 23.1611, lng: 72.6841 }, // GIFT City Tower 1
  ]);

  const ride2 = await Ride.create({
    driver: driverVikram._id,
    vehicle: vehicleVikram._id,
    origin: {
      name: 'Thaltej Cross Road, SG Highway, Ahmedabad',
      latitude: 23.0504,
      longitude: 72.5168,
      placeId: 'ChIJb_thaltej_ahmedabad',
      point: { type: 'Point', coordinates: [72.5168, 23.0504] },
    },
    destination: {
      name: 'GIFT City Tower 1, Gandhinagar',
      latitude: 23.1611,
      longitude: 72.6841,
      placeId: 'ChIJb_gift_city',
      point: { type: 'Point', coordinates: [72.6841, 23.1611] },
    },
    route: {
      encodedPolyline: polylineAhdGiftCity,
      distanceMeters: 28000,
      durationSeconds: 2400,
    },
    departureTime: startedFifteenMinsAgo,
    estimatedArrivalTime: new Date(startedFifteenMinsAgo.getTime() + 2400000),
    totalSeats: 4,
    availableSeats: 2,
    bookedSeats: 2,
    contributionPerSeat: 120,
    pickupPolicy: 'nearby',
    status: 'active',
    amenities: ['AC', 'Music', 'No Smoking'],
    notes: 'Demo Corridor: Live active commute on SG Highway to GIFT City.',
  });

  // Corridor 3: South Bopal -> Vaishnodevi Circle (Driver: Ananya Sharma) - BOARDING NOW
  const polylineBopalVaishnodevi = buildRoutePolyline([
    { lat: 23.0182, lng: 72.4831 }, // South Bopal
    { lat: 23.0285, lng: 72.5068 }, // ISCON Cross Road
    { lat: 23.0450, lng: 72.5120 }, // Rajpath Club
    { lat: 23.0504, lng: 72.5168 }, // Thaltej
    { lat: 23.0840, lng: 72.5310 }, // Gota Flyover
    { lat: 23.1287, lng: 72.5453 }, // Vaishnodevi Circle
  ]);

  const ride3 = await Ride.create({
    driver: driverAnanya._id,
    vehicle: vehicleAnanya._id,
    origin: {
      name: 'South Bopal, Ahmedabad',
      latitude: 23.0182,
      longitude: 72.4831,
      placeId: 'ChIJb_south_bopal',
      point: { type: 'Point', coordinates: [72.4831, 23.0182] },
    },
    destination: {
      name: 'Vaishnodevi Circle, SG Highway, Ahmedabad',
      latitude: 23.1287,
      longitude: 72.5453,
      placeId: 'ChIJb_vaishnodevi_circle',
      point: { type: 'Point', coordinates: [72.5453, 23.1287] },
    },
    route: {
      encodedPolyline: polylineBopalVaishnodevi,
      distanceMeters: 18500,
      durationSeconds: 1800,
    },
    departureTime: new Date(),
    estimatedArrivalTime: new Date(Date.now() + 1800000),
    totalSeats: 4,
    availableSeats: 3,
    bookedSeats: 1,
    contributionPerSeat: 80,
    pickupPolicy: 'nearby',
    status: 'boarding',
    amenities: ['AC', 'Electric Vehicle', 'Silent Ride'],
    notes: 'Demo Corridor: Electric SUV commute along SG Highway. Boarding now.',
  });

  // Corridor 4: Vadodara -> Surat (Driver: Karan Dave) - TOMORROW MORNING
  const polylineVadodaraSurat = buildRoutePolyline([
    { lat: 22.3072, lng: 73.1812 }, // Central Bus Station, Vadodara
    { lat: 22.1890, lng: 73.1560 }, // Por
    { lat: 21.7050, lng: 72.9980 }, // Bharuch Narmada Bridge
    { lat: 21.6260, lng: 73.0030 }, // Ankleshwar
    { lat: 21.4120, lng: 72.9540 }, // Kim
    { lat: 21.2840, lng: 72.9050 }, // Kamrej
    { lat: 21.2185, lng: 72.8634 }, // Varachha Main Road, Surat
  ]);

  const ride4 = await Ride.create({
    driver: driverKaran._id,
    vehicle: vehicleKaran._id,
    origin: {
      name: 'Central Bus Station, Sayajiganj, Vadodara',
      latitude: 22.3072,
      longitude: 73.1812,
      placeId: 'ChIJb_vadodara_central',
      point: { type: 'Point', coordinates: [73.1812, 22.3072] },
    },
    destination: {
      name: 'Varachha Main Road, Surat',
      latitude: 21.2185,
      longitude: 72.8634,
      placeId: 'ChIJb_surat_varachha',
      point: { type: 'Point', coordinates: [72.8634, 21.2185] },
    },
    route: {
      encodedPolyline: polylineVadodaraSurat,
      distanceMeters: 145000,
      durationSeconds: 9000,
    },
    departureTime: tomorrowMorning,
    estimatedArrivalTime: new Date(tomorrowMorning.getTime() + 9000000),
    totalSeats: 4,
    availableSeats: 3,
    bookedSeats: 0,
    contributionPerSeat: 280,
    pickupPolicy: 'nearby',
    status: 'scheduled',
    amenities: ['AC', 'Music', 'Luggage Space'],
    notes: 'Demo Corridor: NH48 Golden Quadrilateral route to Surat.',
  });

  // Corridor 5: Ahmedabad -> Vadodara (Driver: Vikram Rao) - TOMORROW EVENING
  const polylineAhdVadodara = buildRoutePolyline([
    { lat: 22.9922, lng: 72.6289 }, // CTM Cross Road, Ahmedabad
    { lat: 22.6950, lng: 72.8640 }, // Nadiad Toll Plaza
    { lat: 22.5640, lng: 72.9280 }, // Anand Interchange
    { lat: 22.3255, lng: 73.1970 }, // Amit Nagar Circle, Vadodara
  ]);

  const ride5 = await Ride.create({
    driver: driverVikram._id,
    vehicle: vehicleVikram._id,
    origin: {
      name: 'CTM Cross Road, Express Highway, Ahmedabad',
      latitude: 22.9922,
      longitude: 72.6289,
      placeId: 'ChIJb_ctm_ahmedabad',
      point: { type: 'Point', coordinates: [72.6289, 22.9922] },
    },
    destination: {
      name: 'Amit Nagar Circle, Vadodara',
      latitude: 22.3255,
      longitude: 73.1970,
      placeId: 'ChIJb_amitnagar_vadodara',
      point: { type: 'Point', coordinates: [73.1970, 22.3255] },
    },
    route: {
      encodedPolyline: polylineAhdVadodara,
      distanceMeters: 110000,
      durationSeconds: 6000,
    },
    departureTime: tomorrowEvening,
    estimatedArrivalTime: new Date(tomorrowEvening.getTime() + 6000000),
    totalSeats: 4,
    availableSeats: 4,
    bookedSeats: 0,
    contributionPerSeat: 180,
    pickupPolicy: 'nearby',
    status: 'scheduled',
    amenities: ['AC', 'Music'],
    notes: 'Demo Corridor: NE1 National Expressway fast transit.',
  });

  // Corridor 6: Surat -> Vapi (Driver: Ananya Sharma) - TODAY AFTERNOON
  const polylineSuratVapi = buildRoutePolyline([
    { lat: 21.1822, lng: 72.8197 }, // Majura Gate, Surat
    { lat: 21.0650, lng: 72.8460 }, // Sachin GIDC
    { lat: 20.9540, lng: 72.9320 }, // Navsari
    { lat: 20.7680, lng: 72.9750 }, // Bilimora
    { lat: 20.6120, lng: 72.9280 }, // Valsad
    { lat: 20.3708, lng: 72.9106 }, // Gunjan GIDC, Vapi
  ]);

  const ride6 = await Ride.create({
    driver: driverAnanya._id,
    vehicle: vehicleAnanya._id,
    origin: {
      name: 'Majura Gate, Ring Road, Surat',
      latitude: 21.1822,
      longitude: 72.8197,
      placeId: 'ChIJb_majura_surat',
      point: { type: 'Point', coordinates: [72.8197, 21.1822] },
    },
    destination: {
      name: 'Gunjan GIDC, Vapi',
      latitude: 20.3708,
      longitude: 72.9106,
      placeId: 'ChIJb_gunjan_vapi',
      point: { type: 'Point', coordinates: [72.9106, 20.3708] },
    },
    route: {
      encodedPolyline: polylineSuratVapi,
      distanceMeters: 115000,
      durationSeconds: 8100,
    },
    departureTime: inFourHours,
    estimatedArrivalTime: new Date(inFourHours.getTime() + 8100000),
    totalSeats: 4,
    availableSeats: 3,
    bookedSeats: 0,
    contributionPerSeat: 220,
    pickupPolicy: 'nearby',
    status: 'scheduled',
    amenities: ['AC', 'Electric Vehicle', 'Music'],
    notes: 'Demo Corridor: South Gujarat Industrial Corridor transit.',
  });

  // Corridor 7: Rajkot -> Jamnagar (Driver: Karan Dave) - TOMORROW 10 AM
  const polylineRajkotJamnagar = buildRoutePolyline([
    { lat: 22.2965, lng: 70.7725 }, // Indira Circle, Rajkot
    { lat: 22.4280, lng: 70.5980 }, // Paddhari
    { lat: 22.5680, lng: 70.4120 }, // Dhrol
    { lat: 22.4638, lng: 70.0760 }, // Digjam Circle, Jamnagar
  ]);

  const ride7 = await Ride.create({
    driver: driverKaran._id,
    vehicle: vehicleKaran._id,
    origin: {
      name: 'Indira Circle, University Road, Rajkot',
      latitude: 22.2965,
      longitude: 70.7725,
      placeId: 'ChIJb_indira_rajkot',
      point: { type: 'Point', coordinates: [70.7725, 22.2965] },
    },
    destination: {
      name: 'Digjam Circle, Jamnagar',
      latitude: 22.4638,
      longitude: 70.0760,
      placeId: 'ChIJb_digjam_jamnagar',
      point: { type: 'Point', coordinates: [70.0760, 22.4638] },
    },
    route: {
      encodedPolyline: polylineRajkotJamnagar,
      distanceMeters: 92000,
      durationSeconds: 6600,
    },
    departureTime: tomorrowTenAm,
    estimatedArrivalTime: new Date(tomorrowTenAm.getTime() + 6600000),
    totalSeats: 4,
    availableSeats: 4,
    bookedSeats: 0,
    contributionPerSeat: 160,
    pickupPolicy: 'nearby',
    status: 'scheduled',
    amenities: ['AC', 'Music'],
    notes: 'Demo Corridor: Saurashtra State Highway corridor.',
  });

  // Corridor 8: Bhuj -> Gandhidham (Driver: Vikram Rao) - DAY AFTER TOMORROW
  const polylineBhujGandhidham = buildRoutePolyline([
    { lat: 23.2420, lng: 69.6669 }, // Jubilee Ground, Bhuj
    { lat: 23.1890, lng: 69.8420 }, // Ratnal
    { lat: 23.1120, lng: 70.0240 }, // Anjar
    { lat: 23.0753, lng: 70.1337 }, // Tagore Road, Gandhidham
  ]);

  const ride8 = await Ride.create({
    driver: driverVikram._id,
    vehicle: vehicleVikram._id,
    origin: {
      name: 'Jubilee Ground, Bhuj',
      latitude: 23.2420,
      longitude: 69.6669,
      placeId: 'ChIJb_bhuj_jubilee',
      point: { type: 'Point', coordinates: [69.6669, 23.2420] },
    },
    destination: {
      name: 'Tagore Road, Gandhidham',
      latitude: 23.0753,
      longitude: 70.1337,
      placeId: 'ChIJb_gandhidham_tagore',
      point: { type: 'Point', coordinates: [70.1337, 23.0753] },
    },
    route: {
      encodedPolyline: polylineBhujGandhidham,
      distanceMeters: 58000,
      durationSeconds: 4200,
    },
    departureTime: dayAfterNineAm,
    estimatedArrivalTime: new Date(dayAfterNineAm.getTime() + 4200000),
    totalSeats: 4,
    availableSeats: 4,
    bookedSeats: 0,
    contributionPerSeat: 140,
    pickupPolicy: 'nearby',
    status: 'scheduled',
    amenities: ['AC'],
    notes: 'Demo Corridor: Kutch Intercity transit.',
  });

  // 9. Seed demo bookings for Passenger Riya Patel
  await Booking.deleteMany({ passenger: passengerRiya._id });

  // Booking on Active ride (Ahmedabad -> GIFT City)
  await Booking.create({
    passenger: passengerRiya._id,
    ride: ride2._id,
    requestedSeats: 1,
    contributionPerSeat: 120,
    totalContribution: 120,
    pickup: {
      name: 'Thaltej Cross Road, SG Highway',
      latitude: 23.0504,
      longitude: 72.5168,
      point: { type: 'Point', coordinates: [72.5168, 23.0504] },
    },
    drop: {
      name: 'GIFT City Tower 1',
      latitude: 23.1611,
      longitude: 72.6841,
      point: { type: 'Point', coordinates: [72.6841, 23.1611] },
    },
    status: 'accepted',
  });

  // Booking on Scheduled ride (Ahmedabad -> Rajkot)
  await Booking.create({
    passenger: passengerRiya._id,
    ride: ride1._id,
    requestedSeats: 1,
    contributionPerSeat: 350,
    totalContribution: 350,
    pickup: {
      name: 'ISCON Cross Road, Ahmedabad',
      latitude: 23.0285,
      longitude: 72.5068,
      point: { type: 'Point', coordinates: [72.5068, 23.0285] },
    },
    drop: {
      name: 'Madhapar Chokdi, Rajkot',
      latitude: 22.3129,
      longitude: 70.7815,
      point: { type: 'Point', coordinates: [70.7815, 22.3129] },
    },
    status: 'accepted',
  });

  console.log('[Seed] Successfully seeded 8 comprehensive demo corridor rides and passenger bookings across Gujarat!');
  await mongoose.disconnect();
  console.log('[Seed] Database disconnected.');
}

seedDemoCorridors().catch((err) => {
  console.error('[Seed] Error seeding demo corridors:', err);
  process.exit(1);
});
