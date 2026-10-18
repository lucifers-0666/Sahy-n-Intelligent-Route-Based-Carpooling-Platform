import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/shared/models/user_model.dart';
import 'package:sahyan/features/auth/data/auth_repository.dart';
import 'package:sahyan/app/router/app_router.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  suspended,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? token;
  final String? errorMessage;
  final String? otpSentToPhone;
  final String? firebaseVerificationId;
  final int? resendToken;
  final String? suspensionReason;
  final String? suspendedAt;
  final bool isPhoneVerified;
  final bool isEmailVerified;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.errorMessage,
    this.otpSentToPhone,
    this.firebaseVerificationId,
    this.resendToken,
    this.suspensionReason,
    this.suspendedAt,
    this.isPhoneVerified = false,
    this.isEmailVerified = false,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isSuspended => status == AuthStatus.suspended;
  bool get isGuest => !isAuthenticated || user == null;
  bool get isLoading => status == AuthStatus.loading;
  bool get isProfileComplete =>
      user != null &&
      user!.name.trim().isNotEmpty &&
      user!.name != 'Sahyān Traveler' &&
      user!.phone.isNotEmpty;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? token,
    String? errorMessage,
    String? otpSentToPhone,
    String? firebaseVerificationId,
    int? resendToken,
    String? suspensionReason,
    String? suspendedAt,
    bool? isPhoneVerified,
    bool? isEmailVerified,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage,
      otpSentToPhone: otpSentToPhone ?? this.otpSentToPhone,
      firebaseVerificationId:
          firebaseVerificationId ?? this.firebaseVerificationId,
      resendToken: resendToken ?? this.resendToken,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repository;
  final SecureStorageService storageService;
  final ApiClient apiClient;

  FirebaseAuthRepository? get _firebaseRepo =>
      repository is FirebaseAuthRepository
      ? repository as FirebaseAuthRepository
      : null;

  bool _isLoggingOut = false;

  AuthNotifier({
    required this.repository,
    required this.storageService,
    required this.apiClient,
  }) : super(const AuthState()) {
    apiClient.onUnauthorized = () {
      if (!_isLoggingOut) {
        logout();
      }
    };
    apiClient.tokenRefresher = () async {
      try {
        final fbRepo = _firebaseRepo;
        if (fbRepo != null && fbRepo.isFirebaseAvailable) {
          final newToken = await fbRepo.refreshToken();
          if (newToken != null && newToken.isNotEmpty) {
            state = state.copyWith(token: newToken);
            await storageService.saveToken(newToken);
            return newToken;
          }
        }
      } catch (_) {}
      return null;
    };
    apiClient.onAccountSuspended = (reason, suspendedAt) {
      handleSuspension(reason, suspendedAt);
    };
    checkAuthStatus();
  }

  Future<void> handleSuspension(String reason, [String? suspendedAt]) async {
    await storageService.clearSession();
    apiClient.setAuthToken(null);
    state = AuthState(
      status: AuthStatus.suspended,
      suspensionReason: reason,
      suspendedAt: suspendedAt,
      errorMessage: reason,
    );
    try {
      navigateToSuspendedScreen(reason, suspendedAt);
    } catch (_) {}
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
          if (e is ApiException && e.errorCode == 'ACCOUNT_SUSPENDED') {
            await handleSuspension(
              e.suspensionReason ?? e.message,
              e.suspendedAt,
            );
            return;
          }
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
          await storageService.setCompletedOnboarding(true);
          state = state.copyWith(
            status: AuthStatus.authenticated,
            token: token,
            user: user,
            isPhoneVerified: user.phone.isNotEmpty,
          );
          return;
        } else if (token.isNotEmpty) {
          final fallbackUser = storedUser ??
              UserModel(
                id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
                name: 'Sahyān Commuter',
                email: '',
                phone: '',
                city: 'Ahmedabad',
                verificationStatus: UserVerificationStatus.verified,
                rating: 5.0,
                totalRides: 0,
              );
          await storageService.saveUser(fallbackUser);
          await storageService.setCompletedOnboarding(true);
          state = state.copyWith(
            status: AuthStatus.authenticated,
            token: token,
            user: fallbackUser,
            isPhoneVerified: fallbackUser.phone.isNotEmpty,
          );
          return;
        }
      }

      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  // -------------------------------------------------------------
  // Firebase Authentication Actions
  // -------------------------------------------------------------

  /// Dispatches Phone OTP using Firebase Authentication SDK with seamless backend fallback
  Future<bool> sendFirebasePhoneOtp(String phoneNumber) async {
    final fbRepo = _firebaseRepo;
    if (fbRepo == null || !fbRepo.isFirebaseAvailable) {
      return await sendOtp(phoneNumber);
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    final completer = Completer<bool>();

    try {
      await fbRepo.sendFirebasePhoneOtp(
        phoneNumber: phoneNumber,
        forceResendingToken: state.resendToken,
        onCodeSent: (verificationId, resendToken) {
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            otpSentToPhone: phoneNumber,
            firebaseVerificationId: verificationId,
            resendToken: resendToken,
          );
          if (!completer.isCompleted) completer.complete(true);
        },
        onVerificationFailed: (errorMessage) {
          final isPhoneFormatError =
              errorMessage.toLowerCase().contains('invalid') &&
              (errorMessage.toLowerCase().contains('phone') ||
                  errorMessage.toLowerCase().contains('format') ||
                  errorMessage.toLowerCase().contains('number'));

          if (isPhoneFormatError) {
            state = state.copyWith(
              status: AuthStatus.error,
              errorMessage: errorMessage,
            );
            if (!completer.isCompleted) completer.complete(false);
            return;
          }

          // If Firebase rejects verification due to missing Google Play Services, unconfigured SHA-1,
          // quota limit, or device credential issue, automatically dispatch via backend OTP
          sendOtp(phoneNumber).then((res) {
            if (!completer.isCompleted) completer.complete(res);
          }).catchError((_) {
            if (!completer.isCompleted) {
              state = state.copyWith(
                status: AuthStatus.error,
                errorMessage: errorMessage,
              );
              completer.complete(false);
            }
          });
        },
        onVerificationCompleted: (credential) async {
          if (credential.smsCode != null &&
              state.firebaseVerificationId != null) {
            await verifyFirebasePhoneOtp(credential.smsCode!);
          }
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          state = state.copyWith(firebaseVerificationId: verificationId);
        },
      );
    } catch (e) {
      // In case of any initialization or runtime exception, immediately fall back to backend OTP
      try {
        final fallbackSuccess = await sendOtp(phoneNumber);
        if (!completer.isCompleted) completer.complete(fallbackSuccess);
      } catch (backendErr) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: backendErr.toString(),
        );
        if (!completer.isCompleted) completer.complete(false);
      }
    }

    return completer.future;
  }

  /// Verifies Phone OTP and provisions/syncs MongoDB profile
  Future<bool> verifyFirebasePhoneOtp(String smsCode, {String? name}) async {
    final fbRepo = _firebaseRepo;
    final verificationId = state.firebaseVerificationId;
    if (fbRepo == null ||
        !fbRepo.isFirebaseAvailable ||
        verificationId == null) {
      return await verifyOtp(smsCode);
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final result = await fbRepo.verifyFirebasePhoneOtp(
        verificationId: verificationId,
        smsCode: smsCode,
        name: name,
      );

      final token = result['token'] as String;
      final user = result['user'] as UserModel;

      apiClient.setAuthToken(token);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
        isPhoneVerified: true,
      );
      return true;
    } catch (e) {
      // If Firebase verification throws, try backend verification before erroring
      try {
        final backendSuccess = await verifyOtp(smsCode);
        if (backendSuccess) return true;
      } catch (_) {}

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sign In with Google and bootstrap/sync MongoDB profile
  Future<bool> signInWithGoogle() async {
    final fbRepo = _firebaseRepo;
    if (fbRepo == null || !fbRepo.isFirebaseAvailable) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage:
            'Google Sign-In is not configured on this device. Please sign in with Phone OTP or Password.',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final result = await fbRepo.signInWithGoogle();

      if (result['cancelled'] == true) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return false;
      }

      final token = result['token'] as String;
      final user = result['user'] as UserModel;

      apiClient.setAuthToken(token);
      await storageService.saveToken(token);
      await storageService.saveUser(user);
      await storageService.setCompletedOnboarding(true);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
        isEmailVerified: true,
      );
      return true;
    } catch (e) {
      final errStr = e.toString();
      final cleanMessage = errStr.contains('network_error') ||
              errStr.contains('ApiException: 7') ||
              errStr.contains('ApiException: 10') ||
              errStr.contains('ApiException: 12500') ||
              errStr.contains('ApiException')
          ? 'Google Sign-In is not configured on this device. Please sign in with Phone OTP or Password.'
          : (errStr.contains('not initialized')
              ? 'Google Sign-In is not configured on this device. Please sign in with Phone OTP or Password.'
              : errStr);
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: cleanMessage,
      );
      return false;
    }
  }

  /// Register with Email and Password via Firebase with backend fallback
  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final fbRepo = _firebaseRepo;
    if (fbRepo == null || !fbRepo.isFirebaseAvailable) {
      return await register(
        name: name,
        email: email,
        phone: phone ?? '',
        password: password,
      );
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final result = await fbRepo.registerWithEmailPassword(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      final token = result['token'] as String;
      final user = result['user'] as UserModel;

      apiClient.setAuthToken(token);
      await storageService.saveToken(token);
      await storageService.saveUser(user);
      await storageService.setCompletedOnboarding(true);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
        isEmailVerified: false,
      );
      return true;
    } catch (e) {
      try {
        return await register(
          name: name,
          email: email,
          phone: phone ?? '',
          password: password,
        );
      } catch (_) {}

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sign In with Email and Password via Firebase with backend fallback
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final fbRepo = _firebaseRepo;
    if (fbRepo == null || !fbRepo.isFirebaseAvailable) {
      return await login(identifier: email, password: password);
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final result = await fbRepo.signInWithEmailPassword(
        email: email,
        password: password,
      );

      final token = result['token'] as String;
      final user = result['user'] as UserModel;

      apiClient.setAuthToken(token);
      await storageService.saveToken(token);
      await storageService.saveUser(user);
      await storageService.setCompletedOnboarding(true);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );
      return true;
    } catch (e) {
      try {
        return await login(identifier: email, password: password);
      } catch (_) {}

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Send email verification link
  Future<bool> sendEmailVerification() async {
    final fbRepo = _firebaseRepo;
    if (fbRepo == null || !fbRepo.isFirebaseAvailable) return false;
    try {
      await fbRepo.sendEmailVerification();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Send password reset link via Firebase with backend fallback
  Future<bool> sendPasswordReset(String email) async {
    final fbRepo = _firebaseRepo;
    if (fbRepo == null || !fbRepo.isFirebaseAvailable) {
      return await forgotPassword(email);
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await fbRepo.sendPasswordResetEmail(email);
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      try {
        return await forgotPassword(email);
      } catch (_) {}

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Link Phone number to currently authenticated profile
  Future<bool> linkPhone(String smsCode) async {
    final fbRepo = _firebaseRepo;
    if (fbRepo == null) {
      state = state.copyWith(
        errorMessage: 'Account linking not supported in this environment.',
      );
      return false;
    }

    final verificationId = state.firebaseVerificationId;
    if (verificationId == null) {
      state = state.copyWith(errorMessage: 'No pending phone verification');
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final result = await fbRepo.linkPhoneCredential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final user = result['user'] as UserModel;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isPhoneVerified: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Link Google account to currently authenticated profile
  Future<bool> linkGoogle() async {
    final fbRepo = _firebaseRepo;
    if (fbRepo == null) {
      state = state.copyWith(
        errorMessage: 'Google linking not supported in this environment.',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final result = await fbRepo.linkGoogleAccount();
      if (result['cancelled'] == true) {
        state = state.copyWith(status: AuthStatus.authenticated);
        return false;
      }
      final user = result['user'] as UserModel;
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // -------------------------------------------------------------
  // Legacy / Direct API Endpoints (Preserved for compatibility)
  // -------------------------------------------------------------

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

      apiClient.setAuthToken(token);
      await storageService.saveToken(token);
      await storageService.saveUser(user);
      await storageService.setCompletedOnboarding(true);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );
      return true;
    } catch (e) {
      if (e is ApiException && e.errorCode == 'ACCOUNT_SUSPENDED') {
        await handleSuspension(e.suspensionReason ?? e.message, e.suspendedAt);
        return false;
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Authenticate using stored session credentials after hardware biometric confirmation
  Future<bool> loginWithBiometrics() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final token = await storageService.getToken();
      final storedUser = await storageService.getUser();

      if (token != null && token.isNotEmpty) {
        apiClient.setAuthToken(token);
        UserModel? user;
        try {
          user = await repository.getProfile();
          await storageService.saveUser(user);
        } catch (_) {
          user = storedUser;
        }

        if (user != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            token: token,
            user: user,
          );
          return true;
        }
      }

      if (storedUser != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: storedUser,
        );
        return true;
      }

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage:
            'No saved credentials found. Please sign in with password first.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Biometric authentication failed.',
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? role,
    String? licenseNumber,
    String? secondaryPhone,
    String? dateOfBirth,
    String? vehiclePlate,
    String? vehicleModel,
    String? vehicleType,
    String? profilePhoto,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final result = await repository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      final rawUser = result['user'];
      final user = rawUser is UserModel
          ? rawUser
          : (rawUser is Map<String, dynamic>
                ? UserModel.fromJson(rawUser)
                : UserModel(
                    id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    email: email,
                    phone: phone,
                    city: 'Ahmedabad',
                    verificationStatus: UserVerificationStatus.pending,
                    rating: 5.0,
                    totalRides: 0,
                  ));

      final updatedUser = (role == 'driver' || role == 'both')
          ? user.copyWith(
              role: role,
              canDrive: false,
              driverOnboardingStatus: 'submitted',
              profilePhoto: profilePhoto ?? user.profilePhoto,
            )
          : user;

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: updatedUser,
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

      apiClient.setAuthToken(token);
      await storageService.saveToken(token);
      await storageService.saveUser(user);
      await storageService.setCompletedOnboarding(true);

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
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    try {
      apiClient.setAuthToken(null);
      try {
        await apiClient.post('/auth/logout');
      } catch (_) {}
      if (repository is FirebaseAuthRepository) {
        try {
          await (repository as FirebaseAuthRepository).signOut();
        } catch (_) {}
      }
      await storageService.clearSession();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } finally {
      _isLoggingOut = false;
    }
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
