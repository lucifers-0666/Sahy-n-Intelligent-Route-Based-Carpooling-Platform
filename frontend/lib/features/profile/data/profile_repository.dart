import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/shared/models/user_model.dart';

abstract class ProfileRepository {
  Future<UserModel> getProfile();
  Future<UserModel> updateProfile({
    required String name,
    required String city,
    String? profilePhoto,
    String? bio,
  });
  Future<UserPreferences> updatePreferences({
    required bool notifications,
    required bool allowSmoking,
    required bool allowPets,
  });
  Future<List<EmergencyContact>> getEmergencyContacts();
  Future<EmergencyContact> addEmergencyContact({
    required String name,
    required String phone,
    String? relationship,
  });
  Future<EmergencyContact> updateEmergencyContact({
    required String id,
    required String name,
    required String phone,
    String? relationship,
  });
  Future<void> deleteEmergencyContact(String id);
  Future<Map<String, dynamic>> submitDriverApplication({
    required String licenseNumber,
    String? licenseDocUrl,
    String? rcDocUrl,
    String? idDocUrl,
  });
  Future<Map<String, dynamic>> getDriverStatus();
  Future<void> anonymizeAccount({String reason = 'User requested account erasure'});
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ApiClient apiClient;
  final SecureStorageService storageService;

  ProfileRepositoryImpl({
    required this.apiClient,
    required this.storageService,
  });

  @override
  Future<UserModel> getProfile() async {
    final response = await apiClient.get('/users/profile');
    final user = UserModel.fromJson(response['data']);
    await storageService.saveUser(user);
    return user;
  }

  @override
  Future<UserModel> updateProfile({
    required String name,
    required String city,
    String? profilePhoto,
    String? bio,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'city': city,
      if (profilePhoto != null && profilePhoto.isNotEmpty)
        'profileImage': profilePhoto,
      if (bio != null && bio.isNotEmpty) 'bio': bio,
    };

    final response = await apiClient.put('/users/profile', body: payload);
    final user = UserModel.fromJson(response['data']);
    await storageService.saveUser(user);
    return user;
  }

  @override
  Future<UserPreferences> updatePreferences({
    required bool notifications,
    required bool allowSmoking,
    required bool allowPets,
  }) async {
    final payload = {
      'notifications': notifications,
      'allowSmoking': allowSmoking,
      'allowPets': allowPets,
    };

    final response = await apiClient.put('/users/preferences', body: payload);
    final preferences = UserPreferences.fromJson(response['data']);

    // Update locally stored user if available
    final storedUser = await storageService.getUser();
    if (storedUser != null) {
      final updatedUser = storedUser.copyWith(preferences: preferences);
      await storageService.saveUser(updatedUser);
    }

    return preferences;
  }

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    final response = await apiClient.get('/users/emergency-contacts');
    final list =
        (response['data'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map((c) => EmergencyContact.fromJson(c))
            .toList() ??
        [];
    return list;
  }

  @override
  Future<EmergencyContact> addEmergencyContact({
    required String name,
    required String phone,
    String? relationship,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-]'), '');
    final formattedPhone =
        cleanPhone.length == 10 && !cleanPhone.startsWith('+91')
        ? '+91$cleanPhone'
        : cleanPhone;

    final payload = {
      'name': name,
      'phone': formattedPhone,
      if (relationship != null && relationship.isNotEmpty)
        'relationship': relationship,
    };

    final response = await apiClient.post(
      '/users/emergency-contacts',
      body: payload,
    );
    final contact = EmergencyContact.fromJson(response['data']);

    // Sync locally stored user
    final storedUser = await storageService.getUser();
    if (storedUser != null) {
      final updatedList = [...storedUser.emergencyContacts, contact];
      await storageService.saveUser(
        storedUser.copyWith(emergencyContacts: updatedList),
      );
    }

    return contact;
  }

  @override
  Future<EmergencyContact> updateEmergencyContact({
    required String id,
    required String name,
    required String phone,
    String? relationship,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-]'), '');
    final formattedPhone =
        cleanPhone.length == 10 && !cleanPhone.startsWith('+91')
        ? '+91$cleanPhone'
        : cleanPhone;

    final payload = {
      'name': name,
      'phone': formattedPhone,
      if (relationship != null && relationship.isNotEmpty)
        'relationship': relationship,
    };

    final response = await apiClient.put(
      '/users/emergency-contacts/$id',
      body: payload,
    );
    final contact = EmergencyContact.fromJson(response['data']);

    // Sync locally stored user
    final storedUser = await storageService.getUser();
    if (storedUser != null) {
      final updatedList = storedUser.emergencyContacts
          .map((c) => c.id == id ? contact : c)
          .toList();
      await storageService.saveUser(
        storedUser.copyWith(emergencyContacts: updatedList),
      );
    }

    return contact;
  }

  @override
  Future<void> deleteEmergencyContact(String id) async {
    await apiClient.delete('/users/emergency-contacts/$id');

    // Sync locally stored user
    final storedUser = await storageService.getUser();
    if (storedUser != null) {
      final updatedList = storedUser.emergencyContacts
          .where((c) => c.id != id)
          .toList();
      await storageService.saveUser(
        storedUser.copyWith(emergencyContacts: updatedList),
      );
    }
  }

  @override
  Future<Map<String, dynamic>> submitDriverApplication({
    required String licenseNumber,
    String? licenseDocUrl,
    String? rcDocUrl,
    String? idDocUrl,
  }) async {
    final payload = {
      'licenseNumber': licenseNumber.trim().toUpperCase(),
      if (licenseDocUrl != null && licenseDocUrl.isNotEmpty)
        'licenseDocUrl': licenseDocUrl,
      if (rcDocUrl != null && rcDocUrl.isNotEmpty) 'rcDocUrl': rcDocUrl,
      if (idDocUrl != null && idDocUrl.isNotEmpty) 'idDocUrl': idDocUrl,
    };

    final response = await apiClient.post(
      '/users/driver-application',
      body: payload,
    );

    // Sync locally stored user
    final storedUser = await storageService.getUser();
    if (storedUser != null) {
      final updatedUser = storedUser.copyWith(
        driverOnboardingStatus: 'submitted',
        licenseNumber: licenseNumber.trim().toUpperCase(),
        rejectionReason: '',
      );
      await storageService.saveUser(updatedUser);
    }

    return response;
  }

  @override
  Future<Map<String, dynamic>> getDriverStatus() async {
    final response = await apiClient.get('/users/driver-status');
    return response['data'] as Map<String, dynamic>? ?? {};
  }

  @override
  Future<void> anonymizeAccount({
    String reason = 'User requested account erasure',
  }) async {
    await apiClient.post(
      '/users/anonymize-data',
      body: {'reason': reason},
    );
    await storageService.clearSession();
  }
}


