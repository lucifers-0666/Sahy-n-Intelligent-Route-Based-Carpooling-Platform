import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/features/profile/presentation/screens/profile_screen.dart';
import 'package:sahyan/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:sahyan/features/profile/presentation/screens/emergency_contacts_screen.dart';
import 'package:sahyan/features/profile/presentation/profile_provider.dart';
import 'package:sahyan/features/profile/data/profile_repository.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/auth/data/auth_repository.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/shared/models/user_model.dart';
import 'package:sahyan/core/widgets/app_text_field.dart';

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
          id: 'u123',
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
  UserModel user = const UserModel(
    id: 'u123',
    name: 'Arjun Patel',
    phone: '+919876543210',
    email: 'arjun@example.com',
    city: 'Ahmedabad',
    bio: 'Commuter between Ahmedabad and Gandhinagar',
    verificationStatus: UserVerificationStatus.verified,
    rating: 4.9,
    totalRides: 14,
    preferences: UserPreferences(
      notifications: true,
      allowSmoking: false,
      allowPets: false,
    ),
    emergencyContacts: [
      EmergencyContact(
        id: 'ec_1',
        name: 'Meera Patel',
        phone: '+919825012345',
        relationship: 'Sister',
      ),
    ],
  );

  @override
  Future<UserModel> getProfile() async => user;

  @override
  Future<UserModel> updateProfile({
    required String name,
    required String city,
    String? profilePhoto,
    String? bio,
  }) async {
    user = user.copyWith(
      name: name,
      city: city,
      profilePhoto: profilePhoto,
      bio: bio,
    );
    return user;
  }

  @override
  Future<UserPreferences> updatePreferences({
    required bool notifications,
    required bool allowSmoking,
    required bool allowPets,
  }) async {
    final prefs = UserPreferences(
      notifications: notifications,
      allowSmoking: allowSmoking,
      allowPets: allowPets,
    );
    user = user.copyWith(preferences: prefs);
    return prefs;
  }

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() async =>
      user.emergencyContacts;

  @override
  Future<EmergencyContact> addEmergencyContact({
    required String name,
    required String phone,
    String? relationship,
  }) async {
    final contact = EmergencyContact(
      id: 'ec_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      relationship: relationship ?? 'Family',
    );
    user = user.copyWith(
      emergencyContacts: [...user.emergencyContacts, contact],
    );
    return contact;
  }

  @override
  Future<EmergencyContact> updateEmergencyContact({
    required String id,
    required String name,
    required String phone,
    String? relationship,
  }) async {
    final updated = EmergencyContact(
      id: id,
      name: name,
      phone: phone,
      relationship: relationship ?? 'Family',
    );
    user = user.copyWith(
      emergencyContacts: user.emergencyContacts
          .map((c) => c.id == id ? updated : c)
          .toList(),
    );
    return updated;
  }

  @override
  Future<void> deleteEmergencyContact(String id) async {
    user = user.copyWith(
      emergencyContacts: user.emergencyContacts
          .where((c) => c.id != id)
          .toList(),
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

Widget createTestApp({
  required Widget child,
  required MockProfileRepository profileRepo,
  double textScaleFactor = 1.0,
}) {
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(profileRepo),
      secureStorageServiceProvider.overrideWithValue(
        MockSecureStorageService(),
      ),
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
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
        child: child,
      ),
    ),
  );
}

