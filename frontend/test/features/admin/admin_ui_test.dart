import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/features/admin/presentation/screens/admin_dashboard_screen.dart';

void main() {
  group('Phase 5: Web Admin Panel & Moderation Dashboard UI Tests', () {
    testWidgets('AdminDashboardScreen desktop layout renders sidebar and bento analytics cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Brand
      expect(find.text('SAHYĀN'), findsOneWidget);
      expect(find.text('ADMIN OS · MODERATION'), findsOneWidget);
      expect(find.textContaining('MongoDB Connected'), findsOneWidget);

      // Verify Bento Metric Cards
      expect(find.text('COMMUNITY MEMBERS'), findsOneWidget);
      expect(find.text('VERIFIED FLEET DRIVERS'), findsOneWidget);
      expect(find.text('ACTIVE CORRIDORS & TRIPS'), findsOneWidget);
      expect(find.text('ENVIRONMENTAL IMPACT'), findsOneWidget);
      expect(find.text('Corridor Operating Health'), findsOneWidget);
    });

    testWidgets('Driver Verifications tab displays queue, filter chips, and approves driver', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Driver Verifications tab via sidebar
      await tester.tap(find.text('Driver Verifications'));
      await tester.pumpAndSettle();

      // Check header and filter chips
      expect(find.text('Driver Verification Queue'), findsOneWidget);
      expect(find.text('Pending Review'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);

      // Verify applicant cards rendered
      expect(find.text('Rahul Varma'), findsOneWidget);
      expect(find.text('Approve'), findsWidgets);

      // Tap Approve button for first pending applicant
      await tester.tap(find.text('Approve').first);
      await tester.pumpAndSettle();

      // Status should update to APPROVED
      expect(find.text('APPROVED'), findsWidgets);
    });

    testWidgets('View Docs button opens verification document preview modal', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Driver Verifications
      await tester.tap(find.text('Driver Verifications'));
      await tester.pumpAndSettle();

      // Tap View Docs on an applicant
      expect(find.text('View Docs'), findsWidgets);
      await tester.tap(find.text('View Docs').first);
      await tester.pumpAndSettle();

      // Check modal content
      expect(find.textContaining('Verification Docs:'), findsOneWidget);
      expect(find.textContaining('Driving License'), findsWidgets);
      expect(find.textContaining('DigiLocker National Registry'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Verification Docs:'), findsNothing);
    });

    testWidgets('Ride Moderation tab displays corridor rides and cancel ride dialog', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Ride Moderation tab
      await tester.tap(find.text('Ride Moderation'));
      await tester.pumpAndSettle();

      expect(find.text('Ride Moderation Console'), findsOneWidget);
      expect(find.textContaining('SG Highway, Ahmedabad'), findsWidgets);
      expect(find.text('Cancel Ride'), findsWidgets);

      // Tap Cancel Ride on a scheduled ride
      await tester.tap(find.text('Cancel Ride').first);
      await tester.pumpAndSettle();

      expect(find.text('Cancel Ride via Admin Moderation'), findsOneWidget);
      expect(find.text('Confirm Cancellation'), findsOneWidget);

      // Confirm Cancellation
      await tester.tap(find.text('Confirm Cancellation'));
      await tester.pumpAndSettle();

      // Dialog dismissed and status updated
      expect(find.text('Cancel Ride via Admin Moderation'), findsNothing);
      expect(find.text('CANCELLED'), findsWidgets);
    });

    testWidgets('Safety & Reports tab displays incidents and resolves report', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Safety & Reports tab
      await tester.tap(find.text('Safety & Reports'));
      await tester.pumpAndSettle();

      expect(find.text('Safety & SOS Incident Center'), findsOneWidget);
      expect(find.text('Corridor Route Deviation Alert'), findsOneWidget);
      expect(find.text('Resolve Incident'), findsWidgets);

      // Tap Resolve Incident
      await tester.tap(find.text('Resolve Incident').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Resolve Report:'), findsOneWidget);
      expect(find.text('Confirm Resolution'), findsOneWidget);

      // Enter notes and confirm
      await tester.enterText(find.byType(TextField), 'Contacted highway patrol; corridor route verified.');
      await tester.tap(find.text('Confirm Resolution'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Resolve Report:'), findsNothing);
      expect(find.text('RESOLVED'), findsWidgets);
    });

    testWidgets('Mobile viewport renders Drawer and toggles navigation', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In mobile view, AppBar is present with drawer button
      expect(find.text('Sahyān Admin'), findsOneWidget);

      // Open drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('ADMIN OS · MODERATION'), findsOneWidget);
      expect(find.text('System Settings'), findsOneWidget);
    });
  });
}
