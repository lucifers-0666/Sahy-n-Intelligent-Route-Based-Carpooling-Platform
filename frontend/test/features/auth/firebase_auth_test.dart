import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sahyan/shared/models/user_model.dart';
import 'package:sahyan/features/auth/data/auth_repository.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/core/network/api_client.dart';

class MockSecureStorageService implements SecureStorageService {
  String? _token;
  UserModel? _user;

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

  bool _completedOnboarding = false;

  @override
  Future<void> setCompletedOnboarding(bool completed) async =>
      _completedOnboarding = completed;

  @override
  Future<bool> hasCompletedOnboarding() async => _completedOnboarding;
}

class MockFirebaseCapableAuthRepo implements FirebaseAuthRepository {
  bool sendPhoneOtpCalled = false;
  bool verifyPhoneOtpCalled = false;
  bool googleSignInCalled = false;
  bool googleSignInCancelled = false;
  bool signOutCalled = false;
  bool linkGoogleCalled = false;
  bool linkPhoneCalled = false;
  bool linkCollisionError = false;

  final UserModel mockUser = const UserModel(
    id: 'user_fb_001',
    name: 'Aarav Sharma',
    email: 'aarav@example.com',
    phone: '+919999911111',
    city: 'Ahmedabad',
    verificationStatus: UserVerificationStatus.verified,
    rating: 4.9,
    totalRides: 12,
  );

