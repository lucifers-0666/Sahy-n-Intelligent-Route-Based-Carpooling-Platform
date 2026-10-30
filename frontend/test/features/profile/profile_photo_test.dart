import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sahyan/core/utils/profile_image_helper.dart';
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

    test('UserModel accepts and preserves Base64 Data URI profilePhoto', () {
      const dummyDataUri = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP...';
      final json = {
        'id': 'u_104',
        'name': 'Arjun Patel',
        'phone': '+919876543210',
        'email': 'arjun@example.com',
        'profilePhoto': dummyDataUri,
        'city': 'Ahmedabad',
      };

      final user = UserModel.fromJson(json);
      expect(user.profilePhoto, dummyDataUri);
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

    test('getProfileImageProvider handles Network, Base64, and empty sources safely', () {
      // 1. Network Image
      final networkProvider = getProfileImageProvider('https://example.com/avatar.jpg');
      expect(networkProvider, isA<NetworkImage>());

      // 2. Base64 Data URI
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4]);
      final base64String = 'data:image/jpeg;base64,${base64Encode(sampleBytes)}';
      final memoryProvider = getProfileImageProvider(base64String);
      expect(memoryProvider, isA<MemoryImage>());

      // 3. Null and empty strings
      expect(getProfileImageProvider(null), isNull);
      expect(getProfileImageProvider(''), isNull);
      expect(getProfileImageProvider('   '), isNull);
    });

    test('processAndCropImageBytes crops and resizes raw image to data URI', () async {
      // Create a test 100x80 image
      final testImg = img.Image(width: 100, height: 80);
      img.fill(testImg, color: img.ColorRgb8(11, 93, 75)); // Sahyan Emerald
      final rawJpg = Uint8List.fromList(img.encodeJpg(testImg));

      // Test standard crop (target 300px)
      final croppedUri = await processAndCropImageBytes(
        rawBytes: rawJpg,
        settings: const CropSettings(
          targetSize: 300,
          scale: 1.2,
          panOffset: Offset(0.1, 0.1),
          rotationDegrees: 0,
        ),
      );

      expect(croppedUri, isNotNull);
      expect(croppedUri!, startsWith('data:image/jpeg;base64,'));

      // Decode the result to verify dimensions
      final commaIndex = croppedUri.indexOf(',');
      final outputBytes = base64Decode(croppedUri.substring(commaIndex + 1));
      final decoded = img.decodeImage(outputBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 300);
      expect(decoded.height, 300);

      // Test high-resolution crop (target 600px)
      final highResUri = await processAndCropImageBytes(
        rawBytes: rawJpg,
        settings: const CropSettings(
          targetSize: 600,
          scale: 1.0,
          rotationDegrees: 90,
        ),
      );

      expect(highResUri, isNotNull);
      final highResBytes = base64Decode(highResUri!.substring(highResUri.indexOf(',') + 1));
      final decodedHighRes = img.decodeImage(highResBytes);
      expect(decodedHighRes, isNotNull);
      expect(decodedHighRes!.width, 600);
      expect(decodedHighRes.height, 600);
    });
  });
}
