import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/widgets/full_screen_route_map_sheet.dart';

void main() {
  const originLoc = LocationModel(
    name: 'Bhuj Bus Station',
    address: 'Station Road, Bhuj, Gujarat',
    city: 'Bhuj',
    latitude: 23.2420,
    longitude: 69.6669,
  );

  const destLoc = LocationModel(
    name: 'Ahmedabad ISKCON Cross Road',
    address: 'SG Highway, Ahmedabad, Gujarat',
    city: 'Ahmedabad',
    latitude: 23.0225,
    longitude: 72.5714,
  );

  Widget createWidgetUnderTest({
    List<LocationModel> stopovers = const [],
    double? distanceKm,
    String? corridorHighway,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: FullScreenRouteMapSheet(
          origin: originLoc,
          destination: destLoc,
          stopovers: stopovers,
          distanceKm: distanceKm,
          corridorHighway: corridorHighway,
        ),
      ),
    );
  }

  testWidgets('FullScreenRouteMapSheet renders origin, destination, and highway chips', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(
        distanceKm: 332.0,
        corridorHighway: 'NH 47 / NH 27 Corridor',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NH 47 / NH 27 Corridor'), findsOneWidget);
    expect(find.text('Bhuj Bus Station'), findsWidgets);
    expect(find.text('Ahmedabad ISKCON Cross Road'), findsWidgets);
    expect(find.text('332 km'), findsOneWidget);
  });

  testWidgets('FullScreenRouteMapSheet renders stopovers if present', (tester) async {
    const stopover = LocationModel(
      name: 'Morbi Toll Plaza',
      address: 'NH 27, Morbi Bypass, Gujarat',
      city: 'Morbi',
      latitude: 22.8173,
      longitude: 70.8378,
    );

    await tester.pumpWidget(
      createWidgetUnderTest(
        stopovers: const [stopover],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Morbi Toll Plaza'), findsOneWidget);
  });

  testWidgets('FullScreenRouteMapSheet close button pops route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  FullScreenRouteMapSheet.show(
                    context: context,
                    origin: originLoc,
                    destination: destLoc,
                  );
                },
                child: const Text('Open Map Sheet'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap to open full screen sheet
    await tester.tap(find.text('Open Map Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Highway Corridor Active'), findsOneWidget);

    // Tap Close button
    final closeBtn = find.byIcon(Icons.close_rounded);
    expect(closeBtn, findsOneWidget);
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();

    // Sheet should be dismissed
    expect(find.text('Open Map Sheet'), findsOneWidget);
    expect(find.text('Highway Corridor Active'), findsNothing);
  });
}