void main() {
  group('ProfileScreen Rendering & Functionality', () {
    late MockProfileRepository mockRepo;

    setUp(() {
      mockRepo = MockProfileRepository();
    });

    testWidgets(
      'Renders ProfileScreen with user details and verification status',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(child: const ProfileScreen(), profileRepo: mockRepo),
        );
        await tester.pumpAndSettle();

        expect(find.text('Account Profile'), findsOneWidget);
        expect(find.text('Arjun Patel'), findsOneWidget);
        expect(find.text('+919876543210'), findsWidgets);
        expect(find.text('arjun@example.com'), findsWidgets);
        expect(find.text('Phone Verified'), findsOneWidget);
        expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);
        expect(find.text('Trust & Safety Status'), findsOneWidget);
        expect(find.text('Edit Profile & Preferences'), findsOneWidget);
        expect(find.text('Safety Center & SOS Contacts'), findsOneWidget);
        expect(find.text('Log Out'), findsOneWidget);
      },
    );

    testWidgets('Verification badge hidden when user is unverified', (
      tester,
    ) async {
      mockRepo.user = mockRepo.user.copyWith(
        verificationStatus: UserVerificationStatus.pending,
      );
      await tester.pumpWidget(
        createTestApp(child: const ProfileScreen(), profileRepo: mockRepo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phone Verified'), findsNothing);
      expect(find.byIcon(Icons.verified_user_rounded), findsNothing);
      expect(find.text('Pending'), findsWidgets);
    });

    testWidgets('Renders loading state when auth is loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(mockRepo),
            secureStorageServiceProvider.overrideWithValue(
              MockSecureStorageService(),
            ),
            authRepositoryProvider.overrideWithValue(
              MockAuthRepository(() => mockRepo.user),
            ),
            apiClientProvider.overrideWithValue(ApiClient()),
            authProvider.overrideWith((ref) {
              return TestAuthNotifier(
                const AuthState(status: AuthStatus.loading),
              );
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Account Profile'), findsOneWidget);
    });

    testWidgets('Renders error and retry state when user is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(mockRepo),
            secureStorageServiceProvider.overrideWithValue(
              MockSecureStorageService(),
            ),
            authRepositoryProvider.overrideWithValue(
              MockAuthRepository(() => mockRepo.user),
            ),
            apiClientProvider.overrideWithValue(ApiClient()),
            authProvider.overrideWith((ref) {
              return TestAuthNotifier(
                const AuthState(status: AuthStatus.unauthenticated, user: null),
              );
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Profile'), findsOneWidget);
      expect(find.text('Retry Loading'), findsOneWidget);
    });

    testWidgets('Help & Support dialog opens and closes cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(child: const ProfileScreen(), profileRepo: mockRepo),
      );
      await tester.pumpAndSettle();

      final helpTile = find.text('Help & Support');
      await tester.ensureVisible(helpTile);
      await tester.tap(helpTile);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'For assistance during your journey, use the Emergency Contacts section to notify your trusted safety circle. Additional customer support channels and route assistance guides will be available in upcoming releases.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'For assistance during your journey, use the Emergency Contacts section to notify your trusted safety circle. Additional customer support channels and route assistance guides will be available in upcoming releases.',
        ),
        findsNothing,
      );
    });
  });

  group('EditProfileScreen Form & Preferences Validation', () {
    late MockProfileRepository mockRepo;

    setUp(() {
      mockRepo = MockProfileRepository();
    });

    testWidgets('Renders fields prefilled and validates empty name/city', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(child: const EditProfileScreen(), profileRepo: mockRepo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Personal Details'), findsOneWidget);
      expect(find.text('Ride Preferences'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Clear name and test validation
      final nameField = find.widgetWithText(AppTextField, 'Full Name');
      expect(nameField, findsOneWidget);

      final nameTextField = find.descendant(
        of: nameField,
        matching: find.byType(TextFormField),
      );
      await tester.enterText(nameTextField, '');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your full name'), findsOneWidget);
    });

    testWidgets('Toggling preferences and saving updates user state', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(child: const EditProfileScreen(), profileRepo: mockRepo),
      );
      await tester.pumpAndSettle();

      // Toggle smoking preference switch
      final smokingSwitch = find.byType(Switch).at(1);
      await tester.ensureVisible(smokingSwitch);
      await tester.tap(smokingSwitch);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(mockRepo.user.preferences.allowSmoking, true);
    });
  });

  group('EmergencyContactsScreen CRUD & Interactions', () {
    late MockProfileRepository mockRepo;

    setUp(() {
      mockRepo = MockProfileRepository();
    });

    testWidgets(
      'Renders existing emergency contacts with phone and relationship',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const EmergencyContactsScreen(),
            profileRepo: mockRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Emergency Contacts'), findsOneWidget);
        expect(find.text('Trusted Safety Circle'), findsOneWidget);
        expect(find.text('Meera Patel'), findsOneWidget);
        expect(find.text('Sister'), findsOneWidget);
        expect(find.text('+919825012345'), findsOneWidget);
      },
    );

    testWidgets(
      'Add emergency contact bottom sheet opens and validates Indian phone',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const EmergencyContactsScreen(),
            profileRepo: mockRepo,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add Contact'));
        await tester.pumpAndSettle();

        expect(find.text('Add Emergency Contact'), findsOneWidget);

        // Enter invalid phone
        final phoneField = find.widgetWithText(AppTextField, 'Phone Number');
        final phoneTextFormField = find.descendant(
          of: phoneField,
          matching: find.byType(TextFormField),
        );
        await tester.enterText(phoneTextFormField, '12345');

        await tester.tap(find.text('Save Contact'));
        await tester.pumpAndSettle();

        expect(
          find.text('Enter a valid 10-digit Indian mobile number'),
          findsOneWidget,
        );
      },
    );
  });

  group('Responsive Layout Testing Across Viewports & 1.5x Text Scaling', () {
    final viewports = [
      const Size(320, 568), // 320dp Compact (e.g. SE / 4-inch)
      const Size(360, 640), // 360dp Small
      const Size(390, 844), // 390dp Standard
      const Size(412, 915), // 412dp Large
      const Size(600, 1024), // 600dp Tablet
    ];

    for (final size in viewports) {
      testWidgets(
        'ProfileScreen renders without overflow at ${size.width}x${size.height}',
        (tester) async {
          final mockRepo = MockProfileRepository();
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            createTestApp(child: const ProfileScreen(), profileRepo: mockRepo),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Account Profile'), findsOneWidget);
        },
      );

      testWidgets(
        'EditProfileScreen renders without overflow at ${size.width}x${size.height}',
        (tester) async {
          final mockRepo = MockProfileRepository();
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            createTestApp(
              child: const EditProfileScreen(),
              profileRepo: mockRepo,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Edit Profile'), findsOneWidget);
        },
      );

      testWidgets(
        'EmergencyContactsScreen renders without overflow at ${size.width}x${size.height}',
        (tester) async {
          final mockRepo = MockProfileRepository();
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            createTestApp(
              child: const EmergencyContactsScreen(),
              profileRepo: mockRepo,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Emergency Contacts'), findsOneWidget);
        },
      );
    }

    testWidgets(
      'ProfileScreen renders without overflow under 1.5x text scaling',
      (tester) async {
        final mockRepo = MockProfileRepository();
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestApp(
            child: const ProfileScreen(),
            profileRepo: mockRepo,
            textScaleFactor: 1.5,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Account Profile'), findsOneWidget);
      },
    );

    testWidgets(
      'EditProfileScreen renders without overflow under 1.5x text scaling',
      (tester) async {
        final mockRepo = MockProfileRepository();
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestApp(
            child: const EditProfileScreen(),
            profileRepo: mockRepo,
            textScaleFactor: 1.5,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Edit Profile'), findsOneWidget);
      },
    );
  });
}
