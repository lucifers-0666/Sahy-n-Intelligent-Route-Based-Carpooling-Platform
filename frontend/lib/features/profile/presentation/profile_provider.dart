import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/shared/models/user_model.dart';
import 'package:sahyan/features/profile/data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  return ProfileRepositoryImpl(
    apiClient: apiClient,
    storageService: storageService,
  );
});

class ProfileState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final List<EmergencyContact> emergencyContacts;

  const ProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.emergencyContacts = const [],
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository repository;
  final Ref ref;

  ProfileNotifier({required this.repository, required this.ref})
    : super(const ProfileState());

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  Future<bool> updateProfile({
    required String name,
    required String city,
    String? profilePhoto,
    String? bio,
  }) async {
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      final updatedUser = await repository.updateProfile(
        name: name,
        city: city,
        profilePhoto: profilePhoto,
        bio: bio,
      );
      ref.read(authProvider.notifier).updateUser(updatedUser);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Profile updated successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updatePreferences({
    required bool notifications,
    required bool allowSmoking,
    required bool allowPets,
  }) async {
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      final updatedPrefs = await repository.updatePreferences(
        notifications: notifications,
        allowSmoking: allowSmoking,
        allowPets: allowPets,
      );
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        ref
            .read(authProvider.notifier)
            .updateUser(currentUser.copyWith(preferences: updatedPrefs));
      }
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Preferences updated successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> loadEmergencyContacts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final contacts = await repository.getEmergencyContacts();
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        ref
            .read(authProvider.notifier)
            .updateUser(currentUser.copyWith(emergencyContacts: contacts));
      }
      state = state.copyWith(isLoading: false, emergencyContacts: contacts);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> addEmergencyContact({
    required String name,
    required String phone,
    String? relationship,
  }) async {
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      final createdContact = await repository.addEmergencyContact(
        name: name,
        phone: phone,
        relationship: relationship,
      );
      final updatedContacts = [...state.emergencyContacts, createdContact];
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        ref
            .read(authProvider.notifier)
            .updateUser(
              currentUser.copyWith(emergencyContacts: updatedContacts),
            );
      }
      state = state.copyWith(
        isSaving: false,
        emergencyContacts: updatedContacts,
        successMessage: 'Emergency contact added successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateEmergencyContact({
    required String id,
    required String name,
    required String phone,
    String? relationship,
  }) async {
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      final updatedContact = await repository.updateEmergencyContact(
        id: id,
        name: name,
        phone: phone,
        relationship: relationship,
      );
      final updatedContacts = state.emergencyContacts
          .map((c) => c.id == id ? updatedContact : c)
          .toList();
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        ref
            .read(authProvider.notifier)
            .updateUser(
              currentUser.copyWith(emergencyContacts: updatedContacts),
            );
      }
      state = state.copyWith(
        isSaving: false,
        emergencyContacts: updatedContacts,
        successMessage: 'Emergency contact updated successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteEmergencyContact(String id) async {
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      await repository.deleteEmergencyContact(id);
      final updatedContacts = state.emergencyContacts
          .where((c) => c.id != id)
          .toList();
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        ref
            .read(authProvider.notifier)
            .updateUser(
              currentUser.copyWith(emergencyContacts: updatedContacts),
            );
      }
      state = state.copyWith(
        isSaving: false,
        emergencyContacts: updatedContacts,
        successMessage: 'Emergency contact removed successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> submitDriverApplication({
    required String licenseNumber,
    String? licenseDocUrl,
    String? rcDocUrl,
    String? idDocUrl,
  }) async {
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      await repository.submitDriverApplication(
        licenseNumber: licenseNumber,
        licenseDocUrl: licenseDocUrl,
        rcDocUrl: rcDocUrl,
        idDocUrl: idDocUrl,
      );
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        ref.read(authProvider.notifier).updateUser(
          currentUser.copyWith(
            driverOnboardingStatus: 'submitted',
            licenseNumber: licenseNumber.trim().toUpperCase(),
            rejectionReason: '',
          ),
        );
      }
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Driver application submitted successfully for review',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchDriverStatus() async {
    try {
      final status = await repository.getDriverStatus();
      return status;
    } catch (e) {
      return {};
    }
  }

  Future<bool> anonymizeAccount({
    String reason = 'User requested account erasure',
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await repository.anonymizeAccount(reason: reason);
      await ref.read(authProvider.notifier).logout();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository: repo, ref: ref);
});
