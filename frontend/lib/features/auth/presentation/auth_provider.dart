import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/shared/models/user_model.dart';
import 'package:sahyan/features/auth/data/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? token;
  final String? errorMessage;
  final String? otpSentToPhone;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.errorMessage,
    this.otpSentToPhone,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isGuest => !isAuthenticated || user == null;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? token,
    String? errorMessage,
    String? otpSentToPhone,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage,
      otpSentToPhone: otpSentToPhone ?? this.otpSentToPhone,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repository;
  final SecureStorageService storageService;
  final ApiClient apiClient;

  AuthNotifier({
    required this.repository,
    required this.storageService,
    required this.apiClient,
  }) : super(const AuthState()) {
    checkAuthStatus();
  }

  /// On App Startup: Check secure storage and restore session
  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final token = await storageService.getToken();
      final storedUser = await storageService.getUser();

      if (token != null && token.isNotEmpty) {
        apiClient.setAuthToken(token);
        UserModel? user;
        try {
          user = await repository.getProfile();
          await storageService.saveUser(user);
        } catch (e) {
          if (e is ApiException && e.statusCode == 401) {
            await storageService.clearSession();
            apiClient.setAuthToken(null);
            state = state.copyWith(
              status: AuthStatus.unauthenticated,
              user: null,
              token: null,
            );
            return;
          }
          // Network offline fallback: use cached user if available
          user = storedUser;
        }

        if (user != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            token: token,
            user: user,
          );
          return;
        }
      }

      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final result = await repository.login(
        identifier: identifier,
        password: password,
      );

      final token = result['token'] as String;
      final user = result['user'] as UserModel;

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final result = await repository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      final user = result['user'] as UserModel;

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: user,
        otpSentToPhone: phone,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await repository.sendOtp(phone);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        otpSentToPhone: phone,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final phone = state.otpSentToPhone ?? state.user?.phone ?? '';
      final result = await repository.verifyOtp(phone: phone, otp: otp);

      final token = result['token']?.toString();
      final user = result['user'] is UserModel
          ? result['user'] as UserModel
          : null;

      if (token == null || user == null) {
        throw Exception('Authentication failed: Missing token or user profile');
      }

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await repository.forgotPassword(email);
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await repository.resetPassword(token: token, newPassword: newPassword);
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  Future<void> logout() async {
    await storageService.clearSession();
    apiClient.setAuthToken(null);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// Global Providers
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  return AuthRepositoryImpl(
    apiClient: apiClient,
    storageService: storageService,
  );
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  final api = ref.watch(apiClientProvider);
  return AuthNotifier(
    repository: repo,
    storageService: storage,
    apiClient: api,
  );
});
