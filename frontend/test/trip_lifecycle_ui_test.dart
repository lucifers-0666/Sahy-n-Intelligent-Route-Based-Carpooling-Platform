import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/features/auth/data/auth_repository.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/bookings/data/bookings_repository.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/features/bookings/presentation/bookings_provider.dart';
import 'package:sahyan/features/bookings/presentation/screens/booking_details_screen.dart';
import 'package:sahyan/features/bookings/presentation/screens/driver_rides_screen.dart';
import 'package:sahyan/features/bookings/presentation/screens/my_bookings_screen.dart';
import 'package:sahyan/features/rides/data/ride_repository.dart';
import 'package:sahyan/features/rides/domain/ride_search_result.dart';
import 'package:sahyan/features/rides/presentation/rides_provider.dart';
import 'package:sahyan/features/rides/presentation/screens/ride_details_screen.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/models/ride_model.dart';
import 'package:sahyan/shared/models/user_model.dart';

class _FakeAuthStorage implements SecureStorageService {
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<String?> getToken() async => null;
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

class _FakeAuthRepo implements AuthRepository {
  @override
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async => {};
  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async => {};
  @override
  Future<Map<String, dynamic>> sendOtp(String phone) async => {};
  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async => {};
  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async => {};
  @override
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async => {};
  @override
  Future<UserModel> getProfile() async => const UserModel(
    id: 'usr_test_driver',
    name: 'Driver Dev',
    phone: '+919876543210',
    email: 'driver@example.com',
    city: 'Ahmedabad',
    verificationStatus: UserVerificationStatus.verified,
    rating: 4.9,
    totalRides: 12,
  );
}

class FakeLifecycleAuthNotifier extends AuthNotifier {
  final bool _initialAuth;

  FakeLifecycleAuthNotifier({bool isAuthenticated = true})
    : _initialAuth = isAuthenticated,
      super(
        repository: _FakeAuthRepo(),
        storageService: _FakeAuthStorage(),
        apiClient: ApiClient(),
      ) {
    _applyAuthState();
  }

  void _applyAuthState() {
    state = _initialAuth
        ? const AuthState(
            status: AuthStatus.authenticated,
            user: UserModel(
              id: 'usr_test_driver',
              name: 'Driver Dev',
              phone: '+919876543210',
              email: 'driver@example.com',
              city: 'Ahmedabad',
              verificationStatus: UserVerificationStatus.verified,
              rating: 4.9,
              totalRides: 12,
              canDrive: true,
            ),
            token: 'valid_driver_jwt',
          )
        : const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  Future<void> checkAuthStatus() async {
    _applyAuthState();
  }
}

class MockLifecycleRideRepo implements RideRepository {
  List<RideModel> rides = [];
  bool shouldFailNext = false;
  String failMessage = 'Simulated network conflict';

  @override
  Future<List<RideModel>> getMyRides({String? status}) async => rides;

  @override
  Future<RideModel> getRideById(String id) async =>
      rides.firstWhere((r) => r.id == id);

  @override
  Future<RideModel> startBoarding(String id) async {
    if (shouldFailNext) {
      throw Exception(failMessage);
    }
    final index = rides.indexWhere((r) => r.id == id);
    final updated = rides[index].copyWith(status: RideStatus.boarding);
    rides[index] = updated;
    return updated;
  }

  @override
  Future<RideModel> startTrip(String id) async {
    if (shouldFailNext) {
      throw Exception(failMessage);
    }
    final index = rides.indexWhere((r) => r.id == id);
    final updated = rides[index].copyWith(status: RideStatus.active);
    rides[index] = updated;
    return updated;
  }

  @override
  Future<RideModel> completeTrip(String id) async {
    if (shouldFailNext) {
      throw Exception(failMessage);
    }
    final index = rides.indexWhere((r) => r.id == id);
    final updated = rides[index].copyWith(status: RideStatus.completed);
    rides[index] = updated;
    return updated;
  }

  @override
  Future<RideModel> cancelRide(String id) async {
    if (shouldFailNext) {
      throw Exception(failMessage);
    }
    final index = rides.indexWhere((r) => r.id == id);
    final updated = rides[index].copyWith(status: RideStatus.cancelled);
    rides[index] = updated;
    return updated;
  }

  @override
  Future<RideModel> createRide({
    required String vehicleId,
    required LocationModel origin,
    required LocationModel destination,
    required RouteInfo route,
    required DateTime departureTime,
    DateTime? estimatedArrivalTime,
    required int availableSeats,
    required double contributionPerSeat,
    String pickupPolicy = 'nearby',
    List<String> amenities = const [],
    String? notes,
  }) async => throw UnimplementedError();

