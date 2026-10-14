import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/core/localization/sahyan_localizations.dart';
import 'package:sahyan/features/auth/presentation/screens/login_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/register_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/otp_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/welcome_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:sahyan/features/auth/presentation/widgets/sahyan_highway_hero.dart';
import 'package:sahyan/shared/widgets/sahyan_route_convergence_logo.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/auth/data/auth_repository.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/shared/models/user_model.dart';
import 'package:sahyan/core/widgets/app_text_field.dart';
import 'package:sahyan/l10n/generated/app_localizations.dart';

class MockSecureStorageService implements SecureStorageService {
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

class MockAuthRepository implements AuthRepository {
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
  Future<UserModel> getProfile() async => UserModel(
    id: 'usr_1',
    name: 'Test',
    email: 'test@example.com',
    phone: '+919876543210',
    city: 'Ahmedabad',
    verificationStatus: UserVerificationStatus.verified,
    rating: 5.0,
    totalRides: 0,
  );
}

class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier()
    : super(
        repository: MockAuthRepository(),
        storageService: MockSecureStorageService(),
        apiClient: ApiClient(),
      ) {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

Widget createTestApp(
  Widget child, {
  double width = 390,
  double height = 844,
  double textScaleFactor = 1.0,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) {
  return ProviderScope(
    overrides: [authProvider.overrideWith((ref) => TestAuthNotifier())],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        SahyanLocalizations.delegate,
      ],
      supportedLocales: SahyanLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: TextScaler.linear(textScaleFactor),
          viewInsets: viewInsets,
        ),
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testWidths = [320.0, 360.0, 390.0, 412.0, 600.0];

  group('Responsive LoginScreen UI Tests', () {
    for (final width in testWidths) {
      testWidgets(
        'LoginScreen renders without overflow on width ${width.toInt()}dp',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            createTestApp(const LoginScreen(), width: width),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          expect(find.text("What's your number?"), findsOneWidget);
          expect(find.text('+91'), findsOneWidget);
          expect(find.text('Sign in with password instead'), findsOneWidget);

          // Switch to password mode
          await tester.tap(find.text('Sign in with password instead'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));

          expect(find.text('Welcome back'), findsOneWidget);
          expect(find.text('Forgot password?'), findsOneWidget);

          // Switch back to OTP mode
          await tester.tap(find.text('Sign in with phone OTP instead'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));

          expect(find.text("What's your number?"), findsOneWidget);
        },
      );
    }

    testWidgets(
      'LoginScreen with 1.5x accessibility text scale renders cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(const LoginScreen(), width: 390, textScaleFactor: 1.5),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text("What's your number?"), findsOneWidget);
        expect(find.text('+91'), findsOneWidget);
      },
    );

    testWidgets(
      'LoginScreen with keyboard visible maintains access without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(
            const LoginScreen(),
            width: 390,
            viewInsets: const EdgeInsets.only(bottom: 300),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text("What's your number?"), findsOneWidget);
      },
    );

    testWidgets('AppTextField password visibility toggle functions correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          const Scaffold(
            body: AppTextField(hint: 'Enter password', isPassword: true),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final toggleFinder = find.byType(IconButton);
      expect(toggleFinder, findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      await tester.tap(toggleFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('valid phone entry does not add a green status dot', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.pump();

      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });
  });

  group('Responsive RegisterScreen UI Tests', () {
    for (final width in testWidths) {
      testWidgets(
        'RegisterScreen renders without overflow on width ${width.toInt()}dp',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            createTestApp(const RegisterScreen(), width: width),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          expect(find.text('Create your account'), findsOneWidget);
          expect(find.text('Full name'), findsOneWidget);
          expect(find.text('+91'), findsOneWidget);
          expect(find.text('Continue'), findsOneWidget);
        },
      );
    }

    testWidgets(
      'RegisterScreen with 1.5x accessibility text scale renders cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(
            const RegisterScreen(),
            width: 390,
            textScaleFactor: 1.5,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Create your account'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
      },
    );