  @override
  Future<void> sendFirebasePhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onVerificationFailed,
    required void Function(PhoneAuthCredential credential)
    onVerificationCompleted,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    sendPhoneOtpCalled = true;
    if (phoneNumber.contains('invalid')) {
      onVerificationFailed('The provided phone number is invalid.');
    } else {
      onCodeSent('test_verification_id_999', 12345);
    }
  }

  @override
  Future<Map<String, dynamic>> verifyFirebasePhoneOtp({
    required String verificationId,
    required String smsCode,
    String? name,
  }) async {
    verifyPhoneOtpCalled = true;
    if (smsCode == '000000') {
      throw Exception('Invalid verification code entered.');
    }
    return {
      'user': mockUser,
      'token': 'mock_firebase_id_token_xyz',
      'isNewUser': false,
    };
  }

  @override
  Future<Map<String, dynamic>> signInWithGoogle() async {
    googleSignInCalled = true;
    if (googleSignInCancelled) {
      return {'cancelled': true};
    }
    return {
      'user': mockUser,
      'token': 'mock_google_id_token_xyz',
      'isNewUser': false,
      'cancelled': false,
    };
  }

  @override
  Future<Map<String, dynamic>> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    return {
      'user': mockUser,
      'token': 'mock_email_reg_token',
      'isNewUser': true,
    };
  }

  @override
  Future<Map<String, dynamic>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return {
      'user': mockUser,
      'token': 'mock_email_signin_token',
      'isNewUser': false,
    };
  }

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<Map<String, dynamic>> linkPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    linkPhoneCalled = true;
    if (linkCollisionError) {
      throw Exception(
        'This phone number is already linked to another Sahyān account.',
      );
    }
    return {'user': mockUser};
  }

  @override
  Future<Map<String, dynamic>> linkGoogleAccount() async {
    linkGoogleCalled = true;
    if (linkCollisionError) {
      throw Exception(
        'This Google account is already linked to another Sahyān profile.',
      );
    }
    return {'user': mockUser};
  }

  @override
  Future<Map<String, dynamic>> syncWithBackend({
    required String idToken,
    String? name,
    String? phone,
  }) async => {'user': mockUser, 'token': idToken, 'isNewUser': false};

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  // Legacy stubs
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
  Future<UserModel> getProfile() async => mockUser;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseCapableAuthRepo mockRepo;
  late MockSecureStorageService fakeStorage;
  late ApiClient fakeApi;
  late AuthNotifier authNotifier;

  setUp(() {
    mockRepo = MockFirebaseCapableAuthRepo();
    fakeStorage = MockSecureStorageService();
    fakeApi = ApiClient();
    authNotifier = AuthNotifier(
      repository: mockRepo,
      storageService: fakeStorage,
      apiClient: fakeApi,
    );
  });

  group('Firebase Phone OTP Flow', () {
    test(
      'sendFirebasePhoneOtp records verificationId and updates state',
      () async {
        final success = await authNotifier.sendFirebasePhoneOtp(
          '+919876543210',
        );
        expect(success, isTrue);
        expect(mockRepo.sendPhoneOtpCalled, isTrue);
        expect(
          authNotifier.state.firebaseVerificationId,
          'test_verification_id_999',
        );
        expect(authNotifier.state.otpSentToPhone, '+919876543210');
        expect(authNotifier.state.resendToken, 12345);
      },
    );

    test(
      'sendFirebasePhoneOtp sets error state when phone number is invalid',
      () async {
        final success = await authNotifier.sendFirebasePhoneOtp('invalid_num');
        expect(success, isFalse);
        expect(authNotifier.state.status, AuthStatus.error);
        expect(authNotifier.state.errorMessage, contains('invalid'));
      },
    );

    test(
      'verifyFirebasePhoneOtp authenticates user and sets isPhoneVerified',
      () async {
        // Setup state with verificationId
        await authNotifier.sendFirebasePhoneOtp('+919876543210');

        final success = await authNotifier.verifyFirebasePhoneOtp('123456');
        expect(success, isTrue);
        expect(authNotifier.state.status, AuthStatus.authenticated);
        expect(authNotifier.state.user?.name, 'Aarav Sharma');
        expect(authNotifier.state.isPhoneVerified, isTrue);
        expect(authNotifier.state.token, 'mock_firebase_id_token_xyz');
      },
    );

    test(
      'verifyFirebasePhoneOtp handles incorrect SMS code rejection',
      () async {
        await authNotifier.sendFirebasePhoneOtp('+919876543210');

        final success = await authNotifier.verifyFirebasePhoneOtp('000000');
        expect(success, isFalse);
        expect(authNotifier.state.status, AuthStatus.error);
        expect(
          authNotifier.state.errorMessage,
          contains('Invalid verification code'),
        );
      },
    );
  });

  group('Google Sign-In Flow', () {
    test('signInWithGoogle authenticates user successfully', () async {
      final success = await authNotifier.signInWithGoogle();
      expect(success, isTrue);
      expect(mockRepo.googleSignInCalled, isTrue);
      expect(authNotifier.state.status, AuthStatus.authenticated);
      expect(authNotifier.state.user?.name, 'Aarav Sharma');
      expect(authNotifier.state.isEmailVerified, isTrue);
    });

    test(
      'signInWithGoogle handles cancellation cleanly without setting error state',
      () async {
        mockRepo.googleSignInCancelled = true;
        final success = await authNotifier.signInWithGoogle();
        expect(success, isFalse);
        expect(authNotifier.state.status, AuthStatus.unauthenticated);
        expect(authNotifier.state.errorMessage, isNull);
      },
    );
  });

  group('Email / Password Flow', () {
    test(
      'registerWithEmail sets authenticated state with user profile',
      () async {
        final success = await authNotifier.registerWithEmail(
          name: 'Aarav Sharma',
          email: 'aarav@example.com',
          password: 'Password123!',
        );
        expect(success, isTrue);
        expect(authNotifier.state.status, AuthStatus.authenticated);
        expect(authNotifier.state.user?.email, 'aarav@example.com');
      },
    );

    test(
      'signInWithEmail sets authenticated state with user profile',
      () async {
        final success = await authNotifier.signInWithEmail(
          email: 'aarav@example.com',
          password: 'Password123!',
        );
        expect(success, isTrue);
        expect(authNotifier.state.status, AuthStatus.authenticated);
      },
    );
  });

  group('Account Linking and Collision Handling', () {
    test('linkGoogle updates authenticated user state', () async {
      final success = await authNotifier.linkGoogle();
      expect(success, isTrue);
      expect(mockRepo.linkGoogleCalled, isTrue);
    });

    test(
      'linkGoogle captures already-linked or collision exceptions gracefully',
      () async {
        mockRepo.linkCollisionError = true;
        final success = await authNotifier.linkGoogle();
        expect(success, isFalse);
        expect(authNotifier.state.errorMessage, contains('already linked'));
      },
    );
  });

  group('Sign Out & Session Management', () {
    test(
      'logout invokes repository signOut and resets state to unauthenticated',
      () async {
        // First authenticate
        await authNotifier.signInWithGoogle();
        expect(authNotifier.state.status, AuthStatus.authenticated);

        // Now logout
        await authNotifier.logout();
        expect(mockRepo.signOutCalled, isTrue);
        expect(authNotifier.state.status, AuthStatus.unauthenticated);
        expect(authNotifier.state.user, isNull);
      },
    );
  });
}
