import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/providers/user_mode_provider.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/bookings/data/bookings_repository.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/features/bookings/presentation/bookings_provider.dart';
import 'package:sahyan/features/bookings/presentation/screens/booking_confirmation_screen.dart';
import 'package:sahyan/features/bookings/presentation/screens/booking_details_screen.dart';
import 'package:sahyan/features/bookings/presentation/screens/confirm_pay_screen.dart';
import 'package:sahyan/features/bookings/presentation/screens/my_bookings_screen.dart';
import 'package:sahyan/features/rides/presentation/screens/ride_details_screen.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/features/auth/data/auth_repository.dart';
import 'package:sahyan/features/rides/presentation/rides_provider.dart';
import 'package:sahyan/features/rides/presentation/widgets/request_seat_bottom_sheet.dart';
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
    id: 'usr_test_passenger',
    name: 'Test Passenger',
    phone: '+919876543210',
    email: 'passenger@example.com',
    city: 'Ahmedabad',
    verificationStatus: UserVerificationStatus.verified,
    rating: 5.0,
    totalRides: 0,
  );
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier({bool isAuthenticated = true})
    : super(
        repository: _FakeAuthRepo(),
        storageService: _FakeAuthStorage(),
        apiClient: ApiClient(),
      ) {
    state = isAuthenticated
        ? const AuthState(
            status: AuthStatus.authenticated,
            user: UserModel(
              id: 'usr_test_passenger',
              name: 'Test Passenger',
              phone: '+919876543210',
              email: 'passenger@example.com',
              city: 'Ahmedabad',
              verificationStatus: UserVerificationStatus.verified,
              rating: 5.0,
              totalRides: 0,
            ),
            token: 'valid_jwt_token',
          )
        : const AuthState(status: AuthStatus.unauthenticated);
  }
}

class MockBookingsRepoForTest implements BookingsRepository {
  List<BookingModel> bookings = [];
  bool shouldFail = false;
  String failMessage = 'Insufficient seats available';

  @override
  Future<BookingModel> createBooking({
    required String rideId,
    required int requestedSeats,
    String? passengerNote,
    LocationModel? pickup,
    LocationModel? drop,
  }) async {
    if (shouldFail) {
      throw Exception(failMessage);
    }

    final newBooking = BookingModel(
      id: 'bk_test_123',
      rideId: rideId,
      passengerId: 'usr_test_passenger',
      requestedSeats: requestedSeats,
      contributionPerSeat: 350.0,
      totalContribution: requestedSeats * 350.0,
      status: BookingStatus.pending,
      passengerNote: passengerNote ?? '',
      pickup:
          pickup ??
          LocationModel.fromCoordinates(
            name: 'Bhuj',
            latitude: 23.24,
            longitude: 69.66,
          ),
      drop:
          drop ??
          LocationModel.fromCoordinates(
            name: 'Ahmedabad',
            latitude: 23.02,
            longitude: 72.57,
          ),
      createdAt: DateTime.now(),
    );

    bookings.insert(0, newBooking);
    return newBooking;
  }

  @override
  Future<List<BookingModel>> getMyBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    if (status != null && status.isNotEmpty && status != 'all') {
      return bookings.where((b) => b.status.name == status).toList();
    }
    return List.from(bookings);
  }

  @override
  Future<BookingModel> getBookingById(String id) async {
    return bookings.firstWhere((b) => b.id == id);
  }

  @override
  Future<BookingModel> cancelBooking(String id) async {
    final index = bookings.indexWhere((b) => b.id == id);
    if (index == -1) throw Exception('Booking not found');

    final old = bookings[index];
    final updated = BookingModel(
      id: old.id,
      rideId: old.rideId,
      ride: old.ride,
      passengerId: old.passengerId,
      passenger: old.passenger,
      requestedSeats: old.requestedSeats,
      contributionPerSeat: old.contributionPerSeat,
      totalContribution: old.totalContribution,
      status: BookingStatus.cancelled,
      passengerNote: old.passengerNote,
      pickup: old.pickup,
      drop: old.drop,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );

    bookings[index] = updated;
    return updated;
  }
}

