import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/features/auth/data/auth_repository.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/bookings/data/bookings_repository.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/features/bookings/presentation/bookings_provider.dart';
import 'package:sahyan/features/bookings/presentation/screens/driver_request_details_screen.dart';
import 'package:sahyan/features/bookings/presentation/screens/driver_rides_screen.dart';
import 'package:sahyan/features/bookings/presentation/screens/my_bookings_screen.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/features/rides/data/ride_repository.dart';
import 'package:sahyan/features/rides/domain/ride_search_result.dart';
import 'package:sahyan/features/rides/presentation/rides_provider.dart';
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
    name: 'Test Driver',
    phone: '+919876543210',
    email: 'driver@example.com',
    city: 'Ahmedabad',
    verificationStatus: UserVerificationStatus.verified,
    rating: 4.9,
    totalRides: 12,
  );
}

class FakeDriverAuthNotifier extends AuthNotifier {
  final bool _initialAuth;

  FakeDriverAuthNotifier({bool isAuthenticated = true})
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
              name: 'Test Driver',
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

class FakeRideRepo implements RideRepository {
  List<RideModel> rides = [];

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
  }) async => rides.first;

  @override
  Future<List<RideModel>> getMyRides({String? status}) async => rides;

  @override
  Future<RideModel> getRideById(String id) async =>
      rides.firstWhere((r) => r.id == id);

  @override
  Future<RideModel> cancelRide(String id) async =>
      rides.firstWhere((r) => r.id == id);

  @override
  Future<RouteInfo> calculateRoute({
    required LocationModel origin,
    required LocationModel destination,
  }) async {
    return const RouteInfo(
      encodedPolyline: 'dummy_poly',
      distanceMeters: 100000,
      durationSeconds: 3600,
    );
  }

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

class MockDriverBookingsRepo implements BookingsRepository {
  List<BookingModel> bookings = [];
  bool shouldFail = false;
  String failMessage = 'Server error';

  @override
  Future<BookingModel> createBooking({
    required String rideId,
    required int requestedSeats,
    String? passengerNote,
    LocationModel? pickup,
    LocationModel? drop,
  }) async {
    if (shouldFail) throw Exception(failMessage);
    final b = BookingModel(
      id: 'bk_${DateTime.now().millisecondsSinceEpoch}',
      rideId: rideId,
      passengerId: 'usr_passenger_1',
      requestedSeats: requestedSeats,
      contributionPerSeat: 350.0,
      totalContribution: requestedSeats * 350.0,
      status: BookingStatus.pending,
      pickup:
          pickup ??
          LocationModel.fromCoordinates(
            name: 'Origin',
            latitude: 23.0,
            longitude: 72.0,
          ),
      drop:
          drop ??
          LocationModel.fromCoordinates(
            name: 'Destination',
            latitude: 22.0,
            longitude: 70.0,
          ),
      createdAt: DateTime.now(),
    );
    bookings.add(b);
    return b;
  }

