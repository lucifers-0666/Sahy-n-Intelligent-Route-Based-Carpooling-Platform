import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/core/widgets/sahyan_text_field.dart';

Widget wrapWithTheme(Widget child, {bool isDark = false, double textScale = 1.0}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
          size: const Size(400, 800),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('SahyanTextField Style C Specification Tests', () {
    testWidgets('1. Rest state renders OutlineInputBorder with 1.5dp border and radius 14', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const SahyanTextField(
            label: 'Mobile number',
            hint: '98765 43210',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      final decoration = textField.decoration!;
      expect(decoration.labelText, 'Mobile number');
      expect(decoration.floatingLabelBehavior, FloatingLabelBehavior.always);
      expect(decoration.enabledBorder, isA<OutlineInputBorder>());

      final border = decoration.enabledBorder as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(14));
      expect(border.borderSide.width, 1.5);
      expect(border.borderSide.color, const Color(0xFF7C918A));
    });

    testWidgets('2. Focus state updates border to 2.0dp brand color', (tester) async {
      final focusNode = FocusNode();
      await tester.pumpWidget(
        wrapWithTheme(
          SahyanTextField(
            label: 'Email Address',
            hint: 'name@example.com',
            focusNode: focusNode,
          ),
        ),
      );
      await tester.pumpAndSettle();

      focusNode.requestFocus();
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      final decoration = textField.decoration!;
      final focusedBorder = decoration.focusedBorder as OutlineInputBorder;
      expect(focusedBorder.borderSide.width, 2.0);
      expect(focusedBorder.borderSide.color, const Color(0xFF0B5D4B));
      focusNode.dispose();
    });

    testWidgets('3. Error state displays error icon and message below the field', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const SahyanTextField(
            label: 'Mobile number',
            hint: '98765 43210',
            errorText: 'Enter a valid 10-digit Indian mobile number',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(
        find.text('Enter a valid 10-digit Indian mobile number'),
        findsOneWidget,
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      final errorBorder = textField.decoration!.errorBorder as OutlineInputBorder;
      expect(errorBorder.borderSide.color, const Color(0xFFC23B2F));
    });

    testWidgets('4. Valid state shows green checkmark suffix icon', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const SahyanTextField(
            label: 'Full Name',
            hint: 'Zaid Patel',
            isValid: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('5. Password field has eye toggle with 48dp touch target', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const SahyanTextField(
            label: 'Password',
            hint: 'Enter secure password',
            isPassword: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final toggleFinder = find.byType(IconButton);
      expect(toggleFinder, findsOneWidget);

      final iconButton = tester.widget<IconButton>(toggleFinder);
      expect(iconButton.constraints!.minWidth, greaterThanOrEqualTo(48.0));
      expect(iconButton.constraints!.minHeight, greaterThanOrEqualTo(48.0));

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('6. Phone field renders +91 prefix and divider inside the field', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const SahyanTextField(
            label: 'Mobile number',
            hint: '98765 43210',
            prefixText: '+91',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+91'), findsOneWidget);
    });

    testWidgets('7. Dark mode tokens apply with high contrast borders and fills', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const SahyanTextField(
            label: 'Mobile number',
            hint: '98765 43210',
          ),
          isDark: true,
        ),
      );
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      final decoration = textField.decoration!;
      final border = decoration.enabledBorder as OutlineInputBorder;
      expect(border.borderSide.color, const Color(0xFF5A6E67));
      expect(decoration.fillColor, const Color(0xB312302A));
    });
  });

  group('SahyanTextField Multilingual & Text Scale Tests', () {
    testWidgets('English label renders cleanly at 1.0x and 1.3x scale without clipping', (
      tester,
    ) async {
      for (final scale in [1.0, 1.3]) {
        await tester.pumpWidget(
          wrapWithTheme(
            const SahyanTextField(
              label: 'Mobile Number *',
              hint: '98765 43210',
              prefixText: '+91',
            ),
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Mobile Number *'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Gujarati label (મોબાઇલ નંબર) renders cleanly at 1.0x and 1.3x scale', (
      tester,
    ) async {
      for (final scale in [1.0, 1.3]) {
        await tester.pumpWidget(
          wrapWithTheme(
            const SahyanTextField(
              label: 'મોબાઇલ નંબર *',
              hint: '98765 43210',
              prefixText: '+91',
            ),
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('મોબાઇલ નંબર *'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Hindi label (मोबाइल नंबर) renders cleanly at 1.0x and 1.3x scale', (
      tester,
    ) async {
      for (final scale in [1.0, 1.3]) {
        await tester.pumpWidget(
          wrapWithTheme(
            const SahyanTextField(
              label: 'मोबाइल नंबर *',
              hint: '98765 43210',
              prefixText: '+91',
            ),
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('मोबाइल नंबर *'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
