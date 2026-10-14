import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/app.dart';

void main() {
  testWidgets('SahyanApp initializes successfully smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SahyanApp()));

    expect(find.byType(MaterialApp), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
