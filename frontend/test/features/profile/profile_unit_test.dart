import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/shared/models/user_model.dart';
import 'package:sahyan/features/profile/data/profile_repository.dart';
import 'package:sahyan/features/profile/presentation/profile_provider.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';

class MockProfileRepository implements ProfileRepository {
  UserModel user = const UserModel(
    id: 'user_123',
    name: 'Arjun Patel',
    phone: '+919876543210',
    email: 'arjun@example.com',
    city: 'Ahmedabad',
    bio: 'Daily carpooler',
    verificationStatus: UserVerificationStatus.verified,
    rating: 4.9,
    totalRides: 14,
    preferences: UserPreferences(
      notifications: true,
      allowSmoking: false,
      allowPets: false,
    ),
    emergencyContacts: [
      EmergencyContact(
        id: 'contact_1',
        name: 'Meera Patel',
        phone: '+919825012345',
        relationship: 'Sister',
      ),
    ],
  );

  @override
  Future<UserModel> getProfile() async {
    return user;
  }

  @override
  Future<UserModel> updateProfile({
    required String name,
    required String city,
    String? profilePhoto,
    String? bio,
  }) async {
    user = user.copyWith(
      name: name,
      city: city,
      profilePhoto: profilePhoto,
      bio: bio,
    );
    return user;
  }

  @override
  Future<UserPreferences> updatePreferences({
    required bool notifications,
    required bool allowSmoking,
    required bool allowPets,
  }) async {
    final newPrefs = UserPreferences(
      notifications: notifications,
      allowSmoking: allowSmoking,
      allowPets: allowPets,
    );
    user = user.copyWith(preferences: newPrefs);
    return newPrefs;
  }

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    return user.emergencyContacts;
  }

  @override
  Future<EmergencyContact> addEmergencyContact({
    required String name,
    required String phone,
    String? relationship,
  }) async {
    final contact = EmergencyContact(
      id: 'contact_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      relationship: relationship ?? 'Family',
    );
    user = user.copyWith(
      emergencyContacts: [...user.emergencyContacts, contact],
    );
    return contact;
  }

  @override
  Future<EmergencyContact> updateEmergencyContact({
    required String id,
    required String name,
    required String phone,
    String? relationship,
  }) async {
    final updated = EmergencyContact(
      id: id,
      name: name,
      phone: phone,
      relationship: relationship ?? 'Family',
    );
    user = user.copyWith(
      emergencyContacts: user.emergencyContacts
          .map((c) => c.id == id ? updated : c)
          .toList(),
    );
    return updated;
  }

  @override
  Future<void> deleteEmergencyContact(String id) async {
    user = user.copyWith(
      emergencyContacts: user.emergencyContacts
          .where((c) => c.id != id)
          .toList(),
    );
  }
}

