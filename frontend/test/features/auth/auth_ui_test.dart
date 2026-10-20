import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/core/localization/sahyan_localizations.dart';
import 'package:sahyan/features/auth/presentation/screens/login_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/register_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/otp_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/welcome_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/onboarding_screen.dart';
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

    testWidgets('valid phone entry shows valid tick as suffix', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.pump();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });

  group('Responsive RegisterScreen UI Tests', () {
    Future<void> advanceRegisterToStep2(WidgetTester tester) async {
      // Full Name
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g., Zaid Patel'),
        'Zaid Patel',
      );
      await tester.pump();
      // Phone
      await tester.enterText(
        find.widgetWithText(TextField, '98765 43210'),
        '9876543210',
      );
      await tester.pump();
      // Email
      await tester.enterText(
        find.widgetWithText(TextField, 'name@example.com'),
        'zaid@example.com',
      );
      await tester.pump();
      // Password (satisfies 8+ chars, upper, lower, number, special char)
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter secure password'),
        'Sahyan@2026',
      );
      await tester.pump();
      // Confirm Password
      await tester.enterText(
        find.widgetWithText(TextField, 'Re-enter your password'),
        'Sahyan@2026',
      );
      await tester.pump();
      // Terms Checkbox
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      // Continue
      await tester.ensureVisible(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

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
          expect(find.text('Full Name *'), findsOneWidget);
          expect(find.text('+91'), findsOneWidget);
          expect(find.text('Email Address *'), findsOneWidget);
          expect(find.text('Password *'), findsOneWidget);
          expect(find.text('Confirm Password *'), findsOneWidget);
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

    testWidgets(
      'RegisterScreen password and confirm-password validation flags mismatch',
      (tester) async {
        await tester.pumpWidget(createTestApp(const RegisterScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Enter password
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter secure password'),
          'Sahyan@2026',
        );
        await tester.pump();

        // Enter mismatched confirm password
        await tester.enterText(
          find.widgetWithText(TextField, 'Re-enter your password'),
          'Different@123',
        );
        await tester.pump();

        // Tap continue to trigger validation
        await tester.ensureVisible(find.text('Continue'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        expect(find.text('Passwords do not match.'), findsOneWidget);
      },
    );

    testWidgets('RegisterScreen step progression works from Step 1 to Step 2', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(const RegisterScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await advanceRegisterToStep2(tester);

      // Verifies Step 2 is shown
      expect(find.text('Preferences & Role'), findsWidgets);
      expect(find.text('How will you travel with Sahyān?'), findsOneWidget);
      expect(find.text('Passenger'), findsOneWidget);
      expect(find.text('Driver'), findsOneWidget);
      expect(find.text('Both'), findsOneWidget);
      expect(find.text('Complete Registration'), findsOneWidget);
    });

    testWidgets(
      'RegisterScreen passenger role selection keeps driver fields hidden and displays readiness card',
      (tester) async {
        await tester.pumpWidget(createTestApp(const RegisterScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await advanceRegisterToStep2(tester);

        // Select Passenger Role
        await tester.tap(find.text('Passenger'));
        await tester.pumpAndSettle();

        // Verifies Passenger Readiness Card
        expect(find.text('Ready to ride as a passenger'), findsOneWidget);
        // Driver fields must be completely hidden
        expect(find.text('Manual Admin Verification Required'), findsNothing);
        expect(find.text('Driving License (DL) Number *'), findsNothing);
        expect(find.text('Car Registration / Number Plate *'), findsNothing);
      },
    );

    testWidgets(
      'RegisterScreen driver role selection reveals admin manual verification, driver details, and photo toggle',
      (tester) async {
        await tester.pumpWidget(createTestApp(const RegisterScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await advanceRegisterToStep2(tester);

        // Select Driver Role
        await tester.ensureVisible(find.text('Driver'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Driver'));
        await tester.pumpAndSettle();

        // Verifies Admin Verification Banner
        expect(find.text('Manual Admin Verification Required'), findsOneWidget);
        expect(
          find.text(
            'Driver profiles and vehicle details undergo manual review by the Sahyān safety admin panel before publishing rides is enabled.',
          ),
          findsOneWidget,
        );

        // Verifies Driver Identity & Vehicle Inputs
        expect(find.text('Driving License (DL) Number *'), findsOneWidget);
        expect(find.text('Car Registration / Number Plate *'), findsOneWidget);
        expect(find.text('Vehicle Make & Model *'), findsOneWidget);
        expect(find.text('IND'), findsOneWidget); // Live HSRP Plate preview

        // Verifies Default User Avatar Icon & Optional Photo Upload
        expect(find.text('Upload driver photo (Optional)'), findsOneWidget);
        expect(find.byIcon(Icons.person_rounded), findsWidgets);

        // Toggle Photo Upload
        await tester.ensureVisible(find.text('Upload driver photo (Optional)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Upload driver photo (Optional)'));
        await tester.pumpAndSettle();
        expect(find.text('Remove photo (Use default icon)'), findsOneWidget);

        // Toggle back to Default Avatar Icon
        await tester.ensureVisible(
          find.text('Remove photo (Use default icon)'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remove photo (Use default icon)'));
        await tester.pumpAndSettle();
        expect(find.text('Upload driver photo (Optional)'), findsOneWidget);
      },
    );

    testWidgets(
      'RegisterScreen switching roles preserves entered driver data without loss',
      (tester) async {
        await tester.pumpWidget(createTestApp(const RegisterScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await advanceRegisterToStep2(tester);

        // Select Driver Role and enter details
        await tester.tap(find.text('Driver'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'e.g. GJ01 20200012345'),
          'GJ01 20240098765',
        );
        await tester.pump();

        await tester.enterText(
          find.widgetWithText(TextField, 'e.g. GJ-01-AB-1234'),
          'GJ-01-XX-9999',
        );
        await tester.pump();

        // Switch to Passenger role
        await tester.ensureVisible(find.text('Passenger'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Passenger'));
        await tester.pumpAndSettle();

        expect(find.text('Driving License (DL) Number *'), findsNothing);

        // Switch back to Driver role
        await tester.ensureVisible(find.text('Driver'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Driver'));
        await tester.pumpAndSettle();

        // Verify values are preserved!
        await tester.ensureVisible(find.text('GJ01 20240098765'));
        expect(find.text('GJ01 20240098765'), findsOneWidget);
        await tester.ensureVisible(find.text('GJ-01-XX-9999').first);
        expect(find.text('GJ-01-XX-9999'), findsWidgets);
      },
    );

    testWidgets(
      'RegisterScreen driver verification suite renders without overflow on 320dp screen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(const RegisterScreen(), width: 320),
        );
        await tester.pumpAndSettle();

        await advanceRegisterToStep2(tester);

        // Select Driver Role
        await tester.ensureVisible(find.text('Driver'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Driver'));
        await tester.pumpAndSettle();

        // Ensure everything fits and renders without overflow
        await tester.ensureVisible(
          find.text('Manual Admin Verification Required'),
        );
        expect(find.text('Manual Admin Verification Required'), findsOneWidget);
        expect(find.text('Complete Registration'), findsOneWidget);
      },
    );
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

    expect(
      find.text('Intelligent journeys, shared naturally.'),
      findsOneWidget,
    );
    for (final letter in ['S', 'a', 'h', 'y', 'ā', 'n']) {
      expect(find.text(letter), findsOneWidget);
    }
  });

  group('Onboarding UI Tests', () {
    testWidgets(
      'Continue advances through the three original onboarding pages',
      (tester) async {
        var finished = false;
        await tester.pumpWidget(
          createTestApp(
            LuxuryOnboardingScreen(onFinish: () => finished = true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Better journeys start together.'), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Find rides that fit your route.'), findsOneWidget);

        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('A more connected way to travel.'), findsOneWidget);

        await tester.tap(find.text('Get started'));
        await tester.pump();
        expect(finished, isTrue);
      },
    );

    testWidgets('Skip completes onboarding without changing the page', (
      tester,
    ) async {
      var finished = false;
      await tester.pumpWidget(
        createTestApp(LuxuryOnboardingScreen(onFinish: () => finished = true)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      expect(finished, isTrue);
      expect(find.text('Better journeys start together.'), findsOneWidget);
    });

    testWidgets('Finger swiping horizontally transitions through pages', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(LuxuryOnboardingScreen(onFinish: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Better journeys start together.'), findsOneWidget);

      // Swipe left from anywhere on the screen
      await tester.drag(find.byType(PageView), const Offset(-450, 0));
      await tester.pumpAndSettle();
      expect(find.text('Find rides that fit your route.'), findsOneWidget);

      // Swipe left again
      await tester.drag(find.byType(PageView), const Offset(-450, 0));
      await tester.pumpAndSettle();
      expect(find.text('A more connected way to travel.'), findsOneWidget);
    });

    testWidgets(
      'Onboarding renders without overflow on 320dp and 360dp screens',
      (tester) async {
        for (final width in [320.0, 360.0, 390.0, 412.0]) {
          tester.view.physicalSize = Size(width, 640.0);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            createTestApp(
              LuxuryOnboardingScreen(
                key: ValueKey<double>(width),
                onFinish: () {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Check page 1
          expect(tester.takeException(), isNull);
          expect(find.text('Better journeys start together.'), findsOneWidget);

          // Check page 2
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Find rides that fit your route.'), findsOneWidget);

          // Check page 3
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('A more connected way to travel.'), findsOneWidget);
          expect(find.text('Get started'), findsOneWidget);
        }
      },
    );
  });
}
