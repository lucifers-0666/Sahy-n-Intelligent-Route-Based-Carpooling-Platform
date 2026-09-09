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

  // 2. Ensure Karan's Vehicle exists
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

  // 4. Ensure Vikram's Vehicle exists
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

  // 5. Clean up existing stale demo rides created by these seed drivers
  await Ride.deleteMany({
    driver: { $in: [driverKaran._id, driverVikram._id] },
    notes: { $regex: /Demo Corridor/i },
  });

  // Base departure times: tomorrow and 2 days out
  const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);
  tomorrow.setHours(9, 30, 0, 0);

  const dayAfter = new Date(Date.now() + 48 * 60 * 60 * 1000);
  dayAfter.setHours(17, 0, 0, 0);

  // Corridor 1: Ahmedabad -> Rajkot (Driver: Karan Dave)
  await Ride.create({
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
      encodedPolyline: 'a~l~Fjk~uOnw@_corridor_ahmedabad_rajkot_nh47',
      distanceMeters: 215000,
      durationSeconds: 14400,
    },
    departureTime: tomorrow,
    estimatedArrivalTime: new Date(tomorrow.getTime() + 4 * 3600000),
    totalSeats: 4,
    availableSeats: 3,
    bookedSeats: 0,
    contributionPerSeat: 350,
    pickupPolicy: 'nearby',
    status: 'scheduled',
    amenities: ['AC', 'Luggage Space', 'Music'],
    notes: 'Demo Corridor: NH47 Express Route. Leaving punctually from ISCON.',
  });

  // Corridor 2: Ahmedabad -> GIFT City / Gandhinagar (Driver: Vikram Rao)
  await Ride.create({
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
      encodedPolyline: 'w~dfD_bswM_corridor_ahmedabad_giftcity_route',
      distanceMeters: 28000,
      durationSeconds: 2100,
    },
    departureTime: tomorrow,
    estimatedArrivalTime: new Date(tomorrow.getTime() + 45 * 60000),
    totalSeats: 4,
    availableSeats: 3,
    bookedSeats: 0,
    contributionPerSeat: 120,
    pickupPolicy: 'nearby',
    amenities: ['AC', 'Music', 'No Smoking'],
    notes: 'Demo Corridor: Daily tech corridor carpool. Direct drop at GIFT Tower.',
  });

  // Corridor 3: Vadodara -> Surat (Driver: Karan Dave)
  await Ride.create({
    driver: driverKaran._id,
    vehicle: vehicleKaran._id,
    origin: {
      name: 'Central Bus Station, Vadodara',
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
      encodedPolyline: 'u~kfD_bswM_corridor_vadodara_surat_expressway',
      distanceMeters: 145000,
      durationSeconds: 9000,
    },
    departureTime: dayAfter,
    estimatedArrivalTime: new Date(dayAfter.getTime() + 2.5 * 3600000),
    totalSeats: 4,
    availableSeats: 3,
    bookedSeats: 0,
    contributionPerSeat: 280,
    pickupPolicy: 'nearby',
    status: 'scheduled',
    amenities: ['AC', 'Music'],
    notes: 'Demo Corridor: Golden Quadrilateral route to Surat.',
  });

  // Corridor 4: Bhuj -> Gandhidham (Driver: Vikram Rao)
  await Ride.create({
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
      encodedPolyline: 'q~jfD_bswM_corridor_bhuj_gandhidham_transit',
      distanceMeters: 58000,
      durationSeconds: 4200,
    },
    departureTime: tomorrow,
    estimatedArrivalTime: new Date(tomorrow.getTime() + 1.2 * 3600000),
    totalSeats: 4,
    availableSeats: 4,
    bookedSeats: 0,
    contributionPerSeat: 150,
    pickupPolicy: 'nearby',
    amenities: ['AC'],
    notes: 'Demo Corridor: Kutch Intercity Morning Transit.',
  });

  console.log('[Seed] Successfully seeded 4 demo corridor rides across Gujarat!');
  await mongoose.disconnect();
  console.log('[Seed] Database disconnected.');
}

seedDemoCorridors().catch((err) => {
  console.error('[Seed] Error seeding demo corridors:', err);
  process.exit(1);
});
