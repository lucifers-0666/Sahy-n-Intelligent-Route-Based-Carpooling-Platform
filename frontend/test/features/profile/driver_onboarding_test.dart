import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/features/profile/presentation/screens/driver_onboarding_screen.dart';
import 'package:sahyan/features/profile/presentation/profile_provider.dart';
import 'package:sahyan/features/profile/data/profile_repository.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/auth/data/auth_repository.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/features/vehicles/presentation/vehicle_provider.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/shared/models/user_model.dart';

class MockSecureStorageService implements SecureStorageService {
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<String?> getToken() async => 'fake_token';
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

class MockAuthRepository implements AuthRepository {
  final UserModel Function()? userGetter;
  MockAuthRepository([this.userGetter]);

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
  Future<UserModel> getProfile() async => userGetter != null
      ? userGetter!()
      : const UserModel(
          id: 'u_onboard_1',
          name: 'Arjun Patel',
          phone: '+919876543210',
          email: 'arjun@example.com',
          city: 'Ahmedabad',
          verificationStatus: UserVerificationStatus.verified,
          rating: 4.9,
          totalRides: 14,
        );
}

class MockProfileRepository implements ProfileRepository {
  UserModel user;
  bool submitCalled = false;

  MockProfileRepository({required this.user});

  @override
  Future<UserModel> getProfile() async => user;

  @override
  Future<UserModel> updateProfile({
    required String name,
    required String city,
    String? profilePhoto,
    String? bio,
  }) async {
    user = user.copyWith(name: name, city: city, profilePhoto: profilePhoto, bio: bio);
    return user;
  }

  @override
  Future<UserPreferences> updatePreferences({
    required bool notifications,
    required bool allowSmoking,
    required bool allowPets,
  }) async => user.preferences;

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() async => user.emergencyContacts;

  @override
  Future<EmergencyContact> addEmergencyContact({
    required String name,
    required String phone,
    String? relationship,
  }) async => EmergencyContact(id: 'ec_1', name: name, phone: phone);

  @override
  Future<EmergencyContact> updateEmergencyContact({
    required String id,
    required String name,
    required String phone,
    String? relationship,
  }) async => EmergencyContact(id: id, name: name, phone: phone);

  @override
  Future<void> deleteEmergencyContact(String id) async {}

  @override
  Future<Map<String, dynamic>> submitDriverApplication({
    required String licenseNumber,
    String? licenseDocUrl,
    String? rcDocUrl,
    String? idDocUrl,
  }) async {
    submitCalled = true;
    user = user.copyWith(
      driverOnboardingStatus: 'submitted',
      licenseNumber: licenseNumber,
    );
    return {
      'status': 'submitted',
      'message': 'Driver application submitted successfully for review',
    };
  }

  @override
  Future<Map<String, dynamic>> getDriverStatus() async {
    return {
      'canDrive': user.canDrive,
      'onboardingStatus': user.driverOnboardingStatus,
      'licenseNumber': user.licenseNumber,
    };
  }

  @override
  Future<void> anonymizeAccount({
    String reason = 'User requested account erasure',
  }) async {
    user = const UserModel(
      id: 'anonymized',
      name: 'Sahyan Member',
      phone: '',
      email: '',
      city: '',
      verificationStatus: UserVerificationStatus.pending,
      rating: 5.0,
      totalRides: 0,
    );
  }
}

class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier(AuthState initialState)
      : super(
          repository: MockAuthRepository(),
          storageService: MockSecureStorageService(),
          apiClient: ApiClient(),
        ) {
    state = initialState;
  }

  @override
  Future<void> checkAuthStatus() async {}
}

class FakeVehiclesNotifier extends VehiclesNotifier {
  final List<VehicleModel> initialVehicles;
  FakeVehiclesNotifier(this.initialVehicles);

  @override
  Future<List<VehicleModel>> build() async => initialVehicles;
}