void main() {
  group('UserModel & Sub-Models Unit Tests', () {
    test(
      'UserModel JSON deserialization with preferences and emergency contacts',
      () {
        final json = {
          'id': 'user_001',
          'name': 'Priya Shah',
          'phone': '+919876543210',
          'email': 'priya@example.com',
          'city': 'Surat',
          'bio': 'Commuter between Surat and Navsari',
          'isVerified': true,
          'rating': {'average': 4.8, 'count': 22},
          'role': 'user',
          'preferences': {
            'notifications': true,
            'allowSmoking': false,
            'allowPets': true,
          },
          'emergencyContacts': [
            {
              '_id': 'ec_01',
              'name': 'Amit Shah',
              'phone': '+919876500000',
              'relationship': 'Brother',
            },
          ],
        };

        final user = UserModel.fromJson(json);

        expect(user.id, 'user_001');
        expect(user.name, 'Priya Shah');
        expect(user.phone, '+919876543210');
        expect(user.city, 'Surat');
        expect(user.bio, 'Commuter between Surat and Navsari');
        expect(user.isVerified, true);
        expect(user.rating, 4.8);
        expect(user.totalRides, 22);
        expect(user.preferences.notifications, true);
        expect(user.preferences.allowSmoking, false);
        expect(user.preferences.allowPets, true);
        expect(user.emergencyContacts.length, 1);
        expect(user.emergencyContacts.first.name, 'Amit Shah');
        expect(user.emergencyContacts.first.relationship, 'Brother');
      },
    );

    test('UserModel copyWith modifies fields cleanly without side-effects', () {
      const initialUser = UserModel(
        id: 'u1',
        name: 'Initial Name',
        phone: '+919999999999',
        email: 'init@test.com',
        city: 'Ahmedabad',
        verificationStatus: UserVerificationStatus.verified,
        rating: 4.9,
        totalRides: 5,
      );

      final updatedUser = initialUser.copyWith(
        name: 'Updated Name',
        city: 'Vadodara',
        bio: 'Updated bio note',
      );

      expect(updatedUser.name, 'Updated Name');
      expect(updatedUser.city, 'Vadodara');
      expect(updatedUser.bio, 'Updated bio note');
      expect(updatedUser.phone, initialUser.phone);
      expect(updatedUser.email, initialUser.email);
    });
  });

  group('ProfileNotifier State Management Tests', () {
    late MockProfileRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockProfileRepository();
      container = ProviderContainer(
        overrides: [profileRepositoryProvider.overrideWithValue(mockRepo)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('updateProfile updates local state and authProvider user', () async {
      // Seed initial auth user
      container.read(authProvider.notifier).updateUser(mockRepo.user);

      final notifier = container.read(profileProvider.notifier);

      final result = await notifier.updateProfile(
        name: 'Arjun Updated Patel',
        city: 'Gandhinagar',
        bio: 'Tech commuter',
      );

      expect(result, true);
      final profileState = container.read(profileProvider);
      expect(profileState.isSaving, false);
      expect(profileState.successMessage, 'Profile updated successfully');

      final authUser = container.read(authProvider).user;
      expect(authUser?.name, 'Arjun Updated Patel');
      expect(authUser?.city, 'Gandhinagar');
      expect(authUser?.bio, 'Tech commuter');
    });

    test(
      'updatePreferences modifies notifications, smoking, and pets',
      () async {
        container.read(authProvider.notifier).updateUser(mockRepo.user);

        final notifier = container.read(profileProvider.notifier);

        final result = await notifier.updatePreferences(
          notifications: false,
          allowSmoking: true,
          allowPets: true,
        );

        expect(result, true);
        final authUser = container.read(authProvider).user;
        expect(authUser?.preferences.notifications, false);
        expect(authUser?.preferences.allowSmoking, true);
        expect(authUser?.preferences.allowPets, true);
      },
    );

    test('Emergency contacts CRUD via ProfileNotifier', () async {
      container.read(authProvider.notifier).updateUser(mockRepo.user);

      final notifier = container.read(profileProvider.notifier);

      // 1. Load contacts
      await notifier.loadEmergencyContacts();
      var state = container.read(profileProvider);
      expect(state.emergencyContacts.length, 1);
      expect(state.emergencyContacts.first.name, 'Meera Patel');

      // 2. Add contact
      final addResult = await notifier.addEmergencyContact(
        name: 'Ramesh Patel',
        phone: '+919876543299',
        relationship: 'Parent',
      );
      expect(addResult, true);
      state = container.read(profileProvider);
      expect(state.emergencyContacts.length, 2);
      final newContact = state.emergencyContacts.last;
      expect(newContact.name, 'Ramesh Patel');

      // 3. Update contact
      final updateResult = await notifier.updateEmergencyContact(
        id: newContact.id,
        name: 'Ramesh K. Patel',
        phone: '+919876543299',
        relationship: 'Father',
      );
      expect(updateResult, true);
      state = container.read(profileProvider);
      expect(state.emergencyContacts.last.name, 'Ramesh K. Patel');
      expect(state.emergencyContacts.last.relationship, 'Father');

      // 4. Delete contact
      final deleteResult = await notifier.deleteEmergencyContact(newContact.id);
      expect(deleteResult, true);
      state = container.read(profileProvider);
      expect(state.emergencyContacts.length, 1);
    });
  });
}
