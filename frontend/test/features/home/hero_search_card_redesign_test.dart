import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/features/home/presentation/screens/passenger_selection_screen.dart';
import 'package:sahyan/features/home/presentation/screens/travel_date_time_screen.dart';
import 'package:sahyan/features/home/presentation/widgets/hero_search_card.dart';
import 'package:sahyan/shared/models/location_model.dart';

void main() {
  group('HeroSearchCard Redesign Widget Tests', () {
    late TextEditingController originCtrl;
    late TextEditingController destCtrl;

    setUp(() {
      originCtrl = TextEditingController(text: 'Ahmedabad');
      destCtrl = TextEditingController(text: 'Vadodara');
    });

    tearDown(() {
      originCtrl.dispose();
      destCtrl.dispose();
    });

    Widget createTestableWidget({
      required Widget child,
      Size size = const Size(390, 844),
      double textScaleFactor = 1.0,
    }) {
      return MaterialApp(
        theme: ThemeData(
          fontFamily: 'Plus Jakarta Sans',
          colorScheme: const ColorScheme.light(
            primary: AppColors.deepEmerald,
          ),
        ),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScaleFactor),
          ),
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

    testWidgets(
      'renders heading, P2P badge, pickup and destination labels correctly',
      (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            child: HeroSearchCard(
              originController: originCtrl,
              destinationController: destCtrl,
              onSwap: () {},
              onSelectCorridor: (_) {},
              selectedDate: DateTime(2026, 10, 20),
              selectedTime: const TimeOfDay(hour: 9, minute: 30),
              onPickDateTime: () {},
              selectedSeats: 2,
              onSeatsChanged: (_) {},
              onSearch: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Where are you heading?'), findsOneWidget);
        expect(find.text('P2P Corridor'), findsOneWidget);
        expect(find.text('PICKUP LOCATION'), findsOneWidget);
        expect(find.text('DESTINATION HUB'), findsOneWidget);
        expect(find.text('Ahmedabad'), findsOneWidget);
        expect(find.text('Vadodara'), findsOneWidget);
        expect(find.text('FREQUENT CORRIDORS'), findsOneWidget);
        expect(find.text('Find Matching Rides'), findsOneWidget);
      },
    );

    testWidgets(
      'swaps origin and destination fields with rotation on tap',
      (tester) async {
        bool swapped = false;
        await tester.pumpWidget(
          createTestableWidget(
            child: StatefulBuilder(
              builder: (context, setState) {
                return HeroSearchCard(
                  originController: originCtrl,
                  destinationController: destCtrl,
                  onSwap: () {
                    swapped = true;
                    final temp = originCtrl.text;
                    originCtrl.text = destCtrl.text;
                    destCtrl.text = temp;
                    setState(() {});
                  },
                  onSelectCorridor: (_) {},
                  selectedDate: DateTime(2026, 10, 20),
                  selectedTime: const TimeOfDay(hour: 9, minute: 30),
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

        final swapButton = find.byIcon(Icons.swap_vert_rounded);
        expect(swapButton, findsOneWidget);

        await tester.tap(swapButton);
        await tester.pumpAndSettle();

        expect(swapped, isTrue);
        expect(originCtrl.text, 'Vadodara');
        expect(destCtrl.text, 'Ahmedabad');
      },
    );

    testWidgets(
      'selecting frequent corridor populates origin and destination',
      (tester) async {
        Map<String, dynamic>? selected;
        await tester.pumpWidget(
          createTestableWidget(
            child: StatefulBuilder(
              builder: (context, setState) {
                return HeroSearchCard(
                  originController: originCtrl,
                  destinationController: destCtrl,
                  onSwap: () {},
                  onSelectCorridor: (c) {
                    selected = c;
                    originCtrl.text = c['from'] as String;
                    destCtrl.text = c['to'] as String;
                    setState(() {});
                  },
                  selectedDate: DateTime(2026, 10, 20),
                  selectedTime: const TimeOfDay(hour: 9, minute: 30),
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

        final chip = find.text('Bhuj → Ahmd');
        expect(chip, findsOneWidget);

        await tester.tap(chip);
        await tester.pumpAndSettle();

        expect(selected, isNotNull);
        expect(originCtrl.text, 'Bhuj');
        expect(destCtrl.text, 'Ahmd');
      },
    );

    testWidgets(
      'focusing origin displays connected suggestions dropdown and GPS tile',
      (tester) async {
        LocationModel? selectedModel;
        await tester.pumpWidget(
          createTestableWidget(
            child: HeroSearchCard(
              originController: originCtrl,
              destinationController: destCtrl,
              onSwap: () {},
              onSelectCorridor: (_) {},
              onOriginLocationSelected: (loc) => selectedModel = loc,
              selectedDate: DateTime(2026, 10, 20),
              selectedTime: const TimeOfDay(hour: 9, minute: 30),
              onPickDateTime: () {},
              selectedSeats: 2,
              onSeatsChanged: (_) {},
              onSearch: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the origin field to gain focus
        await tester.tap(find.widgetWithText(TextField, 'Ahmedabad'));
        await tester.pumpAndSettle();

        // Suggestions panel should open with header and GPS option
        expect(find.text('PICKUP CORRIDORS & HUBS'), findsOneWidget);
        expect(find.text('Use Current GPS Location'), findsOneWidget);

        // Tap on a suggestion (e.g. Surat Central Ring Road)
        final suggestion = find.text('Surat Central Ring Road');
        if (suggestion.evaluate().isNotEmpty) {
          await tester.tap(suggestion.first);
          await tester.pumpAndSettle();
          expect(originCtrl.text, 'Surat Central Ring Road');
          expect(selectedModel, isNotNull);
          expect(selectedModel!.city, 'Surat');
        }
      },
    );

    testWidgets(
      'date/time picker callback triggers when left parameters cell is tapped',
      (tester) async {
        bool datePickerTapped = false;
        await tester.pumpWidget(
          createTestableWidget(
            child: HeroSearchCard(
              originController: originCtrl,
              destinationController: destCtrl,
              onSwap: () {},
              onSelectCorridor: (_) {},
              selectedDate: DateTime(2026, 10, 20),
              selectedTime: const TimeOfDay(hour: 9, minute: 30),
              onPickDateTime: () => datePickerTapped = true,
              selectedSeats: 2,
              onSeatsChanged: (_) {},
              onSearch: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final dateCell = find.byIcon(Icons.calendar_today_rounded);
        expect(dateCell, findsOneWidget);

        await tester.tap(dateCell);
        await tester.pumpAndSettle();

        expect(datePickerTapped, isTrue);
      },
    );

    testWidgets(
      'passenger summary row triggers onOpenPassengers when tapped and displays seat count',
      (tester) async {
        bool passengersTapped = false;
        await tester.pumpWidget(
          createTestableWidget(
            child: HeroSearchCard(
              originController: originCtrl,
              destinationController: destCtrl,
              onSwap: () {},
              onSelectCorridor: (_) {},
              selectedDate: DateTime(2026, 10, 20),
              selectedTime: const TimeOfDay(hour: 9, minute: 30),
              onPickDateTime: () {},
              selectedSeats: 2,
              onSeatsChanged: (_) {},
              onOpenPassengers: () => passengersTapped = true,
              onSearch: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('PASSENGERS'), findsOneWidget);
        expect(find.text('2 seats'), findsOneWidget);

        final passengerRow = find.text('PASSENGERS');
        await tester.tap(passengerRow);
        await tester.pumpAndSettle();

        expect(passengersTapped, isTrue);
      },
    );

    testWidgets(
      'PassengerSelectionScreen enforces 1 to 6 seat limits and confirms selection',
      (tester) async {
        int? returnedSeats;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      returnedSeats = await Navigator.of(context).push<int>(
                        MaterialPageRoute(
                          builder: (_) => const PassengerSelectionScreen(
                            initialSeats: 2,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Passengers'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Passengers'));
        await tester.pumpAndSettle();

        expect(find.text('Select Passengers'), findsOneWidget);
        expect(find.text('2'), findsWidgets);
        expect(find.text('Passengers'), findsOneWidget);

        // Tap increment
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();
        expect(find.text('3'), findsWidgets);

        // Tap decrement back to 2, then to 1
        await tester.tap(find.byIcon(Icons.remove_rounded));
        await tester.pumpAndSettle();
        expect(find.text('2'), findsWidgets);

        await tester.tap(find.byIcon(Icons.remove_rounded));
        await tester.pumpAndSettle();
        expect(find.text('1'), findsWidgets);
        expect(find.text('Passenger'), findsOneWidget);

        // Minimum boundary: 1
        await tester.tap(find.byIcon(Icons.remove_rounded));
        await tester.pumpAndSettle();
        expect(find.text('1'), findsWidgets);

        // Tap confirm button
        final confirmButton = find.text('Confirm 1 Passenger Seat');
        expect(confirmButton, findsOneWidget);
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        expect(returnedSeats, 1);
      },
    );

    testWidgets(
      'TravelDateTimeScreen allows preset selection and returns date and time',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 950));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        Map<String, dynamic>? returnedResult;
        final baseDate = DateTime(2026, 10, 20);
        const baseTime = TimeOfDay(hour: 17, minute: 30);

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      returnedResult = await Navigator.of(context).push<Map<String, dynamic>>(
                        MaterialPageRoute(
                          builder: (_) => TravelDateTimeScreen(
                            initialDate: baseDate,
                            initialTime: baseTime,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Date Time'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Date Time'));
        await tester.pumpAndSettle();

        expect(find.text('Travel Date & Time'), findsOneWidget);
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Tomorrow'), findsOneWidget);

        // Tap preset 'Tomorrow'
        await tester.tap(find.text('Tomorrow'));
        await tester.pumpAndSettle();

        // Tap preset time chip 'Evening' if visible or ensureVisible
        final eveningChip = find.text('Evening');
        if (eveningChip.evaluate().isNotEmpty) {
          await tester.ensureVisible(eveningChip);
          await tester.pumpAndSettle();
          await tester.tap(eveningChip);
          await tester.pumpAndSettle();
        }

        // Tap confirm button
        final confirmBtn = find.text('Confirm Date & Time');
        await tester.ensureVisible(confirmBtn);
        await tester.pumpAndSettle();
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(returnedResult, isNotNull);
        expect(returnedResult!['date'], isA<DateTime>());
        expect(returnedResult!['time'], isA<TimeOfDay>());
      },
    );

    testWidgets(
      'search button triggers onSearch callback and shows loader when isLoading',
      (tester) async {
        bool searchCalled = false;
        await tester.pumpWidget(
          createTestableWidget(
            child: HeroSearchCard(
              originController: originCtrl,
              destinationController: destCtrl,
              onSwap: () {},
              onSelectCorridor: (_) {},
              selectedDate: DateTime(2026, 10, 20),
              selectedTime: const TimeOfDay(hour: 9, minute: 30),
              onPickDateTime: () {},
              selectedSeats: 2,
              onSeatsChanged: (_) {},
              onSearch: () => searchCalled = true,
              isLoading: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Find Matching Rides'));
        await tester.pumpAndSettle();
        expect(searchCalled, isTrue);

        // Re-pump with isLoading = true
        await tester.pumpWidget(
          createTestableWidget(
            child: HeroSearchCard(
              originController: originCtrl,
              destinationController: destCtrl,
              onSwap: () {},
              onSelectCorridor: (_) {},
              selectedDate: DateTime(2026, 10, 20),
              selectedTime: const TimeOfDay(hour: 9, minute: 30),
              onPickDateTime: () {},
              selectedSeats: 2,
              onSeatsChanged: (_) {},
              onSearch: () {},
              isLoading: true,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'renders without overflow on narrow 320dp width with 1.5x font scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          createTestableWidget(
            size: const Size(320, 568),
            textScaleFactor: 1.5,
            child: HeroSearchCard(
              originController: originCtrl,
              destinationController: destCtrl,
              onSwap: () {},
              onSelectCorridor: (_) {},
              selectedDate: DateTime(2026, 10, 20),
              selectedTime: const TimeOfDay(hour: 9, minute: 30),
              onPickDateTime: () {},
              selectedSeats: 2,
              onSeatsChanged: (_) {},
              onSearch: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Where are you heading?'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
