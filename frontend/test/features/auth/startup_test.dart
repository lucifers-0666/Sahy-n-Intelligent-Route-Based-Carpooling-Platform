import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/providers/app_startup_provider.dart';
import 'package:sahyan/app/providers/user_mode_provider.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/auth/data/auth_repository.dart';
import 'package:sahyan/shared/models/user_model.dart';

class MockTestSecureStorage implements SecureStorageService {
  String? _token;
  UserModel? _user;
  bool _onboardingCompleted = false;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> deleteToken() async => _token = null;

  @override
  Future<void> saveUser(UserModel user) async => _user = user;

  @override
  Future<UserModel?> getUser() async => _user;

  @override
  Future<void> deleteUser() async => _user = null;

  @override
  Future<void> clearSession() async {
    _token = null;
    _user = null;
  }

  @override
  Future<void> setCompletedOnboarding(bool completed) async =>
      _onboardingCompleted = completed;

  @override
  Future<bool> hasCompletedOnboarding() async => _onboardingCompleted;
}

class MockTestAuthRepository implements AuthRepository {
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
  Future<UserModel> getProfile() async {
    return const UserModel(
      id: 'usr_valid_1',
      name: 'Sahyān Traveler',
      phone: '+919876543210',
      email: 'traveler@sahyan.app',
      city: 'Ahmedabad',
      verificationStatus: UserVerificationStatus.verified,
      rating: 4.9,
      totalRides: 5,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTestSecureStorage storage;
  late MockTestAuthRepository repo;
  late ApiClient apiClient;
  late AuthNotifier authNotifier;

  setUp(() {
    storage = MockTestSecureStorage();
    repo = MockTestAuthRepository();
    apiClient = ApiClient();
    authNotifier = AuthNotifier(
      repository: repo,
      storageService: storage,
      apiClient: apiClient,
    );
  });

  group('AppStartupNotifier Tests', () {
    test(
      'Fresh install with no token transitions to onboardingRequired',
      () async {
        final startup = AppStartupNotifier(
          storageService: storage,
          authNotifier: authNotifier,
        );

        await Future.delayed(Duration.zero);
        expect(startup.state.status, AppStartupStatus.onboardingRequired);
      },
    );

    test(
      'Onboarding completion updates storage and transitions to authEntryRequired',
      () async {
        final startup = AppStartupNotifier(
          storageService: storage,
          authNotifier: authNotifier,
        );

        await startup.completeOnboarding();
        expect(await storage.hasCompletedOnboarding(), isTrue);
        expect(startup.state.status, AppStartupStatus.authEntryRequired);
      },
    );

    test(
      'Existing user who completed onboarding transitions to authEntryRequired when unauthenticated',
      () async {
        await storage.setCompletedOnboarding(true);

        final startup = AppStartupNotifier(
          storageService: storage,
          authNotifier: authNotifier,
        );

        await Future.delayed(Duration.zero);
        expect(startup.state.status, AppStartupStatus.authEntryRequired);
      },
    );

    test(
      'Authenticated user with valid session transitions directly to ready',
      () async {
        await storage.setCompletedOnboarding(true);
        await storage.saveToken('valid_jwt_token');

        final startup = AppStartupNotifier(
          storageService: storage,
          authNotifier: authNotifier,
        );

        await Future.delayed(const Duration(milliseconds: 50));
        expect(startup.state.status, AppStartupStatus.ready);
      },
    );
  });

  group('UserModeNotifier Tests', () {
    test('Default mode is authenticated and rider', () {
      final modeNotifier = UserModeNotifier();
      expect(modeNotifier.state.accessMode, AccessMode.authenticated);
      expect(modeNotifier.state.operationalMode, OperationalMode.rider);
      expect(modeNotifier.state.isGuest, isFalse);
    });

    test('setGuestMode transitions to guest access', () {
      final modeNotifier = UserModeNotifier();
      modeNotifier.setGuestMode();
      expect(modeNotifier.state.isGuest, isTrue);
      expect(modeNotifier.state.accessMode, AccessMode.guest);
    });

    test('Operational mode switching between rider and driver', () {
      final modeNotifier = UserModeNotifier();
      modeNotifier.setOperationalMode(OperationalMode.driver);
      expect(modeNotifier.state.isDriverMode, isTrue);
      expect(modeNotifier.state.isRiderMode, isFalse);

      modeNotifier.setOperationalMode(OperationalMode.rider);
      expect(modeNotifier.state.isRiderMode, isTrue);
    });

    test('Protected intent preservation for guest actions', () {
      final modeNotifier = UserModeNotifier();
      modeNotifier.setPendingProtectedIntent('/seat-selection');
      expect(modeNotifier.state.pendingProtectedIntent, '/seat-selection');

      modeNotifier.clearPendingIntent();
      expect(modeNotifier.state.pendingProtectedIntent, isNull);
    });

    test('clearGuestMode clears guest access and pending intent', () {
      final modeNotifier = UserModeNotifier();
      modeNotifier.setGuestMode();
      modeNotifier.setPendingProtectedIntent('/offer-ride');
      expect(modeNotifier.state.isGuest, isTrue);

      modeNotifier.clearGuestMode();
      expect(modeNotifier.state.isGuest, isFalse);
      expect(modeNotifier.state.accessMode, AccessMode.authenticated);
      expect(modeNotifier.state.pendingProtectedIntent, isNull);
    });

    test('resetOnLogout clears guest mode and restores defaults', () {
      final modeNotifier = UserModeNotifier();
      modeNotifier.setGuestMode();
      modeNotifier.setOperationalMode(OperationalMode.driver);
      modeNotifier.setPendingProtectedIntent('/profile');

      modeNotifier.resetOnLogout();
      expect(modeNotifier.state.isGuest, isFalse);
      expect(modeNotifier.state.accessMode, AccessMode.authenticated);
      expect(modeNotifier.state.operationalMode, OperationalMode.rider);
      expect(modeNotifier.state.pendingProtectedIntent, isNull);
    });

    test(
      'userModeProvider automatically clears guest mode on authProvider authentication',
      () {
        final container = ProviderContainer(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(repo),
          ],
        );
        addTearDown(container.dispose);

        // Set guest mode initially
        container.read(userModeProvider.notifier).setGuestMode();
        container
            .read(userModeProvider.notifier)
            .setPendingProtectedIntent('/offer-ride');
        expect(container.read(userModeProvider).isGuest, isTrue);

        // Authenticate authProvider
        container.read(authProvider.notifier).state = const AuthState(
          status: AuthStatus.authenticated,
          user: UserModel(
            id: 'usr_auth_1',
            name: 'Zaid Amreliya',
            phone: '+919876543210',
            email: 'zaid@example.com',
            city: 'Ahmedabad',
            verificationStatus: UserVerificationStatus.verified,
            rating: 5.0,
            totalRides: 12,
          ),
        );

        // userModeProvider should reactively clear guest mode
        expect(container.read(userModeProvider).isGuest, isFalse);
        expect(
          container.read(userModeProvider).accessMode,
          AccessMode.authenticated,
        );
        expect(container.read(userModeProvider).pendingProtectedIntent, isNull);
      },
    );
  });

  group('UserModel Unified Capabilities Tests', () {
    test(
      'Default user has passenger capability and inactive driver capability',
      () {
        const user = UserModel(
          id: 'usr_test_1',
          name: 'Arjun Patel',
          phone: '+919876543210',
          email: 'arjun@example.com',
          city: 'Ahmedabad',
          verificationStatus: UserVerificationStatus.verified,
          rating: 4.9,
          totalRides: 8,
        );

        expect(user.canRide, isTrue);
        expect(user.canDrive, isFalse);
        expect(user.driverOnboardingStatus, 'not_started');
        expect(user.isDriverEligible, isFalse);
      },
    );

    test(
      'User becomes driver eligible only when canDrive is true and driverOnboardingStatus is approved',
      () {
        const driverUser = UserModel(
          id: 'usr_driver_1',
          name: 'Priya Shah',
          phone: '+919876543211',
          email: 'priya@example.com',
          city: 'Vadodara',
          verificationStatus: UserVerificationStatus.verified,
          rating: 5.0,
          totalRides: 20,
          canDrive: true,
          driverOnboardingStatus: 'approved',
        );

        expect(driverUser.isDriverEligible, isTrue);
      },
    );
  });
}
