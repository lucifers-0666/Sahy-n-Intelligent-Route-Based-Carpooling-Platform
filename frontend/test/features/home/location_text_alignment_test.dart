import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/features/home/presentation/widgets/hero_search_card.dart';
import 'package:sahyan/shared/models/location_model.dart';

void main() {
  group('HeroSearchCard Location Text Alignment & Layout Tests', () {
    late TextEditingController originCtrl;
    late TextEditingController destCtrl;

    setUp(() {
      originCtrl = TextEditingController();
      destCtrl = TextEditingController();
    });

    tearDown(() {
      originCtrl.dispose();
      destCtrl.dispose();
    });

    Widget buildTestHarness({
      required Widget child,
      Size size = const Size(390, 844),
      ThemeData? theme,
    }) {
      return MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('1. Empty fields display hint text without inner outline border', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          child: HeroSearchCard(
            originController: originCtrl,
            destinationController: destCtrl,
            onSwap: () {},
            onSelectCorridor: (_) {},
            selectedDate: DateTime(2026, 10, 20),
            selectedTime: const TimeOfDay(hour: 17, minute: 30),
            onPickDateTime: () {},
            selectedSeats: 2,
            onSeatsChanged: (_) {},
            onSearch: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enter pickup hub or address...'), findsOneWidget);
      expect(find.text('Where to? (Destination)...'), findsOneWidget);

      final originTextField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Enter pickup hub or address...'),
      );
      final destTextField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Where to? (Destination)...'),
      );

      expect(originTextField.decoration?.border, equals(InputBorder.none));
      expect(originTextField.decoration?.enabledBorder, equals(InputBorder.none));
      expect(originTextField.decoration?.focusedBorder, equals(InputBorder.none));
      expect(originTextField.decoration?.filled, isFalse);

      expect(destTextField.decoration?.border, equals(InputBorder.none));
      expect(destTextField.decoration?.enabledBorder, equals(InputBorder.none));
      expect(destTextField.decoration?.focusedBorder, equals(InputBorder.none));
      expect(destTextField.decoration?.filled, isFalse);

      expect(originTextField.textAlignVertical, equals(TextAlignVertical.center));
      expect(destTextField.textAlignVertical, equals(TextAlignVertical.center));
    });

    testWidgets('2. Short city names align vertically and clear button works', (tester) async {
      originCtrl.text = 'Rajkot';
      destCtrl.text = 'Nagpur City';

      await tester.pumpWidget(
        buildTestHarness(
          child: HeroSearchCard(
            originController: originCtrl,
            destinationController: destCtrl,
            onSwap: () {},
            onSelectCorridor: (_) {},
            selectedDate: DateTime(2026, 10, 20),
            selectedTime: const TimeOfDay(hour: 17, minute: 30),
            onPickDateTime: () {},
            selectedSeats: 2,
            onSeatsChanged: (_) {},
            onSearch: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rajkot'), findsOneWidget);
      expect(find.text('Nagpur City'), findsOneWidget);

      final clearButtons = find.byIcon(Icons.cancel_rounded);
      expect(clearButtons, findsNWidgets(2));

      await tester.tap(clearButtons.first);
      await tester.pumpAndSettle();

      expect(originCtrl.text, isEmpty);
      expect(find.text('Enter pickup hub or address...'), findsOneWidget);
      expect(find.text('Nagpur City'), findsOneWidget);
    });

    testWidgets('3. Long location names render without overflow on standard and narrow widths', (tester) async {
      final testLocations = [
        'Ahmedabad Junction',
        'Vadodara Central Railway Station',
        'Surat Central Ring Road',
        'Gandhinagar Infocity',
        'Sardar Vallabhbhai Patel International Airport Terminal 2',
      ];

      for (final loc in testLocations) {
        originCtrl.text = loc;
        destCtrl.text = 'Rajkot';

        // Standard Android screen width (390dp)
        await tester.pumpWidget(
          buildTestHarness(
            size: const Size(390, 844),
            child: HeroSearchCard(
              originController: originCtrl,
              destinationController: destCtrl,
              onSwap: () {},
              onSelectCorridor: (_) {},
              selectedDate: DateTime(2026, 10, 20),
              selectedTime: const TimeOfDay(hour: 17, minute: 30),
              onPickDateTime: () {},
              selectedSeats: 2,
              onSeatsChanged: (_) {},
              onSearch: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(loc), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Narrow Android screen width (320dp)
        await tester.pumpWidget(
          buildTestHarness(
            size: const Size(320, 640),
            child: HeroSearchCard(
              originController: originCtrl,
              destinationController: destCtrl,
              onSwap: () {},
              onSelectCorridor: (_) {},
              selectedDate: DateTime(2026, 10, 20),
              selectedTime: const TimeOfDay(hour: 17, minute: 30),
              onPickDateTime: () {},
              selectedSeats: 2,
              onSeatsChanged: (_) {},
              onSearch: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(loc), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('4. Focused field allows normal editing and cursor behavior without data modification', (tester) async {
      LocationModel? selectedOrigin;
      originCtrl.text = 'Vadodara Central Railway Station';

      await tester.pumpWidget(
        buildTestHarness(
          child: HeroSearchCard(
            originController: originCtrl,
            destinationController: destCtrl,
            onSwap: () {},
            onSelectCorridor: (_) {},
            onOriginLocationSelected: (loc) => selectedOrigin = loc,
            selectedDate: DateTime(2026, 10, 20),
            selectedTime: const TimeOfDay(hour: 17, minute: 30),
            onPickDateTime: () {},
            selectedSeats: 2,
            onSeatsChanged: (_) {},
            onSearch: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final originFinder = find.widgetWithText(TextField, 'Vadodara Central Railway Station');
      await tester.tap(originFinder);
      await tester.pumpAndSettle();

      final textFieldWidget = tester.widget<TextField>(originFinder);
      expect(textFieldWidget.focusNode?.hasFocus, isTrue);
      expect(textFieldWidget.cursorColor, equals(AppColors.deepEmerald));
      expect(textFieldWidget.cursorHeight, equals(18.0));
      expect(textFieldWidget.maxLines, equals(1));

      // Type to append text
      await tester.enterText(originFinder, 'Vadodara Central Railway Station Platform 1');
      await tester.pumpAndSettle();

      expect(originCtrl.text, equals('Vadodara Central Railway Station Platform 1'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. Selecting suggestion updates text controller and preserves coordinates', (tester) async {
      LocationModel? selectedModel;
      await tester.pumpWidget(
        buildTestHarness(
          child: HeroSearchCard(
            originController: originCtrl,
            destinationController: destCtrl,
            onSwap: () {},
            onSelectCorridor: (_) {},
            onOriginLocationSelected: (loc) => selectedModel = loc,
            selectedDate: DateTime(2026, 10, 20),
            selectedTime: const TimeOfDay(hour: 17, minute: 30),
            onPickDateTime: () {},
            selectedSeats: 2,
            onSeatsChanged: (_) {},
            onSearch: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap pickup to open suggestions
      await tester.tap(find.widgetWithText(TextField, 'Enter pickup hub or address...'));
      await tester.pumpAndSettle();

      expect(find.text('PICKUP CORRIDORS & HUBS'), findsOneWidget);

      // Select Ahmedabad Junction suggestion
      final suggestion = find.text('Ahmedabad Junction');
      expect(suggestion, findsWidgets);

      await tester.tap(suggestion.first);
      await tester.pumpAndSettle();

      expect(originCtrl.text, equals('Ahmedabad Junction'));
      expect(selectedModel, isNotNull);
      expect(selectedModel!.name, equals('Ahmedabad Junction'));
      expect(selectedModel!.city, equals('Ahmedabad'));
      expect(selectedModel!.latitude, closeTo(23.02, 0.05));
      expect(selectedModel!.longitude, closeTo(72.57, 0.05));
    });

    testWidgets('6. Swap button updates both controllers correctly without text overflow', (tester) async {
      originCtrl.text = 'Ahmedabad Junction';
      destCtrl.text = 'Vadodara Central Railway Station';

      await tester.pumpWidget(
        buildTestHarness(
          child: StatefulBuilder(
            builder: (context, setState) {
              return HeroSearchCard(
                originController: originCtrl,
                destinationController: destCtrl,
                onSwap: () {
                  final tmp = originCtrl.text;
                  originCtrl.text = destCtrl.text;
                  destCtrl.text = tmp;
                  setState(() {});
                },
                onSelectCorridor: (_) {},
                selectedDate: DateTime(2026, 10, 20),
                selectedTime: const TimeOfDay(hour: 17, minute: 30),
                onPickDateTime: () {},
                selectedSeats: 2,
                onSeatsChanged: (_) {},
                onSearch: () {},
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ahmedabad Junction'), findsOneWidget);
      expect(find.text('Vadodara Central Railway Station'), findsOneWidget);

      final swapButton = find.byIcon(Icons.swap_vert_rounded);
      await tester.tap(swapButton);
      await tester.pumpAndSettle();

      expect(originCtrl.text, equals('Vadodara Central Railway Station'));
      expect(destCtrl.text, equals('Ahmedabad Junction'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('7. Map picker button callback triggers when tapped', (tester) async {
      bool pickupMapTapped = false;
      bool destMapTapped = false;

      await tester.pumpWidget(
        buildTestHarness(
          child: HeroSearchCard(
            originController: originCtrl,
            destinationController: destCtrl,
            onSwap: () {},
            onSelectCorridor: (_) {},
            onTapPickup: () => pickupMapTapped = true,
            onTapDestination: () => destMapTapped = true,
            selectedDate: DateTime(2026, 10, 20),
            selectedTime: const TimeOfDay(hour: 17, minute: 30),
            onPickDateTime: () {},
            selectedSeats: 2,
            onSeatsChanged: (_) {},
            onSearch: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mapButtons = find.byIcon(Icons.map_outlined);
      expect(mapButtons, findsNWidgets(2));

      await tester.tap(mapButtons.first);
      await tester.pumpAndSettle();
      expect(pickupMapTapped, isTrue);

      await tester.tap(mapButtons.last);
      await tester.pumpAndSettle();
      expect(destMapTapped, isTrue);
    });
  });
}