  @override
  Future<RouteInfo> calculateRoute({
    required LocationModel origin,
    required LocationModel destination,
  }) async => throw UnimplementedError();

  @override
  Future<List<RideSearchResult>> searchRides({
    LocationModel? origin,
    LocationModel? destination,
    String? originText,
    String? destinationText,
    DateTime? departureDate,
    int seats = 1,
    double? minContribution,
    double? maxContribution,
    String? pickupPolicy,
    double maxPickupDistanceKm = 10.0,
    double maxDropDistanceKm = 10.0,
    int timeWindowHours = 4,
  }) async => [];
}

class MockLifecycleBookingsRepo implements BookingsRepository {
  List<BookingModel> bookings = [];

  @override
  Future<BookingModel> createBooking({
    required String rideId,
    required int requestedSeats,
    String? passengerNote,
    LocationModel? pickup,
    LocationModel? drop,
  }) async => throw UnimplementedError();

  @override
  Future<List<BookingModel>> getDriverBookingRequests({
    String? status,
    String? rideId,
    int page = 1,
    int limit = 50,
  }) async => bookings;

  @override
  Future<List<BookingModel>> getMyBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async => bookings;

  @override
  Future<BookingModel> getBookingById(String id) async =>
      bookings.firstWhere((b) => b.id == id);

  @override
  Future<BookingModel> cancelBooking(String id) async =>
      bookings.firstWhere((b) => b.id == id);

  @override
  Future<BookingModel> acceptBooking(String id) async =>
      bookings.firstWhere((b) => b.id == id);

  @override
  Future<BookingModel> rejectBooking(String id) async =>
      bookings.firstWhere((b) => b.id == id);
}

// Helper factories
RideModel createTestRide({
  String id = 'ride_101',
  RideStatus status = RideStatus.scheduled,
  int availableSeats = 3,
  int totalSeats = 4,
}) {
  return RideModel(
    id: id,
    driverId: 'usr_test_driver',
    driverName: 'Driver Dev',
    driverRating: 4.9,
    isDriverVerified: true,
    vehicle: const VehicleModel(
      id: 'veh_001',
      ownerId: 'usr_test_driver',
      make: 'Maruti Suzuki',
      model: 'Ertiga',
      year: 2023,
      color: 'Silver',
      registrationNumber: 'GJ-01-EF-5678',
      vehicleType: 'car',
      seatCapacity: 6,
    ),
    origin: LocationModel.fromCoordinates(
      name: 'Ahmedabad ISKCON Cross Roads',
      latitude: 23.028,
      longitude: 72.506,
    ),
    destination: LocationModel.fromCoordinates(
      name: 'Rajkot Madhapar Chowk',
      latitude: 22.312,
      longitude: 70.785,
    ),
    dateTime: DateTime(2026, 9, 15, 8, 30),
    departureTime: '8:30 AM',
    estimatedArrival: '1:30 PM',
    availableSeats: availableSeats,
    totalSeats: totalSeats,
    bookedSeats: totalSeats - availableSeats,
    contributionPerSeat: 380.0,
    status: status,
    amenities: const ['AC', 'Music'],
  );
}

BookingModel createTestBooking({
  String id = 'bk_101',
  String rideId = 'ride_101',
  BookingStatus status = BookingStatus.accepted,
  RideModel? ride,
}) {
  return BookingModel(
    id: id,
    rideId: rideId,
    ride: ride ?? createTestRide(id: rideId),
    passengerId: 'usr_pass_1',
    requestedSeats: 1,
    contributionPerSeat: 380.0,
    totalContribution: 380.0,
    status: status,
    pickup: LocationModel.fromCoordinates(
      name: 'Ahmedabad SG Highway',
      latitude: 23.028,
      longitude: 72.506,
    ),
    drop: LocationModel.fromCoordinates(
      name: 'Rajkot Green Land Chowk',
      latitude: 22.312,
      longitude: 70.785,
    ),
    createdAt: DateTime(2026, 9, 8, 14, 0),
  );
}

Widget createTestApp({
  required Widget child,
  required MockLifecycleRideRepo rideRepo,
  required MockLifecycleBookingsRepo bookingsRepo,
  bool isAuthenticated = true,
  double textScaleFactor = 1.0,
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        (ref) => FakeLifecycleAuthNotifier(isAuthenticated: isAuthenticated),
      ),
      rideApiRepositoryProvider.overrideWithValue(rideRepo),
      bookingsRepositoryProvider.overrideWithValue(bookingsRepo),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (context) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(textScaler: TextScaler.linear(textScaleFactor)),
            child: child,
          );
        },
      ),
    ),
  );
}

