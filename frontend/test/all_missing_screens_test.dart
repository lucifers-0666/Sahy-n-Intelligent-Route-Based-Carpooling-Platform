import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/features/auth/data/auth_repository.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/auth/presentation/screens/auth_success_screen.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/features/bookings/presentation/screens/booking_request_screen.dart';
import 'package:sahyan/features/bookings/presentation/screens/cancel_booking_screen.dart';
import 'package:sahyan/features/home/presentation/screens/system_states_screen.dart';
import 'package:sahyan/features/profile/presentation/screens/personal_details_screen.dart';
import 'package:sahyan/features/rides/presentation/rides_provider.dart';
import 'package:sahyan/features/rides/presentation/screens/filter_rides_screen.dart';
import 'package:sahyan/features/rides/presentation/screens/ride_published_screen.dart';
import 'package:sahyan/features/settings/presentation/screens/help_support_screen.dart';
import 'package:sahyan/features/trip/presentation/screens/driver_active_ride_screen.dart';
import 'package:sahyan/features/trip/presentation/screens/safety_center_screen.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/models/ride_model.dart';
import 'package:sahyan/shared/models/user_model.dart';

void main() {
  const testUser = UserModel(
    id: 'user_123',
    name: 'Zaid Amreliya',
    email: 'zaid@example.com',
    phone: '+919876543210',
    city: 'Ahmedabad',
    verificationStatus: UserVerificationStatus.verified,
    rating: 4.9,
    totalRides: 20,
  );

  final testRide = RideModel(
    id: 'ride_101',
    driverId: 'user_123',
    driverName: 'Zaid Amreliya',
    driverRating: 4.9,
    isDriverVerified: true,
    vehicle: const VehicleModel(
      id: 'veh_001',
      ownerId: 'user_123',
      make: 'Hyundai',
      model: 'Verna',
      year: 2022,
      color: 'White',
      registrationNumber: 'GJ-01-AB-1234',
      seatCapacity: 4,
      vehicleType: 'sedan',
      status: 'active',
    ),
    origin: LocationModel.fromCoordinates(
      name: 'Ahmedabad SG Highway',
      latitude: 23.0225,
      longitude: 72.5714,
    ),
    destination: LocationModel.fromCoordinates(
      name: 'Gandhinagar Infocity',
      latitude: 23.2156,
      longitude: 72.6369,
    ),
    dateTime: DateTime.now().add(const Duration(hours: 3)),
    departureTime: '10:00 AM',
    estimatedArrival: '10:45 AM',
    totalSeats: 4,
    availableSeats: 3,
    contributionPerSeat: 150.0,
    status: RideStatus.active,
    amenities: const ['AC', 'Music'],
  );

  final testBooking = BookingModel(
    id: 'booking_202',
    rideId: testRide.id,
    passengerId: testUser.id,
    requestedSeats: 2,
    contributionPerSeat: 150.0,
    totalContribution: 300.0,
    status: BookingStatus.pending,
    pickup: testRide.origin,
    drop: testRide.destination,
    createdAt: DateTime.now(),
  );

  Widget wrapWithScope({
    required Widget child,
    double textScaleFactor = 1.0,
  }) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(
          (ref) => FakeTestAuthNotifier(user: testUser),
        ),
        rideSearchQueryProvider.overrideWith(
          (ref) => RideSearchQuery(
            origin: 'Ahmedabad',
            destination: 'Gandhinagar',
            date: DateTime.now(),
            seats: 2,
            maxContribution: 200,
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, childWidget) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: childWidget!,
          );
        },
        home: child,
      ),
    );
  }

  void verifyNoEmojisInTree(WidgetTester tester) {
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F1E0}-\u{1F1FF}]',
      unicode: true,
    );
    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    for (final textWidget in textWidgets) {
      final text = textWidget.data ?? textWidget.textSpan?.toPlainText() ?? '';
      expect(
        emojiRegex.hasMatch(text),
        isFalse,
        reason: 'Found emoji in Text widget content: "$text"',
      );
    }
  }

  group('AuthSuccessScreen Tests', () {
    testWidgets('Renders all elements without errors or emojis', (tester) async {
      await tester.pumpWidget(
        wrapWithScope(child: const AuthSuccessScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Identity Verification'), findsOneWidget);
      expect(find.text("You're all set"), findsOneWidget);
      expect(find.text('Complete Your Profile'), findsOneWidget);
      verifyNoEmojisInTree(tester);
    });
  });

  group('PersonalDetailsScreen Tests', () {
    testWidgets('Renders profile inputs and save button', (tester) async {
      await tester.pumpWidget(wrapWithScope(child: const PersonalDetailsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Personal Details'), findsOneWidget);
      expect(find.text('Legal Identity'), findsOneWidget);
      expect(find.text('Save & Complete Setup'), findsOneWidget);
      verifyNoEmojisInTree(tester);
    });
  });

  group('FilterRidesScreen Tests', () {
    testWidgets('Renders filter chips and apply CTA', (tester) async {
      await tester.pumpWidget(wrapWithScope(child: const FilterRidesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Filter Rides'), findsOneWidget);
      expect(find.text('DEPARTURE WINDOW'), findsOneWidget);
      expect(find.text('Show Matching Rides'), findsOneWidget);
      verifyNoEmojisInTree(tester);
    });
  });

  group('BookingRequestScreen Tests', () {
    testWidgets('Renders booking request details and action tiles', (tester) async {
      await tester.pumpWidget(
        wrapWithScope(child: BookingRequestScreen(initialBooking: testBooking)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Booking Request'), findsOneWidget);
      expect(find.text('Request Progress'), findsOneWidget);
      expect(find.text('Request Sent'), findsOneWidget);
      verifyNoEmojisInTree(tester);
    });
  });

  group('CancelBookingScreen Tests', () {
    testWidgets('Renders cancellation reasons and confirm CTA', (tester) async {
      await tester.pumpWidget(
        wrapWithScope(child: CancelBookingScreen(initialBooking: testBooking)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancel Booking'), findsOneWidget);
      expect(find.text('Trip Summary'), findsOneWidget);
      expect(find.text('Confirm Cancellation'), findsOneWidget);
      verifyNoEmojisInTree(tester);
    });
  });

  group('RidePublishedScreen Tests', () {
    testWidgets('Renders published ride summary and primary actions', (tester) async {
      await tester.pumpWidget(
        wrapWithScope(child: RidePublishedScreen(publishedRide: testRide)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ride Published'), findsOneWidget);
      expect(find.text('Ride Published Successfully!'), findsOneWidget);
      expect(find.text('View in My Offered Rides'), findsOneWidget);
      expect(find.text('Return to Home'), findsOneWidget);
      verifyNoEmojisInTree(tester);
    });
  });

  group('DriverActiveRideScreen Tests', () {
    testWidgets('Renders active navigation HUD and safety checklist', (tester) async {
      await tester.pumpWidget(
        wrapWithScope(child: DriverActiveRideScreen(initialRide: testRide)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Driver Navigation HUD'), findsOneWidget);
      expect(find.text('Complete Journey'), findsOneWidget);
      verifyNoEmojisInTree(tester);
    });
  });

  group('SafetyCenterScreen Tests', () {
    testWidgets('Renders emergency hotline, toolkit, and protocols', (tester) async {
      await tester.pumpWidget(wrapWithScope(child: const SafetyCenterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Safety Center'), findsOneWidget);
      expect(find.text('EMERGENCY ASSISTANCE'), findsOneWidget);
      expect(find.text('Emergency SOS'), findsOneWidget);
      verifyNoEmojisInTree(tester);
    });
  });

  group('HelpSupportScreen Tests', () {
    testWidgets('Renders contact channels and FAQ expandable tiles', (tester) async {
      await tester.pumpWidget(wrapWithScope(child: const HelpSupportScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('RECENT JOURNEY'), findsOneWidget);
      expect(find.text('Knowledge Hub'), findsOneWidget);
      verifyNoEmojisInTree(tester);
    });
  });

  group('SystemStatesScreen Tests', () {
    testWidgets('Renders interactive state tabs and empty/error/loading views', (
      tester,
    ) async {
      await tester.pumpWidget(wrapWithScope(child: const SystemStatesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('System & Edge States'), findsOneWidget);
      expect(find.text('Empty Results'), findsOneWidget);
      expect(find.text('No Internet / Offline'), findsOneWidget);
      expect(find.text('Driver Cancelled'), findsOneWidget);
      verifyNoEmojisInTree(tester);
    });
  });

  group('Responsive Layout Testing for All 10 Screens', () {
    final viewports = [
      const Size(320.0, 568.0),
      const Size(360.0, 640.0),
      const Size(390.0, 844.0),
      const Size(412.0, 915.0),
      const Size(600.0, 1024.0),
    ];

    final screens = <String, Widget>{
      'AuthSuccessScreen': const AuthSuccessScreen(),
      'PersonalDetailsScreen': const PersonalDetailsScreen(),
      'FilterRidesScreen': const FilterRidesScreen(),
      'BookingRequestScreen': BookingRequestScreen(initialBooking: testBooking),
      'CancelBookingScreen': CancelBookingScreen(initialBooking: testBooking),
      'RidePublishedScreen': RidePublishedScreen(publishedRide: testRide),
      'DriverActiveRideScreen': DriverActiveRideScreen(initialRide: testRide),
      'SafetyCenterScreen': const SafetyCenterScreen(),
      'HelpSupportScreen': const HelpSupportScreen(),
      'SystemStatesScreen': const SystemStatesScreen(),
    };

    for (final entry in screens.entries) {
      for (final size in viewports) {
        testWidgets(
          '${entry.key} renders without overflow at ${size.width}x${size.height}',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);

            await tester.pumpWidget(wrapWithScope(child: entry.value));
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);
          },
        );
      }

      testWidgets(
        '${entry.key} renders without overflow under 1.5x font scale',
        (tester) async {
          tester.view.physicalSize = const Size(390.0, 844.0);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            wrapWithScope(child: entry.value, textScaleFactor: 1.5),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}

class FakeTestAuthNotifier extends AuthNotifier {
  FakeTestAuthNotifier({required UserModel user})
    : super(
        repository: _FakeTestAuthRepo(user),
        storageService: _FakeTestSecureStorage(),
        apiClient: ApiClient(),
      ) {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
      token: 'valid_jwt_test_token',
    );
  }
}

class _FakeTestSecureStorage extends Fake implements SecureStorageService {
  @override
  Future<String?> getToken() async => 'valid_jwt_test_token';
  @override
  Future<void> saveToken(String token) async {}
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

class _FakeTestAuthRepo implements AuthRepository {
  final UserModel user;
  _FakeTestAuthRepo(this.user);

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
  Future<UserModel> getProfile() async => user;
}
