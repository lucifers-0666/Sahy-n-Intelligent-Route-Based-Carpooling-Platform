import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/features/rides/domain/ride_model.dart';
import 'package:sahyan/features/rides/domain/ride_search_result.dart';

void main() {
  group('RideModel & RideSearchResult Deserialization Resilience', () {
    test('RideModel.fromJson successfully parses populated driver rating object from backend', () {
      final backendJson = {
        'id': 'ride_abc_123',
        'driver': {
          '_id': 'usr_driver_99',
          'name': 'demo demi',
          'profileImage': 'https://example.com/photo.jpg',
          'rating': {
            'average': 4.92,
            'count': 48,
          },
          'isVerified': true,
        },
        'vehicle': {
          'id': 'veh_demo_1',
          'owner': 'usr_driver_99',
          'registrationNumber': 'DEMO1',
          'make': 'demo',
          'model': 'demi',
          'seatCapacity': 4,
          'vehicleType': 'sedan',
        },
        'origin': {
          'name': 'Ahmedabad',
          'latitude': 23.0225,
          'longitude': 72.5714,
        },
        'destination': {
          'name': 'Rajkot',
          'latitude': 22.3039,
          'longitude': 70.8022,
        },
        'route': {
          'encodedPolyline': 'mock_poly',
          'distanceMeters': 214100,
          'durationSeconds': 11400,
        },
        'departureTime': '2026-10-21T16:13:00.000Z',
        'availableSeats': 1,
        'totalSeats': 4,
        'contributionPerSeat': 350.0,
        'status': 'scheduled',
      };

      final ride = RideModel.fromJson(backendJson);

      expect(ride.id, 'ride_abc_123');
      expect(ride.driverId, 'usr_driver_99');
      expect(ride.driverName, 'demo demi');
      expect(ride.driverRating, 4.92);
      expect(ride.isDriverVerified, true);
      expect(ride.contributionPerSeat, 350.0);
      expect(ride.availableSeats, 1);
    });

    test('RideModel.fromJson safely parses flat driverRating and primitive ratings', () {
      final jsonWithNum = {
        'id': 'ride_02',
        'driverId': 'drv_02',
        'driverName': 'Suresh',
        'driverRating': 4.75,
        'availableSeats': 2,
        'contributionPerSeat': 250,
      };

      final ride = RideModel.fromJson(jsonWithNum);
      expect(ride.driverRating, 4.75);
      expect(ride.availableSeats, 2);
      expect(ride.contributionPerSeat, 250.0);

      final jsonWithMissing = {
        'id': 'ride_03',
        'driver': {
          'name': 'Ramesh',
          'rating': null,
        },
      };
      final rideMissing = RideModel.fromJson(jsonWithMissing);
      expect(rideMissing.driverRating, 4.8);
    });

    test('RideSearchResult.fromJson safely parses backend search candidate response', () {
      final searchResultJson = {
        'ride': {
          'id': 'ride_search_match_01',
          'driver': {
            '_id': 'drv_corridor_01',
            'name': 'Mahesh Shah',
            'rating': {
              'average': 4.95,
              'count': 112,
            },
          },
          'origin': {
            'name': 'Trikon Baug, Rajkot',
            'point': {
              'type': 'Point',
              'coordinates': [70.8022, 22.3039],
            },
          },
          'destination': {
            'name': 'AIIMS Rajkot',
            'point': {
              'type': 'Point',
              'coordinates': [70.8200, 22.3200],
            },
          },
          'availableSeats': 3,
          'contributionPerSeat': 50,
        },
        'pickupDistanceKm': 1.2,
        'destinationDistanceKm': 0.8,
        'departureDifferenceMinutes': 15,
        'availableSeats': 3,
        'matchPreview': 'High corridor match',
        'match': {
          'score': 94,
          'grade': 'Excellent',
          'factors': {
            'routeOverlap': 90,
            'pickupDeviation': 95,
            'destinationDeviation': 95,
            'timeCompatibility': 90,
            'driverReliability': 98,
            'seatAvailability': 100,
          },
          'metrics': {
            'routeOverlapPercentage': 90,
            'pickupDistanceKm': 1.2,
            'destinationDistanceKm': 0.8,
            'departureDifferenceMinutes': 15,
          },
          'reasons': ['Direct corridor route', 'Verified driver'],
        },
      };

      final result = RideSearchResult.fromJson(searchResultJson);

      expect(result.ride.driverRating, 4.95);
      expect(result.ride.driverName, 'Mahesh Shah');
      expect(result.pickupDistanceKm, 1.2);
      expect(result.matchScore, 94);
      expect(result.availableSeats, 3);
    });
  });
}
