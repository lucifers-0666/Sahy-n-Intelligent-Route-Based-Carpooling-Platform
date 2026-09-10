import 'package:flutter/material.dart';

/// Centralized corner radii tokens for the Sahyān design system.
/// Implements softly geometric curvature as defined in the Stitch/Figma design guidelines.
abstract class AppRadii {
  /// 4dp - Micro elements, inner highlights, badges
  static const double xs = 4.0;

  /// 8dp - Small tags, mini chips, indicator dots
  static const double sm = 8.0;

  /// 12dp - Standard buttons, input fields, compact cards
  static const double md = 12.0;

  /// 16dp - Standard cards, container sheets, route cards
  static const double lg = 16.0;

  /// 20dp - Hero cards, bottom sheets, floating nav bar
  static const double xl = 20.0;

  /// 24dp - Modal containers, elevated floating dialogs
  static const double xxl = 24.0;

  /// 9999dp - Fully rounded pill shape for status badges and chip selectors
  static const double full = 9999.0;

  /// Standard component aliases
  static const double card = lg;
  static const double button = md;

  /// BorderRadius presets
  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius radiusPill = BorderRadius.all(
    Radius.circular(full),
  );

  /// Top-only radius presets (for bottom sheets, sticky footers)
  static const BorderRadius topSheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );

  static const BorderRadius topSheetLarge = BorderRadius.vertical(
    top: Radius.circular(xxl),
  );
}
