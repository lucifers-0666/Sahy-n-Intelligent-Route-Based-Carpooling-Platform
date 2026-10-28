import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/shared/models/user_model.dart';
import 'package:sahyan/features/profile/presentation/widgets/avatar_selection_sheet.dart';

void main() {
  group('Profile Photo & Default Avatar Tests', () {
    test('UserModel parses profilePhoto and fallback profileImage correctly', () {
      final jsonWithPhoto = {
        'id': 'u_101',
        'name': 'Kavya Shah',
        'phone': '+919876543210',
        'email': 'kavya@example.com',
        'profilePhoto': 'https://api.dicebear.com/7.x/adventurer/png?seed=AhmedabadCommuter',
        'city': 'Ahmedabad',
      };

      final user1 = UserModel.fromJson(jsonWithPhoto);
      expect(user1.profilePhoto, 'https://api.dicebear.com/7.x/adventurer/png?seed=AhmedabadCommuter');

      final jsonWithLegacyField = {
        'id': 'u_102',
        'name': 'Jayesh Dave',
        'phone': '+919876543211',
        'email': 'jayesh@example.com',
        'profileImage': 'https://api.dicebear.com/7.x/bottts/png?seed=SahyanDriverFleet',
        'city': 'Vadodara',
      };

      final user2 = UserModel.fromJson(jsonWithLegacyField);
      expect(user2.profilePhoto, 'https://api.dicebear.com/7.x/bottts/png?seed=SahyanDriverFleet');
    });

    test('UserModel handles null or empty profilePhoto with null safety', () {
      final jsonEmpty = {
        'id': 'u_103',
        'name': 'Ramesh Kumar',
        'phone': '+919876543212',
        'email': 'ramesh@example.com',
        'city': 'Surat',
      };

      final user = UserModel.fromJson(jsonEmpty);
      expect(user.profilePhoto, isNull);
    });

    test('PresetAvatar model holds valid labels and categories', () {
      const preset = PresetAvatar(
        id: 'executive',
        label: 'Executive Driver',
        url: 'https://api.dicebear.com/7.x/adventurer/png?seed=ExecutiveDriver',
        category: 'Driver',
      );

      expect(preset.id, 'executive');
      expect(preset.label, 'Executive Driver');
      expect(preset.url, contains('ExecutiveDriver'));
      expect(preset.category, 'Driver');
    });
  });
}