  @override
  Future<List<BookingModel>> getMyBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    if (shouldFail) throw Exception(failMessage);
    if (status != null && status.isNotEmpty && status != 'all') {
      return bookings.where((b) => b.status.name == status).toList();
    }
    return List.from(bookings);
  }

  @override
  Future<BookingModel> getBookingById(String id) async {
    if (shouldFail) throw Exception(failMessage);
    return bookings.firstWhere((b) => b.id == id);
  }

  @override
  Future<BookingModel> cancelBooking(String id) async {
    if (shouldFail) throw Exception(failMessage);
    final idx = bookings.indexWhere((b) => b.id == id);
    if (idx == -1) throw Exception('Booking not found');
    final updated = BookingModel(
      id: bookings[idx].id,
      rideId: bookings[idx].rideId,
      ride: bookings[idx].ride,
      passengerId: bookings[idx].passengerId,
      passenger: bookings[idx].passenger,
      requestedSeats: bookings[idx].requestedSeats,
      contributionPerSeat: bookings[idx].contributionPerSeat,
      totalContribution: bookings[idx].totalContribution,
      status: BookingStatus.cancelled,
      passengerNote: bookings[idx].passengerNote,
      pickup: bookings[idx].pickup,
      drop: bookings[idx].drop,
      createdAt: bookings[idx].createdAt,
    );
    bookings[idx] = updated;
    return updated;
  }

  @override
  Future<List<BookingModel>> getDriverBookingRequests({
    String? status,
    String? rideId,
    int page = 1,
    int limit = 50,
  }) async {
    if (shouldFail) throw Exception(failMessage);
    var results = List<BookingModel>.from(bookings);
    if (rideId != null && rideId.isNotEmpty) {
      results = results.where((b) => b.rideId == rideId).toList();
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      results = results.where((b) => b.status.name == status).toList();
    }
    return results;
  }

  @override
  Future<BookingModel> acceptBooking(String id) async {
    if (shouldFail) throw Exception(failMessage);
    final idx = bookings.indexWhere((b) => b.id == id);
    if (idx == -1) throw Exception('Booking not found');
    final updated = BookingModel(
      id: bookings[idx].id,
      rideId: bookings[idx].rideId,
      ride: bookings[idx].ride,
      passengerId: bookings[idx].passengerId,
      passenger: bookings[idx].passenger,
      requestedSeats: bookings[idx].requestedSeats,
      contributionPerSeat: bookings[idx].contributionPerSeat,
      totalContribution: bookings[idx].totalContribution,
      status: BookingStatus.accepted,
      passengerNote: bookings[idx].passengerNote,
      pickup: bookings[idx].pickup,
      drop: bookings[idx].drop,
      createdAt: bookings[idx].createdAt,
    );
    bookings[idx] = updated;
    return updated;
  }

  @override
  Future<BookingModel> rejectBooking(String id) async {
    if (shouldFail) throw Exception(failMessage);
    final idx = bookings.indexWhere((b) => b.id == id);
    if (idx == -1) throw Exception('Booking not found');
    final updated = BookingModel(
      id: bookings[idx].id,
      rideId: bookings[idx].rideId,
      ride: bookings[idx].ride,
      passengerId: bookings[idx].passengerId,
      passenger: bookings[idx].passenger,
      requestedSeats: bookings[idx].requestedSeats,
      contributionPerSeat: bookings[idx].contributionPerSeat,
      totalContribution: bookings[idx].totalContribution,
      status: BookingStatus.rejected,
      passengerNote: bookings[idx].passengerNote,
      pickup: bookings[idx].pickup,
      drop: bookings[idx].drop,
      createdAt: bookings[idx].createdAt,
    );
    bookings[idx] = updated;
    return updated;
  }
}

RideModel createTestRide({
  String id = 'ride_123',
  int availableSeats = 2,
  int totalSeats = 4,
}) {
  return RideModel(
    id: id,
    driverId: 'usr_test_driver',
    driverName: 'Test Driver',
    driverRating: 4.9,
    isDriverVerified: true,
    vehicle: const VehicleModel(
      id: 'veh_test_1',
      ownerId: 'usr_test_driver',
      make: 'Maruti',
      model: 'Ertiga',
      year: 2022,
      color: 'White',
      registrationNumber: 'GJ-12-AB-1234',
      vehicleType: 'car',
      seatCapacity: 6,
    ),
    origin: LocationModel.fromCoordinates(
      name: 'Ahmedabad',
      latitude: 23.0225,
      longitude: 72.5714,
    ),
    destination: LocationModel.fromCoordinates(
      name: 'Rajkot',
      latitude: 22.3039,
      longitude: 70.8022,
    ),
    dateTime: DateTime(2026, 9, 15, 8, 30),
    departureTime: '8:30 AM',
    estimatedArrival: '2:30 PM',
    totalSeats: totalSeats,
    availableSeats: availableSeats,
    contributionPerSeat: 350.0,
    status: RideStatus.scheduled,
    amenities: const ['AC', 'Music'],
  );
}

BookingModel createTestBooking({
  String id = 'bk_001',
  String rideId = 'ride_123',
  BookingStatus status = BookingStatus.pending,
  int seats = 2,
  String note = 'Need pickup at SG Highway',
}) {
  return BookingModel(
    id: id,
    rideId: rideId,
    ride: createTestRide(id: rideId),
    passengerId: 'usr_passenger_1',
    passenger: const UserModel(
      id: 'usr_passenger_1',
      name: 'Rohan Sharma',
      phone: '+919876500001',
      email: 'rohan@example.com',
      city: 'Ahmedabad',
      rating: 4.8,
      totalRides: 5,
      verificationStatus: UserVerificationStatus.verified,
    ),
    requestedSeats: seats,
    contributionPerSeat: 350.0,
    totalContribution: seats * 350.0,
    status: status,
    passengerNote: note,
    pickup: LocationModel.fromCoordinates(
      name: 'SG Highway, Ahmedabad',
      latitude: 23.03,
      longitude: 72.52,
    ),
    drop: LocationModel.fromCoordinates(
      name: 'Kalawad Road, Rajkot',
      latitude: 22.28,
      longitude: 70.78,
    ),
    createdAt: DateTime(2026, 9, 8, 10, 0),
  );
}