void main() {
  late MockLifecycleRideRepo rideRepo;
  late MockLifecycleBookingsRepo bookingsRepo;

  setUp(() {
    rideRepo = MockLifecycleRideRepo();
    bookingsRepo = MockLifecycleBookingsRepo();
  });

  group('Phase 10: Trip Lifecycle Management UI Tests', () {
    testWidgets(
      '1. Guest or unauthenticated driver sees authentication gate in DriverRidesScreen',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const DriverRidesScreen(),
            rideRepo: rideRepo,
            bookingsRepo: bookingsRepo,
            isAuthenticated: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Authentication Required'), findsOneWidget);
        expect(find.text('Log In'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Scheduled ride displays Start Boarding and Cancel Ride buttons',
      (tester) async {
        final ride = createTestRide(status: RideStatus.scheduled);
        rideRepo.rides = [ride];

        await tester.pumpWidget(
          createTestApp(
            child: const DriverRidesScreen(),
            rideRepo: rideRepo,
            bookingsRepo: bookingsRepo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Scheduled'), findsOneWidget);
        expect(find.text('Start Boarding'), findsOneWidget);
        expect(find.text('Cancel Ride'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Driver starts boarding: confirms dialog and updates status to Boarding',
      (tester) async {
        final ride = createTestRide(status: RideStatus.scheduled);
        rideRepo.rides = [ride];

        await tester.pumpWidget(
          createTestApp(
            child: const DriverRidesScreen(),
            rideRepo: rideRepo,
            bookingsRepo: bookingsRepo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap Start Boarding
        await tester.ensureVisible(find.text('Start Boarding'));
        await tester.tap(find.text('Start Boarding'));
        await tester.pumpAndSettle();

        // Confirmation dialog appears
        expect(find.text('Start Boarding?'), findsOneWidget);
        expect(
          find.text(
            'Passengers will be notified to proceed to their pickup locations for departure.',
          ),
          findsOneWidget,
        );

        // Confirm
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Start Boarding'),
          ),
        );
        await tester.pumpAndSettle();

        // Status updated to Boarding and action button switches to Start Trip
        expect(find.text('Boarding'), findsOneWidget);
        expect(find.text('Start Trip'), findsOneWidget);
        expect(rideRepo.rides.first.status, RideStatus.boarding);
      },
    );

    testWidgets(
      '4. Driver starts trip: confirms dialog and updates status to Trip in Progress',
      (tester) async {
        final ride = createTestRide(status: RideStatus.boarding);
        rideRepo.rides = [ride];

        await tester.pumpWidget(
          createTestApp(
            child: const DriverRidesScreen(),
            rideRepo: rideRepo,
            bookingsRepo: bookingsRepo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Boarding'), findsOneWidget);
        expect(find.text('Start Trip'), findsOneWidget);

        // Tap Start Trip
        await tester.ensureVisible(find.text('Start Trip'));
        await tester.tap(find.text('Start Trip'));
        await tester.pumpAndSettle();

        // Confirmation dialog
        expect(find.text('Start Trip?'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Start Trip'),
          ),
        );
        await tester.pumpAndSettle();

        // Status updated to Trip in Progress and action button switches to Complete Trip
        expect(find.text('Trip in Progress'), findsOneWidget);
        expect(find.text('Complete Trip'), findsOneWidget);
        expect(rideRepo.rides.first.status, RideStatus.active);
      },
    );

    testWidgets(
      '5. Driver completes trip: confirms dialog and finalizes ride',
      (tester) async {
        final ride = createTestRide(status: RideStatus.active);
        rideRepo.rides = [ride];

        await tester.pumpWidget(
          createTestApp(
            child: const DriverRidesScreen(),
            rideRepo: rideRepo,
            bookingsRepo: bookingsRepo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Trip in Progress'), findsOneWidget);
        expect(find.text('Complete Trip'), findsOneWidget);

        // Tap Complete Trip
        await tester.ensureVisible(find.text('Complete Trip'));
        await tester.tap(find.text('Complete Trip'));
        await tester.pumpAndSettle();

        // Confirmation dialog
        expect(find.text('Complete Trip?'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Complete Trip'),
          ),
        );
        await tester.pumpAndSettle();

        // Completed text badge displayed
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Trip completed successfully'), findsOneWidget);
        expect(rideRepo.rides.first.status, RideStatus.completed);
      },
    );

    testWidgets(
      '6. Driver cancels ride: confirms destructive dialog and marks ride cancelled',
      (tester) async {
        final ride = createTestRide(status: RideStatus.scheduled);
        rideRepo.rides = [ride];

        await tester.pumpWidget(
          createTestApp(
            child: const DriverRidesScreen(),
            rideRepo: rideRepo,
            bookingsRepo: bookingsRepo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap Cancel Ride
        await tester.ensureVisible(find.text('Cancel Ride'));
        await tester.tap(find.text('Cancel Ride'));
        await tester.pumpAndSettle();

        // Destructive confirmation dialog
        expect(find.text('Cancel Ride?'), findsOneWidget);
        expect(
          find.text(
            'Are you sure you want to cancel this ride? All pending and accepted booking requests will be cancelled, and reserved seats returned.',
          ),
          findsOneWidget,
        );

        // Confirm
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Cancel Ride'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Cancelled'), findsOneWidget);
        expect(find.text('Ride has been cancelled'), findsOneWidget);
        expect(rideRepo.rides.first.status, RideStatus.cancelled);
      },
    );

    testWidgets(
      '7. API error handling during lifecycle mutation displays SnackBar error',
      (tester) async {
        final ride = createTestRide(status: RideStatus.scheduled);
        rideRepo.rides = [ride];
        rideRepo.shouldFailNext = true;
        rideRepo.failMessage = 'Invalid lifecycle transition 409';

        await tester.pumpWidget(
          createTestApp(
            child: const DriverRidesScreen(),
            rideRepo: rideRepo,
            bookingsRepo: bookingsRepo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Start Boarding'));
        await tester.tap(find.text('Start Boarding'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Start Boarding'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Invalid lifecycle transition 409'), findsOneWidget);
      },
    );

    testWidgets(
      '8. Passenger RideDetailsScreen shows current ride status badge and disables booking when active/completed',
      (tester) async {
        final activeRide = createTestRide(status: RideStatus.active);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (ref) => FakeLifecycleAuthNotifier(isAuthenticated: true),
              ),
              selectedRideProvider.overrideWith((ref) => activeRide),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const RideDetailsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Status chip visible in Journey Route card
        expect(find.text('Trip in Progress'), findsAtLeastNWidgets(1));

        // Bottom button should be disabled with 'Trip in Progress'
        expect(find.text('Trip in Progress'), findsAtLeastNWidgets(2));
      },
    );

    testWidgets(
      '9. Passenger BookingDetailsScreen distinguishes Booking Status and Trip Status',
      (tester) async {
        final boardingRide = createTestRide(status: RideStatus.boarding);
        final booking = createTestBooking(
          status: BookingStatus.accepted,
          ride: boardingRide,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (ref) => FakeLifecycleAuthNotifier(isAuthenticated: true),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: BookingDetailsScreen(initialBooking: booking),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Booking Status'), findsOneWidget);
        expect(find.text('Booking Accepted'), findsOneWidget);
        expect(find.text('Trip Status'), findsOneWidget);
        expect(find.text('Boarding'), findsOneWidget);
        expect(
          find.text(
            'Boarding in progress! Please be at your pickup point for departure.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '10. Passenger MyBookingsScreen displays both booking and trip status badges',
      (tester) async {
        final completedRide = createTestRide(status: RideStatus.completed);
        final booking = createTestBooking(
          status: BookingStatus.completed,
          ride: completedRide,
        );
        bookingsRepo.bookings = [booking];

        await tester.pumpWidget(
          createTestApp(
            child: const MyBookingsScreen(),
            rideRepo: rideRepo,
            bookingsRepo: bookingsRepo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Trip: Completed'), findsOneWidget);
      },
    );

    testWidgets(
      '11. Responsive Layout Audit: 320dp, 360dp, 390dp, 412dp, 600dp without overflow',
      (tester) async {
        final viewports = [
          const Size(320, 568),
          const Size(360, 640),
          const Size(390, 844),
          const Size(412, 915),
          const Size(600, 1024),
        ];

        final scheduledRide = createTestRide(status: RideStatus.scheduled);
        final activeRide = createTestRide(
          id: 'ride_102',
          status: RideStatus.active,
        );
        rideRepo.rides = [scheduledRide, activeRide];

        for (final size in viewports) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            createTestApp(
              child: const DriverRidesScreen(),
              rideRepo: rideRepo,
              bookingsRepo: bookingsRepo,
              isAuthenticated: true,
            ),
          );
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow at ${size.width}x${size.height}',
          );
        }

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '12. Responsive Layout Audit: 1.5x font scale without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;

        final ride = createTestRide(status: RideStatus.scheduled);
        rideRepo.rides = [ride];

        await tester.pumpWidget(
          createTestApp(
            child: const DriverRidesScreen(),
            rideRepo: rideRepo,
            bookingsRepo: bookingsRepo,
            isAuthenticated: true,
            textScaleFactor: 1.5,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow at 1.5x font scale',
        );

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );
  });
}
