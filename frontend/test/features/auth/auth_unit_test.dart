import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/auth/data/auth_repository.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/shared/models/user_model.dart';

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

class MockAuthRepository implements AuthRepository {
  bool shouldFail = false;

  @override
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    if (shouldFail) throw Exception('Invalid credentials');
    final user = UserModel(
      id: 'usr_123',
      name: 'Arjun Patel',
      email: 'arjun@example.com',
      phone: '+919876543210',
      city: 'Ahmedabad',
      verificationStatus: UserVerificationStatus.verified,
      rating: 4.9,
      totalRides: 10,
    );
    return {'token': 'jwt_token_123', 'user': user};
  }

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (shouldFail) throw Exception('Email already exists');
    final user = UserModel(
      id: 'usr_456',
      name: name,
      email: email,
      phone: phone,
      city: 'Ahmedabad',
      verificationStatus: UserVerificationStatus.pending,
      rating: 5.0,
      totalRides: 0,
    );
    return {'user': user};
  }

  @override
  Future<Map<String, dynamic>> sendOtp(String phone) async => {'success': true};

  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    if (otp != '654321') throw Exception('Invalid OTP');
    final user = UserModel(
      id: 'usr_123',
      name: 'Arjun Patel',
      email: 'arjun@example.com',
      phone: phone,
      city: 'Ahmedabad',
      verificationStatus: UserVerificationStatus.verified,
      rating: 4.9,
      totalRides: 10,
    );
    return {'token': 'jwt_token_123', 'user': user};
  }

  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async => {
    'success': true,
  };

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async => {'success': true};

  @override
  Future<UserModel> getProfile() async {
    if (shouldFail) throw ApiException('Session expired', statusCode: 401);
    return UserModel(
      id: 'usr_123',
      name: 'Arjun Patel',
      email: 'arjun@example.com',
      phone: '+919876543210',
      city: 'Ahmedabad',
      verificationStatus: UserVerificationStatus.verified,
      rating: 4.9,
      totalRides: 10,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockRepo;
  late MockSecureStorageService storageService;
  late ApiClient apiClient;

  setUp(() {
    mockRepo = MockAuthRepository();
    storageService = MockSecureStorageService();
    apiClient = ApiClient();
  });

  test('AuthNotifier initial state is loading or unauthenticated', () async {
    final notifier = AuthNotifier(
      repository: mockRepo,
      storageService: storageService,
      apiClient: apiClient,
    );

    await Future.delayed(Duration.zero);
    expect(
      notifier.state.status,
      anyOf(AuthStatus.initial, AuthStatus.loading, AuthStatus.unauthenticated),
    );
  });

  test('Login success updates AuthNotifier state to authenticated', () async {
    final notifier = AuthNotifier(
      repository: mockRepo,
      storageService: storageService,
      apiClient: apiClient,
    );

    final result = await notifier.login(
      identifier: 'arjun@example.com',
      password: 'StrongPassword123!',
    );

    expect(result, isTrue);
    expect(notifier.state.status, AuthStatus.authenticated);
    expect(notifier.state.user?.name, 'Arjun Patel');
    expect(notifier.state.token, 'jwt_token_123');
  });

  test('Login failure updates AuthNotifier state to error', () async {
    mockRepo.shouldFail = true;
    final notifier = AuthNotifier(
      repository: mockRepo,
      storageService: storageService,
      apiClient: apiClient,
    );

    final result = await notifier.login(
      identifier: 'arjun@example.com',
      password: 'wrong',
    );

    expect(result, isFalse);
    expect(notifier.state.status, AuthStatus.error);
    expect(notifier.state.errorMessage, contains('Invalid credentials'));
  });

  test(
    'Registration leaves state unauthenticated pending 6-digit OTP verification',
    () async {
      final notifier = AuthNotifier(
        repository: mockRepo,
        storageService: storageService,
        apiClient: apiClient,
      );

      final result = await notifier.register(
        name: 'New User',
        email: 'new@example.com',
        phone: '9998887776',
        password: 'StrongPassword123!',
      );

      expect(result, isTrue);
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.otpSentToPhone, '9998887776');
    },
  );

  test(
    'Verify OTP with 6-digit code transitions state to authenticated with real token',
    () async {
      final notifier = AuthNotifier(
        repository: mockRepo,
        storageService: storageService,
        apiClient: apiClient,
      );

      await notifier.sendOtp('9998887776');
      expect(notifier.state.otpSentToPhone, '9998887776');

      final verifySuccess = await notifier.verifyOtp('654321');
      expect(verifySuccess, isTrue);
      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.token, 'jwt_token_123');
      expect(notifier.state.user?.name, 'Arjun Patel');
    },
  );

  test('Verify OTP with invalid code fails and sets error status', () async {
    final notifier = AuthNotifier(
      repository: mockRepo,
      storageService: storageService,
      apiClient: apiClient,
    );

    await notifier.sendOtp('9998887776');
    final verifySuccess = await notifier.verifyOtp('000000');
    expect(verifySuccess, isFalse);
    expect(notifier.state.status, AuthStatus.error);
  });

  test('Logout clears authentication state', () async {
    final notifier = AuthNotifier(
      repository: mockRepo,
      storageService: storageService,
      apiClient: apiClient,
    );

    await notifier.login(
      identifier: 'arjun@example.com',
      password: 'StrongPassword123!',
    );
    expect(notifier.state.status, AuthStatus.authenticated);

    await notifier.logout();
    expect(notifier.state.status, AuthStatus.unauthenticated);
    expect(notifier.state.user, isNull);
    expect(notifier.state.token, isNull);
  });

  test(
    'Session restoration restores authenticated state when valid token in storage',
    () async {
      await storageService.saveToken('valid_stored_jwt_token');

      final notifier = AuthNotifier(
        repository: mockRepo,
        storageService: storageService,
        apiClient: apiClient,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.token, 'valid_stored_jwt_token');
      expect(notifier.state.user?.name, 'Arjun Patel');
    },
  );

  test(
    'Session restoration clears session and unauthenticates on 401 response',
    () async {
      await storageService.saveToken('expired_jwt_token');
      mockRepo.shouldFail = true;

      final notifier = AuthNotifier(
        repository: mockRepo,
        storageService: storageService,
        apiClient: apiClient,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.user, isNull);
    },
  );
}
