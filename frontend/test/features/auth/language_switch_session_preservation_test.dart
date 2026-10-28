import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/core/localization/app_locale_provider.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/shared/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Language Switch Session Preservation Tests', () {
    test('Switching language from EN to Gujarati does not sign out authenticated user', () async {
      final container = ProviderContainer(
        overrides: [
          appLocaleProvider.overrideWith(
            (ref) => AppLocaleNotifier(null),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Verify initial language is English
      expect(container.read(appLocaleProvider).languageCode, 'en');

      final client = container.read(apiClientProvider);
      expect(client.activeLanguageCode, 'en');

      // Simulate authenticated state
      client.setAuthToken('valid_jwt_session_token_123');
      final authNotifier = container.read(authProvider.notifier);
      authNotifier.state = AuthState(
        status: AuthStatus.authenticated,
        token: 'valid_jwt_session_token_123',
        user: UserModel(
          id: 'usr_test_101',
          name: 'Zaid Amreliya',
          email: 'zaid@sahyan.in',
          phone: '+91 98765 43210',
          city: 'Ahmedabad',
          verificationStatus: UserVerificationStatus.verified,
          rating: 4.9,
          totalRides: 12,
        ),
      );

      // Verify authenticated before language switch
      expect(container.read(authProvider).isAuthenticated, isTrue);
      expect(container.read(authProvider).user?.name, 'Zaid Amreliya');

      // Switch language to Gujarati (gu)
      await container
          .read(appLocaleProvider.notifier)
          .setLanguage(SahyanLanguage.gujarati);

      // Verify locale changed
      expect(container.read(appLocaleProvider).languageCode, 'gu');

      // Verify ApiClient activeLanguageCode updated seamlessly
      expect(container.read(apiClientProvider).activeLanguageCode, 'gu');

      // CRUCIAL: Verify user remains 100% authenticated and not signed out
      expect(container.read(authProvider).isAuthenticated, isTrue);
      expect(container.read(authProvider).token, 'valid_jwt_session_token_123');
      expect(container.read(authProvider).user?.name, 'Zaid Amreliya');
      expect(container.read(authProvider).status, AuthStatus.authenticated);

      // Switch language to Hindi (hi)
      await container
          .read(appLocaleProvider.notifier)
          .setLanguage(SahyanLanguage.hindi);

      expect(container.read(appLocaleProvider).languageCode, 'hi');
      expect(container.read(apiClientProvider).activeLanguageCode, 'hi');
      expect(container.read(authProvider).isAuthenticated, isTrue);
      expect(container.read(authProvider).status, AuthStatus.authenticated);
    });
  });
}