Widget createTestApp({
  required Widget child,
  required MockDriverBookingsRepo bookingsRepo,
  bool isAuthenticated = true,
  FakeRideRepo? rideRepo,
  double textScaleFactor = 1.0,
}) {
  final ridesRepo = rideRepo ?? FakeRideRepo();
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        (ref) => FakeDriverAuthNotifier(isAuthenticated: isAuthenticated),
      ),
      bookingsRepositoryProvider.overrideWithValue(bookingsRepo),
      rideApiRepositoryProvider.overrideWithValue(ridesRepo),
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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 9: Driver Booking Request Management UI Tests', () {
    late MockDriverBookingsRepo bookingsRepo;
    late FakeRideRepo rideRepo;

    setUp(() {
      bookingsRepo = MockDriverBookingsRepo();
      rideRepo = FakeRideRepo();
    });

    testWidgets('1. Guest or unauthenticated driver sees authentication gate', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: const DriverRidesScreen(),
          bookingsRepo: bookingsRepo,
          isAuthenticated: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Authentication Required'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('My Offered Rides'), findsNothing);
    });

    testWidgets(
      '2. Authenticated driver sees empty state when no requests exist',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const DriverRidesScreen(),
            bookingsRepo: bookingsRepo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No Booking Requests Found'), findsOneWidget);
        expect(find.text('0 Pending Requests'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Driver sees pending passenger request card with route and details',
      (tester) async {
        final sampleRide = createTestRide();
        rideRepo.rides = [sampleRide];
        bookingsRepo.bookings = [createTestBooking(rideId: sampleRide.id)];

        await tester.pumpWidget(
          createTestApp(
            child: const DriverRidesScreen(),
            bookingsRepo: bookingsRepo,
            rideRepo: rideRepo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('1 Pending Request'), findsOneWidget);
        expect(find.text('Rohan Sharma'), findsOneWidget);
        expect(find.text('2 seats'), findsOneWidget);
        expect(find.text('₹700 total'), findsOneWidget);
        expect(find.text('Pending Driver Approval'), findsOneWidget);
        expect(find.text('Accept'), findsOneWidget);
        expect(find.text('Reject'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Driver accepts pending request: transitions status to accepted',
      (tester) async {
        final sampleRide = createTestRide();
        rideRepo.rides = [sampleRide];
        final booking = createTestBooking(rideId: sampleRide.id);
        bookingsRepo.bookings = [booking];

        await tester.pumpWidget(
          createTestApp(
            child: const DriverRidesScreen(),
            bookingsRepo: bookingsRepo,
            rideRepo: rideRepo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap Accept
        await tester.tap(find.text('Accept'));
        await tester.pumpAndSettle();

        // Confirm in dialog
        expect(find.text('Accept Booking Request?'), findsOneWidget);
        await tester.tap(find.text('Accept Request'));
        await tester.pumpAndSettle();

        // Status should update to Booking Accepted
        expect(find.text('Booking Accepted'), findsOneWidget);
        expect(bookingsRepo.bookings.first.status, BookingStatus.accepted);
      },
    );

    testWidgets(
      '5. Driver rejects pending request: transitions status to rejected',
      (tester) async {
        final sampleRide = createTestRide();
        rideRepo.rides = [sampleRide];
        final booking = createTestBooking(rideId: sampleRide.id);
        bookingsRepo.bookings = [booking];

        await tester.pumpWidget(
          createTestApp(
            child: const DriverRidesScreen(),
            bookingsRepo: bookingsRepo,
            rideRepo: rideRepo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap Reject
        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();

        // Confirm in dialog
        expect(find.text('Decline Booking Request?'), findsOneWidget);
        await tester.tap(find.text('Decline'));
        await tester.pumpAndSettle();

        // Status should update to Request Rejected
        expect(find.text('Request Rejected'), findsOneWidget);
        expect(bookingsRepo.bookings.first.status, BookingStatus.rejected);
      },
    );

    testWidgets(
      '6. DriverRequestDetailsScreen displays full passenger, route, and contribution info',
      (tester) async {
        final booking = createTestBooking();

        await tester.pumpWidget(
          createTestApp(
            child: DriverRequestDetailsScreen(initialRequest: booking),
            bookingsRepo: bookingsRepo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Request Details'), findsOneWidget);
        expect(find.text('Rohan Sharma'), findsOneWidget);
        expect(find.text('Pending Driver Approval'), findsOneWidget);
        expect(find.text('SG Highway, Ahmedabad'), findsOneWidget);
        expect(find.text('Kalawad Road, Rajkot'), findsOneWidget);
        expect(find.text('2 seats'), findsOneWidget);
        expect(find.text('₹350'), findsOneWidget);
        expect(find.text('₹700'), findsOneWidget);
        expect(find.text('Need pickup at SG Highway'), findsOneWidget);
        expect(find.text('Accept Request'), findsOneWidget);
        expect(find.text('Decline Request'), findsOneWidget);
      },
    );

    testWidgets('7. Driver accepts from details screen', (tester) async {
      final booking = createTestBooking();
      bookingsRepo.bookings = [booking];

      await tester.pumpWidget(
        createTestApp(
          child: DriverRequestDetailsScreen(initialRequest: booking),
          bookingsRepo: bookingsRepo,
          isAuthenticated: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Accept Request'));
      await tester.tap(find.text('Accept Request'));
      await tester.pumpAndSettle();

      expect(find.text('Accept Booking Request?'), findsOneWidget);
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(find.text('Booking Accepted'), findsOneWidget);
      expect(find.text('Accept Request'), findsNothing);
    });

    testWidgets(
      '8. Passenger MyBookingsScreen displays accepted and rejected statuses',
      (tester) async {
        final acceptedBooking = createTestBooking(
          id: 'bk_acc',
          status: BookingStatus.accepted,
        );
        final rejectedBooking = createTestBooking(
          id: 'bk_rej',
          status: BookingStatus.rejected,
        );
        bookingsRepo.bookings = [acceptedBooking, rejectedBooking];

        await tester.pumpWidget(
          createTestApp(
            child: const MyBookingsScreen(),
            bookingsRepo: bookingsRepo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Booking Accepted'), findsOneWidget);
        expect(find.text('Request Rejected'), findsOneWidget);
      },
    );

    testWidgets(
      '9. Responsive Layout Audit: 320dp, 360dp, 390dp, 412dp, tablet without overflow',
      (tester) async {
        final sampleRide = createTestRide();
        rideRepo.rides = [sampleRide];
        bookingsRepo.bookings = [createTestBooking(rideId: sampleRide.id)];

        final screenSizes = [
          const Size(320, 600),
          const Size(360, 740),
          const Size(390, 844),
          const Size(412, 915),
          const Size(768, 1024),
        ];

        for (final size in screenSizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            createTestApp(
              child: const DriverRidesScreen(),
              bookingsRepo: bookingsRepo,
              rideRepo: rideRepo,
              isAuthenticated: true,
            ),
          );
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow at size $size',
          );
        }

        // Reset
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '10. Responsive Layout Audit: 1.5x font scale without overflow',
      (tester) async {
        FlutterErrorDetails? caughtDetails;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          caughtDetails = details;
        };
        addTearDown(() {
          FlutterError.onError = originalOnError;
        });

        final sampleRide = createTestRide();
        rideRepo.rides = [sampleRide];
        bookingsRepo.bookings = [createTestBooking(rideId: sampleRide.id)];

        await tester.binding.setSurfaceSize(const Size(360, 740));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          createTestApp(
            child: const DriverRidesScreen(),
            bookingsRepo: bookingsRepo,
            rideRepo: rideRepo,
            isAuthenticated: true,
            textScaleFactor: 1.5,
          ),
        );
        await tester.pumpAndSettle();

        FlutterError.onError = originalOnError;
        expect(caughtDetails, isNull, reason: 'Overflow at 1.5x font scale');
      },
    );
  });
}