RideModel createSampleRide({int availableSeats = 3}) {
  return RideModel(
    id: 'ride_sample_123',
    driverId: 'driver_1',
    driverName: 'Karan Dave',
    driverRating: 4.8,
    isDriverVerified: true,
    vehicle: const VehicleModel(
      id: 'veh_1',
      ownerId: 'driver_1',
      make: 'Maruti',
      model: 'Ertiga',
      year: 2022,
      color: 'White',
      registrationNumber: 'GJ-12-AB-1234',
      vehicleType: 'car',
      seatCapacity: 6,
    ),
    origin: LocationModel.fromCoordinates(
      name: 'Jubeli Ground, Bhuj',
      latitude: 23.242,
      longitude: 69.667,
    ),
    destination: LocationModel.fromCoordinates(
      name: 'ISKCON Cross Road, Ahmedabad',
      latitude: 23.028,
      longitude: 72.506,
    ),
    dateTime: DateTime(2026, 9, 10, 8, 30),
    departureTime: '8:30 AM',
    estimatedArrival: '2:30 PM',
    availableSeats: availableSeats,
    totalSeats: 4,
    contributionPerSeat: 350.0,
    status: RideStatus.scheduled,
    amenities: const ['AC', 'Music', 'Luggage space'],
  );
}

BookingModel createSampleBooking({
  BookingStatus status = BookingStatus.pending,
  int requestedSeats = 2,
}) {
  final ride = createSampleRide();
  return BookingModel(
    id: 'bk_existing_456',
    rideId: ride.id,
    ride: ride,
    passengerId: 'usr_passenger_1',
    passenger: const UserModel(
      id: 'usr_passenger_1',
      name: 'Zaid Patel',
      phone: '9876543210',
      email: 'zaid@example.com',
      city: 'Bhuj',
      verificationStatus: UserVerificationStatus.verified,
      rating: 5.0,
      totalRides: 10,
    ),
    requestedSeats: requestedSeats,
    contributionPerSeat: 350.0,
    totalContribution: requestedSeats * 350.0,
    status: status,
    passengerNote: 'I will wait at highway junction',
    pickup: ride.origin,
    drop: ride.destination,
    createdAt: DateTime(2026, 9, 8, 10, 0),
  );
}

