import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/bookings/data/bookings_repository.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/features/bookings/presentation/bookings_provider.dart';
import 'package:sahyan/features/bookings/presentation/screens/bookings_hub_screen.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/models/ride_model.dart';
import 'package:sahyan/shared/models/user_model.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/features/auth/data/auth_repository.dart';

class _FakeAuthStorage implements SecureStorageService {
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<String?> getToken() async => 'test_token';
  @override
  Future<void> deleteToken() async {}
  @override
  Future<void> saveUser(UserModel user) async {}
  @override
  Future<UserModel?> getUser() async => null;
  @override
  Future<void> deleteUser() async {}
  @override
  Future<void> clearSession() async {}
  @override
  Future<void> setCompletedOnboarding(bool completed) async {}
  @override
  Future<bool> hasCompletedOnboarding() async => true;
}

class _FakeAuthRepo extends Fake implements AuthRepository {
  @override
  Future<UserModel> getProfile() async => const UserModel(
    id: 'usr_test_1',
    name: 'Zaid A',
    phone: '+919876543210',
    email: 'zaid@example.com',
    city: 'Ahmedabad',
    verificationStatus: UserVerificationStatus.verified,
    rating: 5.0,
    totalRides: 4,
  );
}

class _MockBookingsRepo extends Fake implements BookingsRepository {
  List<BookingModel> mockBookings = [];

  @override
  Future<List<BookingModel>> getMyBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    return mockBookings;
  }

  @override
  Future<BookingModel> getBookingById(String bookingId) async {
    return mockBookings.firstWhere((b) => b.id == bookingId);
  }

  @override
  Future<BookingModel> cancelBooking(String bookingId) async {
    final b = mockBookings.firstWhere((e) => e.id == bookingId);
    return BookingModel(
      id: b.id,
      rideId: b.rideId,
      ride: b.ride,
      passengerId: b.passengerId,
      passenger: b.passenger,
      requestedSeats: b.requestedSeats,
      contributionPerSeat: b.contributionPerSeat,
      totalContribution: b.totalContribution,
      status: BookingStatus.cancelled,
      pickup: b.pickup,
      drop: b.drop,
      pin: b.pin,
      createdAt: b.createdAt,
    );
  }
}

BookingModel _createSampleBooking({
  required String id,
  required BookingStatus status,
  String pin = '4821',
}) {
  return BookingModel(
    id: id,
    rideId: 'ride_101',
    passengerId: 'usr_test_1',
    requestedSeats: 1,
    contributionPerSeat: 520.0,
    totalContribution: 520.0,
    status: status,
    pin: pin,
    paymentStatus: 'paid',
    pickup: const LocationModel(
      name: 'Prahlad Nagar, SG Highway, Ahmedabad',
      address: 'Prahlad Nagar, SG Highway, Ahmedabad',
      city: 'Ahmedabad',
      latitude: 23.0125,
      longitude: 72.5020,
    ),
    drop: const LocationModel(
      name: 'Kalawad Road, Rajkot',
      address: 'Kalawad Road, Rajkot',
      city: 'Rajkot',
      latitude: 22.2850,
      longitude: 70.7725,
    ),
    ride: RideModel(
      id: 'ride_101',
      driverId: 'drv_1',
      driverName: 'Rohit Patel',
      driverRating: 4.92,
      isDriverVerified: true,
      departureTime: '06:30 PM',
      estimatedArrival: '09:45 PM',
      dateTime: DateTime(2026, 10, 25, 18, 30),
      origin: const LocationModel(
        name: 'Ahmedabad',
        address: 'Prahlad Nagar, SG Highway, Ahmedabad',
        city: 'Ahmedabad',
        latitude: 23.0125,
        longitude: 72.5020,
      ),
      destination: const LocationModel(
        name: 'Rajkot',
        address: 'Kalawad Road, Rajkot',
        city: 'Rajkot',
        latitude: 22.2850,
        longitude: 70.7725,
      ),
      route: const RouteInfo(
        encodedPolyline: 'polyline_sample',
        distanceMeters: 215000,
        durationSeconds: 11700,
      ),
      vehicle: const VehicleModel(
        id: 'veh_1',
        ownerId: 'drv_1',
        make: 'Honda',
        model: 'City ZX',
        year: 2023,
        color: 'White',
        registrationNumber: 'GJ 01 AB 1234',
        vehicleType: 'car',
        seatCapacity: 4,
      ),
      availableSeats: 3,
      totalSeats: 4,
      contributionPerSeat: 520,
      status: RideStatus.scheduled,
      amenities: const ['AC', 'Music'],
    ),
    createdAt: DateTime(2026, 10, 18, 14, 30),
  );
}

