import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../features/auth/presentation/auth_provider.dart';

enum AppStartupStatus {
  initializing,
  onboardingRequired,
  authEntryRequired,
  ready,
}

class AppStartupState {
  final AppStartupStatus status;
  final String? errorMessage;

  const AppStartupState({
    this.status = AppStartupStatus.initializing,
    this.errorMessage,
  });

  AppStartupState copyWith({AppStartupStatus? status, String? errorMessage}) {
    return AppStartupState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AppStartupNotifier extends StateNotifier<AppStartupState> {
  final SecureStorageService storageService;
  final AuthNotifier authNotifier;
  bool _isOverridden = false;

  AppStartupNotifier({required this.storageService, required this.authNotifier})
    : super(const AppStartupState()) {
    initialize();
  }

  Future<void> initialize() async {
    _isOverridden = false;
    state = const AppStartupState(status: AppStartupStatus.initializing);
    try {
      final hasCompletedOnboarding = await storageService
          .hasCompletedOnboarding();
      final token = await storageService.getToken();

      if (_isOverridden) return;

      if (token != null && token.isNotEmpty) {
        await authNotifier.checkAuthStatus();
        if (_isOverridden) return;
        if (authNotifier.state.isAuthenticated) {
          await storageService.setCompletedOnboarding(true);
          state = const AppStartupState(status: AppStartupStatus.ready);
          return;
        }
      }

      if (_isOverridden) return;

      if (!hasCompletedOnboarding) {
        state = const AppStartupState(
          status: AppStartupStatus.onboardingRequired,
        );
      } else {
        state = const AppStartupState(
          status: AppStartupStatus.authEntryRequired,
        );
      }
    } catch (e) {
      if (_isOverridden) return;
      state = AppStartupState(
        status: AppStartupStatus.authEntryRequired,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> completeOnboarding() async {
    _isOverridden = true;
    await storageService.setCompletedOnboarding(true);
    state = const AppStartupState(status: AppStartupStatus.authEntryRequired);
  }

  void markReady() {
    state = const AppStartupState(status: AppStartupStatus.ready);
  }

  void requireAuthEntry() {
    state = const AppStartupState(status: AppStartupStatus.authEntryRequired);
  }
}

final appStartupProvider =
    StateNotifierProvider<AppStartupNotifier, AppStartupState>((ref) {
      final storageService = ref.watch(secureStorageServiceProvider);
      final authNotifier = ref.watch(authProvider.notifier);
      final notifier = AppStartupNotifier(
        storageService: storageService,
        authNotifier: authNotifier,
      );
      ref.listen<AuthState>(authProvider, (previous, next) {
        if (next.isAuthenticated) {
          notifier.markReady();
        }
      });
      return notifier;
    });
