import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/features/auth/presentation/screens/auth_decision_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/login_screen.dart';
import 'package:sahyan/features/bookings/presentation/screens/bookings_hub_screen.dart';
import 'package:sahyan/features/home/presentation/widgets/hero_search_card.dart';
import 'package:sahyan/shared/widgets/bento/segmented_pill_bar.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/auth/data/auth_repository.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/shared/models/user_model.dart';

class _MockSecureStorageService implements SecureStorageService {
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

class _MockAuthRepository implements AuthRepository {
  @override
  Future<Map<String, dynamic>> login({required String identifier, required String password}) async => {};
  @override
  Future<Map<String, dynamic>> register({required String name, required String email, required String phone, required String password}) async => {};
  @override
  Future<Map<String, dynamic>> sendOtp(String phone) async => {};
  @override
  Future<Map<String, dynamic>> verifyOtp({required String phone, required String otp}) async => {};
  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async => {};
  @override
  Future<Map<String, dynamic>> resetPassword({required String token, required String newPassword}) async => {};
  @override
  Future<UserModel> getProfile() async => UserModel(
    id: 'usr_test',
    name: 'Test User',
    email: 'test@example.com',
    phone: '+919876543210',
    city: 'Ahmedabad',
    verificationStatus: UserVerificationStatus.verified,
    rating: 5.0,
    totalRides: 0,
  );
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier()
      : super(
          repository: _MockAuthRepository(),
          storageService: _MockSecureStorageService(),
          apiClient: ApiClient(),
        ) {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

void main() {
  group('Luxury Light Edition UI & Interaction Tests', () {
    testWidgets('AuthDecisionScreen renders luxury hero, trust capsule, and guest card', (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthDecisionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sahyān'), findsOneWidget);
      expect(find.text('Where Journeys Find Company'), findsOneWidget);
      expect(find.text("India's premier verified intercity highway carpooling network."), findsOneWidget);
      expect(find.text('Verified Profiles'), findsOneWidget);
      expect(find.text('Fair Cost Sharing'), findsOneWidget);
      expect(find.text('Direct Routes'), findsOneWidget);
      expect(find.text('Create an Account'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Explore as Guest'), findsOneWidget);
    });

    testWidgets('HeroSearchCard 180-degree quick swap and popular chips populate fields', (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final originCtrl = TextEditingController(text: 'SG Highway, Ahmedabad');
      final destCtrl = TextEditingController(text: 'Rajkot, Kalawad Road');
      int seats = 2;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return HeroSearchCard(
                  originController: originCtrl,
                  destinationController: destCtrl,
                  onSwap: () {
                    setState(() {
                      final temp = originCtrl.text;
                      originCtrl.text = destCtrl.text;
                      destCtrl.text = temp;
                    });
                  },
                  onSelectCorridor: (corridor) {
                    setState(() {
                      originCtrl.text = corridor['from'] as String;
                      destCtrl.text = corridor['to'] as String;
                    });
                  },
                  selectedDate: DateTime.now(),
                  selectedTime: const TimeOfDay(hour: 17, minute: 30),
                  onPickDateTime: () {},
                  selectedSeats: seats,
                  onSeatsChanged: (val) => setState(() => seats = val),
                  onSearch: () {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial texts
      expect(originCtrl.text, 'SG Highway, Ahmedabad');
      expect(destCtrl.text, 'Rajkot, Kalawad Road');

      // Tap swap button
      final swapButton = find.byIcon(Icons.swap_vert_rounded);
      expect(swapButton, findsOneWidget);
      await tester.tap(swapButton);
      await tester.pumpAndSettle();

      // Verify swapped
      expect(originCtrl.text, 'Rajkot, Kalawad Road');
      expect(destCtrl.text, 'SG Highway, Ahmedabad');

      // Tap popular corridor chip
      final chipFinder = find.text('Bhuj → Ahmd · ₹388');
      expect(chipFinder, findsOneWidget);
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      expect(originCtrl.text, 'Bhuj');
      expect(destCtrl.text, 'Ahmd');
    });

    testWidgets('BookingsHubScreen sliding pill bar and PageView synchronize smoothly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingsHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially on Active tab
      expect(find.text('Rohit Patel'), findsOneWidget);
      expect(find.text('4821'), findsOneWidget);
      expect(find.text('Track Live on Map'), findsOneWidget);

      // Tap 'Pending' tab in the sliding pill bar
      await tester.tap(find.text('Pending'));
      await tester.pumpAndSettle();

      // Verify switched to Pending view with Dr. Priya Sharma
      expect(find.text('Dr. Priya Sharma'), findsOneWidget);
      expect(find.text('Under Review'), findsOneWidget);

      // Tap 'History' tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Verify switched to Completed Journeys
      expect(find.text('Completed Journeys'), findsOneWidget);
      expect(find.text('Rajkot → Ahmedabad'), findsOneWidget);
    });

    testWidgets('LoginScreen sliding pill switcher and 2-step OTP flow work seamlessly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith((ref) => _TestAuthNotifier())],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify unclipped Sign In header and Password mode form
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Password'), findsWidgets);
      expect(find.text('Phone OTP'), findsOneWidget);
      expect(find.text('Mobile Number or Email'), findsOneWidget);

      // Tap 'Phone OTP' tab to trigger sliding pill switcher
      await tester.tap(find.text('Phone OTP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // State A: Mobile number field and "Get Verification Code" button
      expect(find.text('+91'), findsOneWidget);
      expect(find.text('Get Verification Code'), findsOneWidget);

      // Tap "Get Verification Code" to advance to State B
      await tester.tap(find.text('Get Verification Code'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // State B: Phone preview with "Edit", 4 discrete digit boxes, countdown timer, and Verify & Sign In button
      expect(find.text('Edit'), findsOneWidget);
      expect(find.textContaining('Resend code in'), findsOneWidget);
      expect(find.text('Verify & Sign In'), findsOneWidget);

      // Tap "Edit" to return to State A
      await tester.tap(find.text('Edit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Get Verification Code'), findsOneWidget);
    });

    testWidgets('Responsive Layout across multiple viewports without overflow', (tester) async {
      const viewports = [
        Size(320, 568),
        Size(360, 640),
        Size(393, 852),
        Size(412, 915),
      ];

      final testOverrides = [authProvider.overrideWith((ref) => _TestAuthNotifier())];

      for (final size in viewports) {
        await tester.binding.setSurfaceSize(size);

        await tester.pumpWidget(
          ProviderScope(
            overrides: testOverrides,
            child: const MaterialApp(
              home: AuthDecisionScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'AuthDecisionScreen overflow at $size');

        await tester.pumpWidget(
          ProviderScope(
            overrides: testOverrides,
            child: const MaterialApp(
              home: LoginScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: 'LoginScreen overflow at $size');

        await tester.pumpWidget(
          ProviderScope(
            overrides: testOverrides,
            child: const MaterialApp(
              home: BookingsHubScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'BookingsHubScreen overflow at $size');
      }
    });
  });
}
