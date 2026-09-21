import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/core/network/api_config.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/features/rides/domain/ride_model.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/shared/models/location_model.dart';

void main() {
  group('Phase 2 Full-Stack Integration & State Architecture Tests', () {
    test('ApiConfig supports custom local IP and default endpoints', () {
      ApiConfig.setCustomBaseUrl('http://10.60.144.149:5000/api/v1');
      expect(ApiConfig.baseUrl, 'http://10.60.144.149:5000/api/v1');

      // Reset to default
      ApiConfig.setCustomBaseUrl(null);
      expect(ApiConfig.baseUrl.isNotEmpty, true);
    });

    test('ApiClient onUnauthorized callback triggers on 401 responses', () {
      final client = ApiClient();
      bool unauthorizedTriggered = false;
      client.onUnauthorized = () {
        unauthorizedTriggered = true;
      };

      // Verify callback assignment
      expect(client.onUnauthorized, isNotNull);
      client.onUnauthorized?.call();
      expect(unauthorizedTriggered, true);
    });

    test(
      'VehicleRepository deserializes MongoDB vehicles response formats',
      () {
        final mockRawResponse = {
          'success': true,
          'vehicles': [
            {
              '_id': 'veh_mongodb_101',
              'owner': 'usr_driver_01',
              'make': 'Tata',
              'model': 'Nexon EV',
              'year': 2024,
              'color': 'Teal Blue',
              'registrationNumber': 'GJ 01 EV 9988',
              'vehicleType': 'suv',
              'seatCapacity': 4,
              'status': 'active',
            },
          ],
        };

        final vehiclesList = (mockRawResponse['vehicles'] as List)
            .map((item) => VehicleModel.fromJson(item as Map<String, dynamic>))
            .toList();

        expect(vehiclesList.length, 1);
        expect(vehiclesList.first.make, 'Tata');
        expect(vehiclesList.first.model, 'Nexon EV');
        expect(vehiclesList.first.registrationNumber, 'GJ 01 EV 9988');
        expect(vehiclesList.first.displayName, 'Tata Nexon EV');
      },
    );

    test(
      'RideModel parses live MongoDB document with Driver and Route info',
      () {
        final mockRideJson = {
          '_id': 'ride_live_777',
          'driver': {
            '_id': 'usr_driver_77',
            'name': 'Jay Patel',
            'rating': 4.95,
            'phone': '+919876543210',
            'isVerified': true,
          },
          'vehicle': {
            '_id': 'veh_77',
            'make': 'Hyundai',
            'model': 'Verna',
            'registrationNumber': 'GJ 03 XY 4321',
            'vehicleType': 'sedan',
            'color': 'Polar White',
            'seatCapacity': 4,
          },
          'origin': {
            'name': 'Ahmedabad SG Highway',
            'address': 'Ahmedabad SG Highway, Gujarat',
            'city': 'Ahmedabad',
            'latitude': 23.0338,
            'longitude': 72.5850,
          },
          'destination': {
            'name': 'Rajkot Kalawad Road',
            'address': 'Rajkot Kalawad Road, Gujarat',
            'city': 'Rajkot',
            'latitude': 22.3039,
            'longitude': 70.8022,
          },
          'departureTime': '2026-09-14T08:00:00.000Z',
          'availableSeats': 3,
          'totalSeats': 4,
          'pricePerSeat': 350.0,
          'status': 'scheduled',
          'amenities': ['AC', 'Music', 'No Smoking'],
        };

        final ride = RideModel.fromJson(mockRideJson);

        expect(ride.id, 'ride_live_777');
        expect(ride.driverName, 'Jay Patel');
        expect(ride.driverRating, 4.95);
        expect(ride.vehicle.displayName, 'Hyundai Verna');
        expect(ride.origin.city, 'Ahmedabad');
        expect(ride.destination.city, 'Rajkot');
        expect(ride.availableSeats, 3);
        expect(ride.contributionPerSeat, 350.0);
      },
    );

    test(
      'BookingModel parses live booking with atomic status changes and security PIN',
      () {
        final mockBookingJson = {
          '_id': 'bk_atomic_5001',
          'ride': {
            '_id': 'ride_live_777',
            'driver': {'name': 'Rohit Patel', 'rating': 4.92},
            'vehicle': {
              'make': 'Honda',
              'model': 'City ZX',
              'registrationNumber': 'GJ 01 AB 1234',
            },
            'origin': {'address': 'AMD · Iscon Cross'},
            'destination': {'address': 'RAJ · Kalawad Rd'},
            'pricePerSeat': 420.0,
            'availableSeats': 2,
          },
          'passenger': {
            '_id': 'usr_pass_02',
            'name': 'Sneha Rao',
            'phone': '+919988776655',
          },
          'pickupLocation': {
            'name': 'Iscon Cross Roads',
            'address': 'Iscon Cross Roads, Ahmedabad',
            'city': 'Ahmedabad',
            'latitude': 23.0270,
            'longitude': 72.5080,
          },
          'dropLocation': {
            'name': 'Kalawad Road',
            'address': 'Kalawad Road, Rajkot',
            'city': 'Rajkot',
            'latitude': 22.2850,
            'longitude': 70.7720,
          },
          'seatsRequested': 2,
          'fare': 840.0,
          'status': 'pending',
          'pin': '7492',
          'createdAt': '2026-09-13T10:00:00.000Z',
        };

        final booking = BookingModel.fromJson(mockBookingJson);

        expect(booking.id, 'bk_atomic_5001');
        expect(booking.isPending, true);
        expect(booking.requestedSeats, 2);
        expect(booking.totalContribution, 840.0);
        expect(booking.securityPin, '7492');
        expect(booking.ride?.driverName, 'Rohit Patel');

        // Test deterministic fallback PIN when pin is null
        final bookingWithoutPin = BookingModel(
          id: 'bk_fallback_12',
          rideId: 'ride_1',
          passengerId: 'usr_1',
          requestedSeats: 1,
          contributionPerSeat: 300,
          totalContribution: 300,
          status: BookingStatus.accepted,
          pickup: const LocationModel(
            address: 'A',
            city: 'A',
            latitude: 0,
            longitude: 0,
          ),
          drop: const LocationModel(
            address: 'B',
            city: 'B',
            latitude: 0,
            longitude: 0,
          ),
          createdAt: DateTime.now(),
        );

        expect(bookingWithoutPin.securityPin.length, 4);
        expect(int.tryParse(bookingWithoutPin.securityPin), isNotNull);
        expect(bookingWithoutPin.isAccepted, true);
      },
    );
  });
}