void main() {
  group('RequestSeatBottomSheet & Booking Flow Tests', () {
    testWidgets(
      'Renders seat request bottom sheet with correct route, price, and stepper',
      (tester) async {
        final ride = createSampleRide(availableSeats: 3);
        final mockRepo = MockBookingsRepoForTest();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [bookingsRepositoryProvider.overrideWithValue(mockRepo)],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(body: RequestSeatBottomSheet(ride: ride)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check header and route
        expect(find.text('Request a Seat'), findsOneWidget);
        expect(find.text('Bhuj → Ahmedabad'), findsOneWidget);
        expect(find.text('3 seats currently available'), findsOneWidget);

        // Initial seat count is 1 and contribution is ₹350
        expect(find.text('1'), findsOneWidget);
        expect(find.text('₹350 per seat'), findsOneWidget);
        expect(find.text('₹350'), findsOneWidget);

        // Increment seat count to 2
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();

        expect(find.text('2'), findsOneWidget);
        expect(find.text('₹700'), findsOneWidget);

        // Increment to 3 (max available)
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();

        expect(find.text('3'), findsOneWidget);
        expect(find.text('₹1050'), findsOneWidget);

        // Trying to increment past max seats should not exceed 3
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();
        expect(find.text('3'), findsOneWidget);

        // Decrement back to 2
        await tester.tap(find.byIcon(Icons.remove_rounded));
        await tester.pumpAndSettle();
        expect(find.text('2'), findsOneWidget);
        expect(find.text('₹700'), findsOneWidget);

        // Buttons present
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Send Request'), findsOneWidget);
      },
    );

    testWidgets('Submits booking request successfully and triggers API call', (
      tester,
    ) async {
      final ride = createSampleRide(availableSeats: 2);
      final mockRepo = MockBookingsRepoForTest();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingsRepositoryProvider.overrideWithValue(mockRepo),
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(isAuthenticated: true),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: RequestSeatBottomSheet(ride: ride)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter note
      await tester.enterText(
        find.byType(TextField),
        'Waiting at the main bus stand',
      );
      await tester.pumpAndSettle();

      // Tap Send Request
      await tester.ensureVisible(find.text('Send Request'));
      await tester.tap(find.text('Send Request'));
      await tester.pump();

      // Repo received the booking
      expect(mockRepo.bookings.length, 1);
      expect(mockRepo.bookings.first.requestedSeats, 1);
      expect(
        mockRepo.bookings.first.passengerNote,
        'Waiting at the main bus stand',
      );
      expect(mockRepo.bookings.first.status, BookingStatus.pending);
    });

    testWidgets('Displays error message when booking API fails', (
      tester,
    ) async {
      final ride = createSampleRide(availableSeats: 1);
      final mockRepo = MockBookingsRepoForTest()
        ..shouldFail = true
        ..failMessage = 'Insufficient capacity for this ride';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingsRepositoryProvider.overrideWithValue(mockRepo),
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(isAuthenticated: true),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: RequestSeatBottomSheet(ride: ride)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Send Request'));
      await tester.tap(find.text('Send Request'));
      await tester.pumpAndSettle();

      expect(find.text('Insufficient capacity for this ride'), findsOneWidget);
    });

    testWidgets('Guest user tapping Request Seat triggers AuthGateDialog', (
      tester,
    ) async {
      final ride = createSampleRide();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedRideProvider.overrideWith((ref) => ride),
            userModeProvider.overrideWith((ref) {
              final notifier = UserModeNotifier();
              notifier.setGuestMode();
              return notifier;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RideDetailsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Request Seat button
      await tester.tap(find.text('Request Seat'));
      await tester.pumpAndSettle();

      // Auth gate dialog should appear
      expect(find.text('Sign In to Request Seat'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Log In to Existing Account'), findsOneWidget);
    });
  });

  group('MyBookingsScreen Tests', () {
    testWidgets('Displays empty state when user has no bookings', (
      tester,
    ) async {
      final mockRepo = MockBookingsRepoForTest();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [bookingsRepositoryProvider.overrideWithValue(mockRepo)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MyBookingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No ride bookings yet'), findsOneWidget);
    });

    testWidgets('Displays booking cards with Pending status badge', (
      tester,
    ) async {
      final mockRepo = MockBookingsRepoForTest();
      mockRepo.bookings.add(createSampleBooking());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [bookingsRepositoryProvider.overrideWithValue(mockRepo)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MyBookingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending Driver Approval'), findsOneWidget);
      expect(find.text('Bhuj → Ahmedabad'), findsOneWidget);
      expect(find.text('2 seats'), findsOneWidget);
      expect(find.text('₹700'), findsOneWidget);
    });

    testWidgets(
      'Filter chips switch view between All, Pending, and Cancelled',
      (tester) async {
        final mockRepo = MockBookingsRepoForTest();
        mockRepo.bookings.add(
          createSampleBooking(status: BookingStatus.pending),
        );
        mockRepo.bookings.add(
          createSampleBooking(status: BookingStatus.cancelled),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [bookingsRepositoryProvider.overrideWithValue(mockRepo)],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const MyBookingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // All tab shows 2 bookings
        expect(find.byType(Card), findsNWidgets(2));

        // Filter by Pending
        await tester.tap(find.text('Pending Approval'));
        await tester.pumpAndSettle();
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Pending Driver Approval'), findsOneWidget);

        // Filter by Cancelled
        await tester.tap(find.text('Cancelled'));
        await tester.pumpAndSettle();
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Cancelled'), findsNWidgets(2));
      },
    );
  });

  group('BookingDetailsScreen Tests', () {
    testWidgets(
      'Renders complete booking details and allows cancelling a pending booking',
      (tester) async {
        final mockRepo = MockBookingsRepoForTest();
        final booking = createSampleBooking(status: BookingStatus.pending);
        mockRepo.bookings.add(booking);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [bookingsRepositoryProvider.overrideWithValue(mockRepo)],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: BookingDetailsScreen(initialBooking: booking),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check details
        expect(find.text('Booking Details'), findsOneWidget);
        expect(find.text('Pending Driver Approval'), findsOneWidget);
        expect(find.text('Journey Overview'), findsOneWidget);
        expect(find.text('Driver & Vehicle'), findsOneWidget);
        expect(find.text('Karan Dave'), findsOneWidget);
        expect(find.text('Contribution Details'), findsOneWidget);
        expect(find.text('Cancel Request'), findsOneWidget);

        // Tap Cancel Request button
        await tester.ensureVisible(find.text('Cancel Request'));
        await tester.tap(find.text('Cancel Request'));
        await tester.pumpAndSettle();

        // Confirmation dialog appears
        expect(find.text('Cancel Seat Request?'), findsOneWidget);
        expect(find.text('Keep Request'), findsOneWidget);

        // Confirm cancellation in dialog
        final dialogCancelButton = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cancel Request'),
        );
        await tester.tap(dialogCancelButton);
        await tester.pumpAndSettle();

        // Status is updated to Cancelled
        expect(find.text('Cancelled'), findsOneWidget);
        expect(mockRepo.bookings.first.status, BookingStatus.cancelled);
      },
    );
  });

  group('Responsive Layout Testing Across Viewports & 1.5x Text Scale', () {
    final viewports = [
      const Size(320, 568),
      const Size(360, 640),
      const Size(390, 844),
      const Size(412, 915),
      const Size(600, 1024),
    ];

    for (final size in viewports) {
      testWidgets(
        'RequestSeatBottomSheet renders without overflow at ${size.width}x${size.height}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          final ride = createSampleRide();
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: Scaffold(body: RequestSeatBottomSheet(ride: ride)),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'MyBookingsScreen renders without overflow at ${size.width}x${size.height}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          final mockRepo = MockBookingsRepoForTest();
          mockRepo.bookings.add(createSampleBooking());

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                bookingsRepositoryProvider.overrideWithValue(mockRepo),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const MyBookingsScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'BookingDetailsScreen renders without overflow at ${size.width}x${size.height}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          final booking = createSampleBooking();
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: BookingDetailsScreen(initialBooking: booking),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'RequestSeatBottomSheet renders without overflow under 1.5x text scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final ride = createSampleRide();
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.5)),
                  child: child!,
                );
              },
              home: Scaffold(body: RequestSeatBottomSheet(ride: ride)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'BookingDetailsScreen renders without overflow under 1.5x text scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final booking = createSampleBooking();
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.5)),
                  child: child!,
                );
              },
              home: BookingDetailsScreen(initialBooking: booking),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ConfirmPayScreen renders without overflow under 1.5x text scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final ride = createSampleRide();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedRideProvider.overrideWith((ref) => ride),
              selectedSeatsProvider.overrideWith((ref) => ['A1', 'A2']),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.5)),
                  child: child!,
                );
              },
              home: const ConfirmPayScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'BookingConfirmationScreen renders without overflow under 1.5x text scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final booking = createSampleBooking();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [activeBookingProvider.overrideWith((ref) => booking)],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.5)),
                  child: child!,
                );
              },
              home: const BookingConfirmationScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('ConfirmPayScreen and BookingConfirmationScreen Hardening Tests', () {
    testWidgets(
      'ConfirmPayScreen displays Contribution terminology and zero payment or escrow terms',
      (tester) async {
        final ride = createSampleRide();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedRideProvider.overrideWith((ref) => ride),
              selectedSeatsProvider.overrideWith((ref) => ['A1', 'A2']),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ConfirmPayScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Validated clean terminology
        expect(find.text('Booking Request Summary'), findsOneWidget);
        expect(find.text('Contribution Details'), findsOneWidget);
        expect(find.text('Seat Contribution (2 seats)'), findsOneWidget);
        expect(find.text('Total Contribution'), findsOneWidget);
        expect(find.text('Pending Driver Approval'), findsOneWidget);
        expect(find.text('Send Request'), findsOneWidget);

        // Verify zero legacy payment or escrow terms
        expect(find.textContaining('Escrow'), findsNothing);
        expect(find.textContaining('Platform Fee'), findsNothing);
        expect(find.textContaining('Total Payable'), findsNothing);
        expect(find.textContaining('Pay ₹'), findsNothing);
      },
    );

    testWidgets(
      'ConfirmPayScreen triggers AuthGateDialog when unauthenticated user clicks Send Request',
      (tester) async {
        final ride = createSampleRide();
        final mockRepo = MockBookingsRepoForTest();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedRideProvider.overrideWith((ref) => ride),
              selectedSeatsProvider.overrideWith((ref) => ['A1']),
              bookingsRepositoryProvider.overrideWithValue(mockRepo),
              authProvider.overrideWith(
                (ref) => FakeAuthNotifier(isAuthenticated: false),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ConfirmPayScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Send Request'));
        await tester.pumpAndSettle();

        // AuthGateDialog must be triggered, and 0 bookings created
        expect(find.text('Sign In to Request Seat'), findsOneWidget);
        expect(mockRepo.bookings.length, 0);
      },
    );

    testWidgets(
      'BookingConfirmationScreen displays Request Sent and Pending Driver Approval without payment terms',
      (tester) async {
        final booking = createSampleBooking(status: BookingStatus.pending);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [activeBookingProvider.overrideWith((ref) => booking)],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const BookingConfirmationScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Request Sent'), findsOneWidget);
        expect(find.text('Pending Driver Approval'), findsOneWidget);
        expect(
          find.textContaining('The driver needs to approve your request'),
          findsOneWidget,
        );
        expect(find.text('Total Contribution'), findsOneWidget);
        expect(find.text('View My Bookings'), findsOneWidget);
        expect(find.text('Back to Home'), findsOneWidget);

        // Verify zero payment/escrow terms
        expect(find.textContaining('Escrow'), findsNothing);
        expect(find.textContaining('Payable'), findsNothing);
        expect(find.textContaining('Platform Fee'), findsNothing);
      },
    );
  });
}