    testWidgets('RegisterScreen step progression works from Step 1 to Step 2', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(const RegisterScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter name
      final nameFinder = find.byType(TextFormField).first;
      await tester.enterText(nameFinder, 'Zaid Patel');
      await tester.pump();

      // Enter phone
      final phoneFinder = find.widgetWithText(TextField, '98765 43210');
      await tester.enterText(phoneFinder, '9876543210');
      await tester.pump();

      // Tick consent checkbox
      final checkboxFinder = find.byType(Checkbox);
      await tester.tap(checkboxFinder);
      await tester.pump();

      // Scroll to and tap Continue
      await tester.ensureVisible(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifies Step 2 is shown
      expect(find.text('Preferences & Role'), findsOneWidget);
      expect(find.text('Complete Registration'), findsOneWidget);
    });
  });

  group('Responsive OtpScreen UI Tests', () {
    for (final width in testWidths) {
      testWidgets(
        'OtpScreen renders 6 digits without overflow on width ${width.toInt()}dp',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            createTestApp(const OtpScreen(), width: width),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          expect(find.text('Verify your phone'), findsOneWidget);
          expect(find.text('Verify & Proceed'), findsOneWidget);
          expect(find.textContaining('Resend'), findsOneWidget);
        },
      );
    }

    testWidgets('OTP accepts a multi-digit paste in one accessible field', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(const OtpScreen(), width: 320));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), '12345');
      await tester.pump();

      for (final digit in ['1', '2', '3', '4', '5']) {
        expect(find.text(digit), findsOneWidget);
      }

      await tester.tap(find.text('Verify & Proceed'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Enter all 6 digits to verify.'), findsOneWidget);
    });

    testWidgets(
      'OtpScreen with 1.5x accessibility text scale renders cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(const OtpScreen(), width: 390, textScaleFactor: 1.5),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Verify your phone'), findsOneWidget);
        expect(find.text('Verify & Proceed'), findsOneWidget);
      },
    );

    testWidgets('OtpScreen with keyboard visible maintains reachability', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestApp(
          const OtpScreen(),
          width: 390,
          viewInsets: const EdgeInsets.only(bottom: 300),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Verify your phone'), findsOneWidget);
      expect(find.text('Verify & Proceed'), findsOneWidget);
    });
  });

  group('Responsive Forgot and Reset Password UI Tests', () {
    for (final width in [320.0, 390.0, 600.0]) {
      testWidgets(
        'ForgotPasswordScreen and ResetPasswordScreen on width ${width.toInt()}dp',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            createTestApp(const ForgotPasswordScreen(), width: width),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.text('Forgot Password?'), findsOneWidget);

          await tester.pumpWidget(
            createTestApp(
              const ResetPasswordScreen(initialToken: 'test-token'),
              width: width,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.text('Reset Password'), findsOneWidget);
        },
      );
    }
  });

  group('Responsive WelcomeScreen & Hero UI Tests', () {
    const testWidths = [320.0, 360.0, 390.0, 412.0, 600.0];

    for (final width in testWidths) {
      testWidgets(
        'WelcomeScreen renders without overflow on width ${width.toInt()}dp',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            createTestApp(const WelcomeScreen(), width: width),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          expect(
            find.text('Share the journey,\nnot just the ride.'),
            findsOneWidget,
          );
          expect(find.text('Continue with phone'), findsOneWidget);
          expect(find.text('Use email or password instead'), findsOneWidget);
          expect(find.text('Explore as guest · Browse rides'), findsOneWidget);
        },
      );
    }

    testWidgets(
      'SahyanHighwaySunriseHero renders in light and dark mode without error',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            const Column(
              children: [
                SahyanHighwaySunriseHero(height: 300, isDark: false),
                SahyanHighwaySunriseHero(height: 300, isDark: true),
              ],
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(SahyanHighwaySunriseHero), findsNWidgets(2));
      },
    );
  });

  testWidgets('Splash lockup shows its wordmark and tagline on first frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestApp(
        const Scaffold(body: Center(child: SahyanAnimatedRouteLogo())),
      ),
    );
    await tester.pump();

    expect(find.text('Where journeys find company'), findsOneWidget);
    for (final letter in ['S', 'a', 'h', 'y', 'ā', 'n']) {
      expect(find.text(letter), findsOneWidget);
    }
  });
}
