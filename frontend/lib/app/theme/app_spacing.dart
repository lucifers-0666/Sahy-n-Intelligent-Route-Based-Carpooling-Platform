import 'package:flutter/material.dart';

/// Centralized layout and spacing tokens for the Sahyān design system.
/// Built on a mathematical 4dp/8dp modular scale as specified in the Stitch/Figma design guidelines.
abstract class AppSpacing {
  /// 4dp - Micro gaps, badge inner padding, border offsets
  static const double xs = 4.0;

  /// 8dp - Base unit, icon-to-text spacing, tight chips
  static const double sm = 8.0;

  /// 12dp - Medium gap, chip horizontal padding, compact list items
  static const double md = 12.0;

  /// 16dp - Standard base spacing, card padding, content margins
  static const double base = 16.0;

  /// 20dp - Generous mobile screen margin, major container padding
  static const double lg = 20.0;

  /// 24dp - Section spacing, header bottom margins
  static const double xl = 24.0;

  /// 32dp - Major section separation, vertical rhythm spacing
  static const double xxl = 32.0;

  /// 48dp - Hero spacing, empty state spacing
  static const double xxxl = 48.0;

  /// Standard screen container margin (20dp as defined in Stitch mobile design)
  static const double containerMargin = 20.0;

  /// Common EdgeInsets presets
  static const EdgeInsets paddingScreen = EdgeInsets.symmetric(
    horizontal: containerMargin,
    vertical: base,
  );

  static const EdgeInsets paddingScreenHorizontal = EdgeInsets.symmetric(
    horizontal: containerMargin,
  );

  static const EdgeInsets paddingCard = EdgeInsets.all(base);
  static const EdgeInsets paddingCardLarge = EdgeInsets.all(lg);
  static const EdgeInsets paddingCardDense = EdgeInsets.all(md);

  static const EdgeInsets paddingButton = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  static const EdgeInsets paddingButtonCompact = EdgeInsets.symmetric(
    horizontal: base,
    vertical: sm,
  );

  /// Common SizedBox gaps
  static const Widget gap4 = SizedBox(width: xs, height: xs);
  static const Widget gap8 = SizedBox(width: sm, height: sm);
  static const Widget gap12 = SizedBox(width: md, height: md);
  static const Widget gap16 = SizedBox(width: base, height: base);
  static const Widget gap20 = SizedBox(width: lg, height: lg);
  static const Widget gap24 = SizedBox(width: xl, height: xl);
  static const Widget gap32 = SizedBox(width: xxl, height: xxl);
  static const Widget gap48 = SizedBox(width: xxxl, height: xxxl);

  /// Horizontal SizedBox gaps
  static const Widget hGap4 = SizedBox(width: xs);
  static const Widget hGap8 = SizedBox(width: sm);
  static const Widget hGap12 = SizedBox(width: md);
  static const Widget hGap16 = SizedBox(width: base);
  static const Widget hGap20 = SizedBox(width: lg);
  static const Widget hGap24 = SizedBox(width: xl);

  /// Vertical SizedBox gaps
  static const Widget vGap4 = SizedBox(height: xs);
  static const Widget vGap8 = SizedBox(height: sm);
  static const Widget vGap12 = SizedBox(height: md);
  static const Widget vGap16 = SizedBox(height: base);
  static const Widget vGap20 = SizedBox(height: lg);
  static const Widget vGap24 = SizedBox(height: xl);
  static const Widget vGap32 = SizedBox(height: xxl);
  static const Widget vGap48 = SizedBox(height: xxxl);
}
