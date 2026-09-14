import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/features/home/presentation/screens/home_screen.dart';
import 'package:sahyan/features/messaging/domain/messaging_model.dart';
import 'package:sahyan/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:sahyan/features/messaging/presentation/screens/chat_detail_screen.dart';
import 'package:sahyan/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:sahyan/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:sahyan/features/profile/data/profile_repository.dart';
import 'package:sahyan/features/profile/presentation/profile_provider.dart';
import 'package:sahyan/features/trip/presentation/widgets/rate_trip_sheet.dart';
import 'package:sahyan/features/trip/presentation/widgets/sos_action_bottom_sheet.dart';
import 'package:sahyan/shared/models/user_model.dart';

class TestProfileNotifier extends StateNotifier<ProfileState> implements ProfileNotifier {
  TestProfileNotifier(super.state);

  @override
  ProfileRepository get repository => throw UnimplementedError();

  @override
  Ref get ref => throw UnimplementedError();

  @override
  void clearMessages() {}

  @override
  Future<bool> updateProfile({required String name, required String city, String? profilePhoto, String? bio}) async => true;

  @override
  Future<bool> updatePreferences({required bool notifications, required bool allowSmoking, required bool allowPets}) async => true;

  @override
  Future<void> loadEmergencyContacts() async {}

  @override
  Future<bool> addEmergencyContact({required String name, required String phone, String? relationship}) async => true;

  @override
  Future<bool> updateEmergencyContact({required String id, required String name, required String phone, String? relationship}) async => true;

  @override
  Future<bool> deleteEmergencyContact(String id) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 4: In-App Messaging & Quick Responses Tests', () {
    testWidgets('ChatDetailScreen renders corridor header, quick chips, and sends message', (tester) async {
      final testConv = Conversation(
        id: 'test-conv-1',
        bookingId: 'test-booking-1',
        participantName: 'Karan Patel',
        participantRole: 'Driver',
        routeSummary: 'Ahmedabad to Vadodara',
        lastMessage: 'Ready at pickup point',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        phone: '+91 98765 43210',
      );

      final container = ProviderContainer(
        overrides: [
          messagingProvider.overrideWith(
            (ref) => MessagingNotifier(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: ChatDetailScreen(initialConversation: testConv),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and corridor info
      expect(find.text('Karan Patel'), findsOneWidget);
      expect(find.textContaining('Ahmedabad to Vadodara'), findsWidgets);
      expect(find.byIcon(Icons.phone_outlined), findsOneWidget);

      // Check quick reply chips exist
      expect(find.text('I have reached the pickup point'), findsOneWidget);
      expect(find.text('Running 5 mins late'), findsOneWidget);
      expect(find.text('Where are you waiting?'), findsOneWidget);

      // Tap a quick reply chip to send
      await tester.tap(find.text('I have reached the pickup point'));
      await tester.pumpAndSettle();

      // Check that message bubble was created in stream
      expect(find.text('I have reached the pickup point'), findsWidgets);
    });

    testWidgets('ChatDetailScreen message field text input sends custom message', (tester) async {
      final container = ProviderContainer(
        overrides: [
          messagingProvider.overrideWith(
            (ref) => MessagingNotifier(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ChatDetailScreen(conversationId: 'conv-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter text and tap send button
      await tester.enterText(find.byType(TextField), 'See you at the toll gate!');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('See you at the toll gate!'), findsOneWidget);
    });
  });

  group('Phase 4: Post-Trip Rating & Reviews Sheet Tests', () {
    testWidgets('RateTripSheet renders 5 stars, toggles feedback tags, and submits', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => Center(
                  child: ElevatedButton(
                    onPressed: () => RateTripSheet.show(ctx, driverName: 'Karan Patel'),
                    child: const Text('Rate Trip'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.text('Rate Trip'));
      await tester.pumpAndSettle();

      // Verify header and 5 stars
      expect(find.text('Rate Your Experience'), findsOneWidget);
      expect(find.textContaining('Karan Patel'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));

      // Check tags
      expect(find.text('Punctual'), findsOneWidget);
      expect(find.text('Smooth Driving'), findsOneWidget);
      expect(find.text('Clean Vehicle'), findsOneWidget);

      // Select another tag
      await tester.tap(find.text('Polite'));
      await tester.pumpAndSettle();

      // Enter optional comment
      await tester.enterText(find.byType(TextField), 'Very smooth highway drive.');
      await tester.pumpAndSettle();

      // Tap Submit Review
      await tester.tap(find.text('Submit Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Sheet dismissed
      expect(find.text('Rate Your Experience'), findsNothing);
    });
  });

  group('Phase 4: Emergency SOS & Safety Ring Tests', () {
    testWidgets('SosActionBottomSheet renders emergency 112, 1800-SAHYAN, and primary contact', (tester) async {
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            (ref) => TestProfileNotifier(
              const ProfileState(
                emergencyContacts: [
                  EmergencyContact(
                    id: 'ec1',
                    name: 'Ramesh Patel',
                    phone: '+91 98222 33445',
                    relationship: 'Father',
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => Center(
                  child: ElevatedButton(
                    onPressed: () => SosActionBottomSheet.show(ctx),
                    child: const Text('Open SOS'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open SOS'));
      await tester.pumpAndSettle();

      // Check Emergency SOS Title
      expect(find.text('Emergency SOS & Safety'), findsOneWidget);
      // Check 112 National Police
      expect(find.textContaining('112'), findsOneWidget);
      // Check Sahyān Helpline
      expect(find.textContaining('1800-SAHYAN'), findsOneWidget);
      // Check Primary Contact
      expect(find.textContaining('Ramesh Patel (Father)'), findsOneWidget);
      // Check Share Live Trip
      expect(find.text('Share Live Trip Corridor'), findsOneWidget);

      // Tap Call 112
      await tester.tap(find.textContaining('112'));
      await tester.pump();
      expect(find.textContaining('Dialing 112'), findsOneWidget);
    });
  });

  group('Phase 4: In-App Notifications Hub Tests', () {
    testWidgets('HomeScreen notification bell displays dynamic unread count badge', (tester) async {
      final container = ProviderContainer(
        overrides: [
          notificationsProvider.overrideWith(
            (ref) => NotificationsNotifier(
              repository: null,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Notification bell should display badge with count 3
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('NotificationsScreen renders category filter chips and swipe dismisses notification', (tester) async {
      final container = ProviderContainer(
        overrides: [
          notificationsProvider.overrideWith(
            (ref) => NotificationsNotifier(
              repository: null,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check filter categories
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Rides'), findsOneWidget);
      expect(find.text('Safety'), findsOneWidget);

      // Verify initial notifications
      expect(find.text('Booking Approved'), findsOneWidget);
      expect(find.text('Driver Started Boarding'), findsOneWidget);

      // Filter by Bookings
      await tester.tap(find.text('Bookings'));
      await tester.pumpAndSettle();
      expect(find.text('Booking Approved'), findsOneWidget);

      // Back to All
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Dismiss first notification with swipe
      await tester.drag(find.text('Booking Approved'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Verify dismissed
      expect(find.text('Booking Approved'), findsNothing);
    });
  });
}
