import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized Typography Scale for Sahyān.
/// Uses Plus Jakarta Sans as the unified primary font family throughout the app.
abstract class AppTypography {
  /// Display / Hero text for large branded headers (36sp, 800 ExtraBold)
  static TextStyle get displayHero => GoogleFonts.plusJakartaSans(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.deepForest,
    letterSpacing: -0.02,
    height: 1.2,
  );

  /// Screen titles for top-level pages (28sp, 700 Bold)
  static TextStyle get pageTitle => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.01,
    height: 1.25,
  );

  /// Backwards-compatible alias for pageTitle
  static TextStyle get screenTitle => GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  /// Section headings within screens (20sp, 700 Bold)
  static TextStyle get sectionHeader => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Standard Heading 3 alias
  static TextStyle get h3 => sectionHeader;

  /// Card titles within widgets (16sp, 600 SemiBold)
  static TextStyle get cardTitle => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Small bold body text
  static TextStyle get bodySmallBold => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  /// Field labels above input controls (14sp, 600 SemiBold)
  static TextStyle get fieldLabel => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Body large for prominent descriptive paragraphs (16sp, 500 Medium)
  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  /// Body medium for standard content and descriptions (14sp, 400 Regular)
  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Secondary / supporting text, subtitles, and hints (13sp, 400 Regular)
  static TextStyle get secondary => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  /// Backwards-compatible alias for bodySmall (13sp, 400 Regular)
  static TextStyle get bodySmall => secondary;

  /// Captions, helper text, and timestamps (12sp, 500 Medium)
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  /// Label caps for overlines and category tags (11sp, 700 Bold, uppercase tracking)
  static TextStyle get labelCaps => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 0.08,
    height: 1.2,
  );

  /// Buttons and primary call-to-action text (15sp, 600 SemiBold)
  static TextStyle get button => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 0.2,
  );

  /// Prominent OTP input digits (24sp, 700 Bold)
  static TextStyle get otpDigit => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.deepForest,
  );

  /// Validation feedback and error messages (12sp, 500 Medium)
  static TextStyle get validationMessage => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedRust,
    height: 1.25,
  );

  /// Badges and status pills (12sp, 600 SemiBold)
  static TextStyle get badge => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.deepForest,
  );
}