Widget createTestApp({
  required Widget child,
  required MockProfileRepository profileRepo,
  List<VehicleModel>? vehicles,
}) {
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(profileRepo),
      secureStorageServiceProvider.overrideWithValue(MockSecureStorageService()),
      authRepositoryProvider.overrideWithValue(
        MockAuthRepository(() => profileRepo.user),
      ),
      apiClientProvider.overrideWithValue(ApiClient()),
      authProvider.overrideWith((ref) {
        return TestAuthNotifier(
          AuthState(
            status: AuthStatus.authenticated,
            user: profileRepo.user,
            token: 'fake_token',
          ),
        );
      }),
      vehiclesProvider.overrideWith(() => FakeVehiclesNotifier(vehicles ?? [])),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}

void main() {
  group('DriverOnboardingScreen Step-by-Step Wizard Tests', () {
    testWidgets('Step 0: Identity confirmation renders member details and advances to Step 1', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockProfileRepository(
        user: const UserModel(
          id: 'u101',
          name: 'Pooja Shah',
          phone: '+919876543210',
          email: 'pooja@example.com',
          city: 'Ahmedabad',
          verificationStatus: UserVerificationStatus.verified,
          rating: 4.8,
          totalRides: 12,
          driverOnboardingStatus: 'not_started',
        ),
      );

      await tester.pumpWidget(createTestApp(
        child: const DriverOnboardingScreen(),
        profileRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      // Check header and step indicators
      expect(find.text('Driver Onboarding'), findsOneWidget);
      expect(find.text('Step 1: Identity & Contact Confirmation'), findsOneWidget);
      expect(find.text('Pooja Shah'), findsWidgets);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Advance to Step 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2: Driving Licence Verification'), findsOneWidget);
      expect(find.text('Driving Licence Number (Required)'), findsOneWidget);
    });

    testWidgets('Step 1: Licence details validates format before proceeding', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockProfileRepository(
        user: const UserModel(
          id: 'u101',
          name: 'Pooja Shah',
          phone: '+919876543210',
          email: 'pooja@example.com',
          city: 'Ahmedabad',
          verificationStatus: UserVerificationStatus.verified,
          rating: 4.8,
          totalRides: 12,
          driverOnboardingStatus: 'not_started',
        ),
      );

      await tester.pumpWidget(createTestApp(
        child: const DriverOnboardingScreen(),
        profileRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      // Advance from Step 0 to Step 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Try tapping Continue without entering licence number
      final continueButton = find.text('Continue');
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Form validation error appears
      expect(find.text('Driving licence number is required'), findsOneWidget);

      // Enter valid Indian DL format
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'GJ0120200012345');
      await tester.pumpAndSettle();

      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Successfully advances to Step 2
      expect(find.text('Step 3: Associate Registered Vehicle'), findsOneWidget);
    });

    testWidgets('Step 2: Vehicle association displays registered fleet and advances', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockProfileRepository(
        user: const UserModel(
          id: 'u101',
          name: 'Pooja Shah',
          phone: '+919876543210',
          email: 'pooja@example.com',
          city: 'Ahmedabad',
          verificationStatus: UserVerificationStatus.verified,
          rating: 4.8,
          totalRides: 12,
          driverOnboardingStatus: 'not_started',
        ),
      );

      final testVehicle = VehicleModel(
        id: 'v101',
        ownerId: 'u101',
        registrationNumber: 'GJ-01-AB-1234',
        vehicleType: 'sedan',
        make: 'Honda',
        model: 'City',
        color: 'Silver',
        year: 2022,
        seatCapacity: 4,
      );

      await tester.pumpWidget(createTestApp(
        child: const DriverOnboardingScreen(),
        profileRepo: mockRepo,
        vehicles: [testVehicle],
      ));
      await tester.pumpAndSettle();

      // Step 0 -> Step 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 1: fill DL -> Step 2
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'GJ0120200012345');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2 shows vehicle
      expect(find.text('Honda City'), findsOneWidget);
      expect(find.text('GJ-01-AB-1234 • 4 Seats'), findsOneWidget);

      // Advance to Step 3 (Review & Consent)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Step 4: Review Application & Safety Consent'), findsOneWidget);
    });

    testWidgets('Step 3: Review & consent requirements enable submission', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockProfileRepository(
        user: const UserModel(
          id: 'u101',
          name: 'Pooja Shah',
          phone: '+919876543210',
          email: 'pooja@example.com',
          city: 'Ahmedabad',
          verificationStatus: UserVerificationStatus.verified,
          rating: 4.8,
          totalRides: 12,
          driverOnboardingStatus: 'not_started',
        ),
      );

      await tester.pumpWidget(createTestApp(
        child: const DriverOnboardingScreen(),
        profileRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      // Step 0 -> Step 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 1: Enter DL -> Step 2
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'GJ0120200012345');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2 -> Step 3
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify review items
      expect(find.text('GJ0120200012345'), findsOneWidget);

      // Checkboxes exist for Motor Vehicles Act and cost sharing
      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes, findsNWidgets(2));

      // Toggle both consents
      await tester.tap(checkboxes.at(0));
      await tester.pumpAndSettle();
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      // Submit Application button is present and clickable
      final submitButton = find.text('Submit Application for Review');
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(mockRepo.submitCalled, isTrue);
    });
  });

  group('Driver Status Views Rendering', () {
    testWidgets('Submitted status renders Application Under Review view', (tester) async {
      final mockRepo = MockProfileRepository(
        user: const UserModel(
          id: 'u102',
          name: 'Karan Dave',
          phone: '+919876543211',
          email: 'karan@example.com',
          city: 'Surat',
          verificationStatus: UserVerificationStatus.verified,
          rating: 4.7,
          totalRides: 8,
          driverOnboardingStatus: 'submitted',
          licenseNumber: 'GJ0520190098765',
        ),
      );

      await tester.pumpWidget(createTestApp(
        child: const DriverOnboardingScreen(),
        profileRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Application Under Review'), findsOneWidget);
      expect(find.textContaining('24 to 48 hours'), findsOneWidget);
      expect(find.text('GJ0520190098765'), findsOneWidget);
      expect(find.text('Back to Account Profile'), findsOneWidget);
    });

    testWidgets('Approved status renders Approved Sahyān Driver view', (tester) async {
      final mockRepo = MockProfileRepository(
        user: const UserModel(
          id: 'u103',
          name: 'Vikram Joshi',
          phone: '+919876543212',
          email: 'vikram@example.com',
          city: 'Vadodara',
          verificationStatus: UserVerificationStatus.verified,
          rating: 4.95,
          totalRides: 42,
          canDrive: true,
          driverOnboardingStatus: 'approved',
          licenseNumber: 'GJ0620180054321',
        ),
      );

      await tester.pumpWidget(createTestApp(
        child: const DriverOnboardingScreen(),
        profileRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Approved Sahyān Driver'), findsOneWidget);
      expect(find.text('Offer a Ride'), findsOneWidget);
      expect(find.text('Manage Fleet & Vehicles'), findsOneWidget);
      expect(find.text('GJ0620180054321'), findsOneWidget);
    });

    testWidgets('Rejected status renders Action Required view with reason', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockProfileRepository(
        user: const UserModel(
          id: 'u104',
          name: 'Nisha Mehta',
          phone: '+919876543213',
          email: 'nisha@example.com',
          city: 'Rajkot',
          verificationStatus: UserVerificationStatus.verified,
          rating: 4.6,
          totalRides: 5,
          driverOnboardingStatus: 'rejected',
          licenseNumber: 'GJ0320210011223',
          rejectionReason: 'Licence photo was blurry. Please re-enter number or re-upload.',
        ),
      );

      await tester.pumpWidget(createTestApp(
        child: const DriverOnboardingScreen(),
        profileRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Action Required on Application'), findsOneWidget);
      expect(find.text('Licence photo was blurry. Please re-enter number or re-upload.'), findsOneWidget);
      expect(find.text('Re-Submit Driver Details'), findsOneWidget);

      // Tapping Re-Submit Driver Details reopens the wizard form at Step 1
      await tester.tap(find.text('Re-Submit Driver Details'));
      await tester.pumpAndSettle();

      expect(find.text('Driver Onboarding'), findsOneWidget);
      expect(find.text('Step 2: Driving Licence Verification'), findsOneWidget);
    });
  });
}