void main() {
  late _MockBookingsRepo mockRepo;

  setUp(() {
    mockRepo = _MockBookingsRepo();
  });

  Widget createWidgetUnderTest({List<BookingModel> bookings = const []}) {
    mockRepo.mockBookings = bookings;
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(
          (ref) => AuthNotifier(
            repository: _FakeAuthRepo(),
            storageService: _FakeAuthStorage(),
            apiClient: ApiClient(),
          )..state = const AuthState(
            status: AuthStatus.authenticated,
            user: UserModel(
              id: 'usr_test_1',
              name: 'Zaid A',
              phone: '+919876543210',
              email: 'zaid@example.com',
              city: 'Ahmedabad',
              verificationStatus: UserVerificationStatus.verified,
              rating: 5.0,
              totalRides: 4,
            ),
            token: 'test_token',
          ),
        ),
        bookingsRepositoryProvider.overrideWithValue(mockRepo),
        bookingsNotifierProvider.overrideWith((ref) {
          final notifier = BookingsNotifier(mockRepo);
          notifier.state = AsyncValue.data(bookings);
          return notifier;
        }),
      ],
      child: const MaterialApp(
        home: BookingsHubScreen(),
      ),
    );
  }

  group('BookingsHubScreen Master Overhaul Tests', () {
    testWidgets('Active tab renders DigitalBoardingPass when confirmed booking exists', (tester) async {
      final confirmedBooking = _createSampleBooking(
        id: 'bk_active_1',
        status: BookingStatus.accepted,
        pin: '4821',
      );

      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest(bookings: [confirmedBooking]));
      await tester.pumpAndSettle();

      // 1. Header Row
      expect(find.byType(DigitalBoardingPass), findsOneWidget);
      expect(find.text('Rohit Patel'), findsWidgets);
      expect(find.text('4.92'), findsOneWidget);
      expect(find.text('Honda City ZX · GJ 01 AB 1234'), findsOneWidget);
      expect(find.text('CONFIRMED & PAID'), findsOneWidget);

      // 2. Perforated ticket notch divider
      expect(find.byType(TicketNotchDivider), findsOneWidget);

      // 3. Route & Time Matrix
      expect(find.text('06:30 PM'), findsOneWidget);
      expect(find.text('09:45 PM'), findsOneWidget);
      expect(find.text('215.0 km · Non-stop · Est. 3h 15m'), findsOneWidget);

      // 4. Contactless Boarding PIN Container
      expect(find.text('CONTACTLESS BOARDING PIN'), findsOneWidget);
      expect(find.text('4821'), findsWidgets);

      // 5. Action Dock
      expect(find.text('Track Live on Map'), findsOneWidget);
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Share Trip'), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);
    });

    testWidgets('Pending tab displays Under Review card with actions', (tester) async {
      final pendingBooking = _createSampleBooking(
        id: 'bk_pending_1',
        status: BookingStatus.pending,
      );

      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest(bookings: [pendingBooking]));
      await tester.pumpAndSettle();

      // Switch to Pending tab
      await tester.tap(find.text('Pending'));
      await tester.pumpAndSettle();

      // Verify Under Review status badge
      expect(find.text('Under Review'), findsOneWidget);
      expect(find.text('Rohit Patel · Ahmedabad ➔ Rajkot'), findsOneWidget);
      expect(find.text('1 Seat Requested · ₹520 total contribution'), findsOneWidget);
      expect(find.text('Auto-expires in 14 mins if unaccepted'), findsOneWidget);
      expect(find.text('Cancel Request'), findsOneWidget);
      expect(find.text('View Ride Details'), findsOneWidget);
    });

    testWidgets('History tab displays completed trip with Rate Trip & Driver button', (tester) async {
      final completedBooking = _createSampleBooking(
        id: 'bk_history_1',
        status: BookingStatus.completed,
      );

      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest(bookings: [completedBooking]));
      await tester.pumpAndSettle();

      // Switch to History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Verify route, driver and rating button
      expect(find.text('Ahmedabad ➔ Rajkot'), findsOneWidget);
      expect(find.text('₹520 total · 1 Seat'), findsOneWidget);
      expect(find.text('Driver: Rohit Patel · Honda City ZX'), findsOneWidget);
      expect(find.text('Rate Trip & Driver'), findsOneWidget);
    });

    testWidgets('Eco and Carbon Impact Bento opens breakdown modal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify eco impact bento
      final ecoFinder = find.text('You saved 14.8 kg CO₂ this month');
      expect(ecoFinder, findsOneWidget);
      expect(find.text('Top 12% among Gujarat EV Corridor sharers'), findsOneWidget);

      // Tap eco bento to open modal
      await tester.tap(ecoFinder);
      await tester.pumpAndSettle();

      // Verify modal content
      expect(find.text('Carbon Savings Breakdown'), findsOneWidget);
      expect(find.text('Total CO₂ Offset'), findsOneWidget);
      expect(find.text('Fuel Conserved'), findsOneWidget);
      expect(find.text('Corridor Distance'), findsOneWidget);
      expect(find.text('Fleet Efficiency'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Dismiss modal
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Carbon Savings Breakdown'), findsNothing);
    });

    testWidgets('Renders without overflow on 320dp narrow viewport', (tester) async {
      final activeBooking = _createSampleBooking(
        id: 'bk_active_2',
        status: BookingStatus.accepted,
      );

      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest(bookings: [activeBooking]));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DigitalBoardingPass), findsOneWidget);
    });
  });
}
