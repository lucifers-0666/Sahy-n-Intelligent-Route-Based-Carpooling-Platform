import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/shared/models/user_model.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  });

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<Map<String, dynamic>> sendOtp(String phone);

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  });

  Future<Map<String, dynamic>> forgotPassword(String email);

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<UserModel> getProfile();
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  final SecureStorageService storageService;

  AuthRepositoryImpl({required this.apiClient, required this.storageService});

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final cleanPhone = phone.length == 10 ? '+91$phone' : phone;
    final response = await apiClient.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'phone': cleanPhone,
        'password': password,
      },
    );

    final token = response['accessToken'] as String?;
    final user = UserModel.fromJson(response['user']);

    if (token != null) {
      apiClient.setAuthToken(token);
      await storageService.saveToken(token);
      await storageService.saveUser(user);
    }

    final result = <String, dynamic>{'user': user};
    if (token != null) {
      result['token'] = token;
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/auth/login',
      body: {'identifier': identifier, 'password': password},
    );

    final token = response['accessToken'] as String;
    final user = UserModel.fromJson(response['user']);

    apiClient.setAuthToken(token);
    await storageService.saveToken(token);
    await storageService.saveUser(user);

    return {'token': token, 'user': user};
  }

  @override
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    return await apiClient.post('/auth/send-otp', body: {'phone': phone});
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await apiClient.post(
      '/auth/verify-otp',
      body: {'phone': phone, 'otp': otp},
    );

    final token = response['accessToken'] as String;
    final user = UserModel.fromJson(response['user']);

    apiClient.setAuthToken(token);
    await storageService.saveToken(token);
    await storageService.saveUser(user);

    return {'token': token, 'user': user};
  }

  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await apiClient.post(
      '/auth/forgot-password',
      body: {'email': email},
    );
  }

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return await apiClient.post(
      '/auth/reset-password',
      body: {
        'token': token,
        'newPassword': newPassword,
        'password': newPassword,
      },
    );
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await apiClient.get('/users/profile');
      final user = UserModel.fromJson(response['data']);
      await storageService.saveUser(user);
      return user;
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        rethrow;
      }
      final storedUser = await storageService.getUser();
      if (storedUser != null) return storedUser;
      rethrow;
    }
  }
}
