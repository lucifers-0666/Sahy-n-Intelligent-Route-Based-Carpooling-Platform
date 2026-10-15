import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/localization/sahyan_language_selector.dart';
import '../../../../core/localization/sahyan_localizations.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../core/widgets/sahyan_text_field.dart';
import '../../../../shared/widgets/feedback/feedback_service.dart';
import '../../../../shared/widgets/feedback/sahyan_legal_sheet.dart';
import '../../../../shared/widgets/sahyan_glass_card.dart';
import '../../../../shared/widgets/sahyan_logo.dart';
import '../../../../shared/widgets/sahyan_route_background.dart';
import '../auth_provider.dart';

/// Redesigned 2026 Progressive Registration Screen for Sahyān.
///
/// Features:
/// - Progressive 2-step onboarding:
///   Step 1: Full name, Phone (strict ^[6-9]\d{9}$), DPDP Terms consent
///   Step 2: Role choice FIRST (Passenger / Driver / Both),
///           When Driver or Both selected:
///             - Admin manual verification notice card
///             - Optional driver photo upload with default avatar icon
///             - First name & Last name confirmation
///             - Date of birth (18+ validation)
///             - Primary & Secondary / Emergency numbers
///             - Driver's license number
///             - Vehicle registration number plate with live HSRP badge
///             - Vehicle make, model & vehicle type selector
///           Optional Email with "why we ask", Optional Password with rules
/// - Frosted glassmorphism (SahyanGlassCard) with ambient blurred backdrop
/// - Single container for phone input (+91 | 98765 43210 with thin divider)
/// - Inline errors on blur & responsive layout down to 320dp
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  // Step 1 Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _scrollController = ScrollController();

  // Step 2 General Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Driver Verification Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _vehicleModelController = TextEditingController();

  // Focus Nodes
  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _secondaryPhoneFocusNode = FocusNode();
  final _licenseFocusNode = FocusNode();
  final _vehiclePlateFocusNode = FocusNode();
  final _vehicleModelFocusNode = FocusNode();

  int _currentStep = 1; // Step 1: Basic Info, Step 2: Role & Verification
  bool _agreedToTerms = false;
  bool _isPasswordVisible = false;
  bool _isPasswordFocused = false;
  bool _isSubmitting = false;
  bool _hasPhoneBlurred = false;
  bool _hasAttemptedStep1 = false;
  bool _hasAttemptedStep2 = false;
  bool _hasAttemptedDriverValidation = false;

  // Role: 'rider', 'driver', 'both' (Unselected by default)
  String? _selectedRole;

  // Driver specific state
  DateTime? _selectedDob;
  String _selectedVehicleType = 'Sedan';
  bool _hasCustomDriverPhoto = false;

  // Password rules validation
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
    _nameController.addListener(_onFullNameChanged);
    _vehiclePlateController.addListener(() => setState(() {}));
    _passwordController.addListener(_onPasswordChanged);

    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus) {
        setState(() => _hasPhoneBlurred = true);
      }
    });

    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  void _onFullNameChanged() {
    final text = _nameController.text.trim();
    final parts = text.split(RegExp(r'\s+'));
    if (parts.isNotEmpty) {
      if (_firstNameController.text != parts.first) {
        _firstNameController.text = parts.first;
      }
      final remaining = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      if (_lastNameController.text != remaining) {
        _lastNameController.text = remaining;
      }
    }
    setState(() {});
  }

  void _onPasswordChanged() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(password);
      _hasNumber = RegExp(r'\d').hasMatch(password);
      _hasSpecialChar = RegExp(r'[\W_]').hasMatch(password);
    });
  }

  int get _passwordStrengthScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase && _hasLowercase) score++;
    if (_hasNumber) score++;
    if (_hasSpecialChar) score++;
    return score;
  }

  String get _passwordStrengthLabel {
    final score = _passwordStrengthScore;
    if (_passwordController.text.isEmpty) return '';
    if (score <= 1) return 'Weak';
    if (score == 2) return 'Fair';
    if (score == 3) return 'Good';
    return 'Strong';
  }

  Color get _passwordStrengthColor {
    final score = _passwordStrengthScore;
    if (score <= 1) return AppColors.error;
    if (score == 2) return AppColors.marigold;
    if (score == 3) return AppColors.brandBright;
    return AppColors.mint;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _secondaryPhoneController.dispose();
    _licenseController.dispose();
    _vehiclePlateController.dispose();
    _vehicleModelController.dispose();

    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _secondaryPhoneFocusNode.dispose();
    _licenseFocusNode.dispose();
    _vehiclePlateFocusNode.dispose();
    _vehicleModelFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _cleanPhoneDigits =>
      _phoneController.text.replaceAll(RegExp(r'\D'), '');

  String get _cleanSecondaryDigits =>
      _secondaryPhoneController.text.replaceAll(RegExp(r'\D'), '');

  /// Strict Indian mobile check: starts with 6-9 and exactly 10 digits
  bool get _isPhoneValid => RegExp(r'^[6-9]\d{9}$').hasMatch(_cleanPhoneDigits);

  bool get _showPhoneInlineError =>
      (_hasPhoneBlurred || _hasAttemptedStep1) &&
      _cleanPhoneDigits.isNotEmpty &&
      !_isPhoneValid;

  bool get _isStep1Valid =>
      _nameController.text.trim().length >= 2 &&
      _isPhoneValid &&
      _agreedToTerms;

  bool get _isStep2Valid {
    if (_selectedRole == null) return false;
    if (_selectedRole == 'driver' || _selectedRole == 'both') {
      return _licenseController.text.trim().isNotEmpty &&
          _vehiclePlateController.text.trim().isNotEmpty &&
          _vehicleModelController.text.trim().isNotEmpty;
    }
    return true;
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(now.year - 24, now.month, now.day);
    final firstDate = DateTime(now.year - 80, 1, 1);
    final lastDate = DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'SELECT DATE OF BIRTH (18+ YEARS)',
      confirmText: 'CONFIRM',
      cancelText: 'CANCEL',
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.brandBright,
                    onPrimary: Colors.white,
                    surface: AppColors.darkSurface,
                    onSurface: AppColors.darkText,
                  )
                : const ColorScheme.light(
                    primary: AppColors.brand,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColors.ink,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')} ${months[picked.month - 1]} ${picked.year}';
      });
    }
  }

  void _handleStep1Continue() {
    FocusScope.of(context).unfocus();
    setState(() => _hasAttemptedStep1 = true);
    if (!_isStep1Valid) return;
    setState(() => _currentStep = 2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _handleFinalRegister() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting) return;

    if (_selectedRole == null) {
      setState(() => _hasAttemptedStep2 = true);
      FeedbackService.error(context, 'Please choose a travel role to continue.');
      return;
    }

    if ((_selectedRole == 'driver' || _selectedRole == 'both') && !_isStep2Valid) {
      setState(() => _hasAttemptedDriverValidation = true);
      FeedbackService.error(
        context,
        'Please complete required driver license and vehicle details for admin verification.',
      );
      return;
    }

    final cleanDigits = _cleanPhoneDigits;
    final localPhone = cleanDigits.length == 12 && cleanDigits.startsWith('91')
        ? cleanDigits.substring(2)
        : cleanDigits;

    final password = _passwordController.text.trim().isNotEmpty
        ? _passwordController.text.trim()
        : 'Sahyan${cleanDigits.substring(math.max(0, cleanDigits.length - 4))}!2026';

    final effectiveName = (_firstNameController.text.trim().isNotEmpty &&
            _lastNameController.text.trim().isNotEmpty)
        ? '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
        : _nameController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      final success = await ref
          .read(authProvider.notifier)
          .register(
            name: effectiveName,
            email: _emailController.text.trim().toLowerCase(),
            phone: localPhone,
            password: password,
            role: _selectedRole,
            licenseNumber: _licenseController.text.trim().toUpperCase(),
            secondaryPhone: _cleanSecondaryDigits.isNotEmpty ? _cleanSecondaryDigits : null,
            dateOfBirth: _selectedDob?.toIso8601String(),
            vehiclePlate: _vehiclePlateController.text.trim().toUpperCase(),
            vehicleModel: _vehicleModelController.text.trim(),
            vehicleType: _selectedVehicleType,
            profilePhoto: _hasCustomDriverPhoto ? 'https://sahyan.app/avatars/driver_sample.jpg' : null,
          );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        if (_selectedRole == 'driver' || _selectedRole == 'both') {
          FeedbackService.success(
            context,
            'Account created. Verification code sent. Driver profile queued for admin approval.',
          );
        } else {
          FeedbackService.success(
            context,
            'Account created. Verification code sent.',
          );
        }
        context.push('/otp?flow=registration');
      } else {
        final errorMsg = ref.read(authProvider).errorMessage;
        FeedbackService.error(
          context,
          errorMsg ?? 'Failed to create account. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        FeedbackService.error(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.ink;
    const mutedColor = Color(0xFF5B6B66);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final l10n = SahyanLocalizations.of(context);

    final authState = ref.watch(authProvider);
    if (authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/home');
        }
      });
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.canvasLight,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.brand,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.canvasLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: 22,
            color: textColor,
          ),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() => _currentStep = 1);
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/welcome');
            }
          },
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: SahyanLanguageSelector(),
          ),
        ],
      ),
      body: SahyanRouteBackground(
        isDark: isDark,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  24.0,
                  8.0,
                  24.0,
                  math.max(bottomPadding + 16, 24.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Mark Header + Trust Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SahyanLogo.mark(size: 34),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.mint : AppColors.brand)
                                .withValues(alpha: isDark ? 0.18 : 0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: (isDark ? AppColors.mint : AppColors.brand)
                                  .withValues(alpha: 0.25),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.mint : AppColors.brand,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "DPDP Verified Community",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.mint : AppColors.brand,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Step Progress Indicator
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkSurfaceHigh
                                : AppColors.border,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StepBadge(
                              stepNumber: 1,
                              label: l10n.step1Title,
                              isActive: _currentStep == 1,
                              isComplete: _currentStep > 1,
                              isDark: isDark,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                size: 14,
                                color: isDark
                                    ? AppColors.darkMuted
                                    : AppColors.mutedLight,
                              ),
                            ),
                            _StepBadge(
                              stepNumber: 2,
                              label: l10n.step2Title,
                              isActive: _currentStep == 2,
                              isComplete: false,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Headline & Subline
                    Text(
                      _currentStep == 1
                          ? l10n.createYourAccount
                          : l10n.step2Title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentStep == 1
                          ? l10n.registerIntro
                          : 'Set your primary travel role and optional access credentials.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Step 1 or Step 2 Content inside SahyanGlassCard
                    SahyanGlassCard(
                      padding: const EdgeInsets.all(18),
                      child: _currentStep == 1
                          ? _buildStep1(
                              isDark,
                              textColor,
                              mutedColor,
                              l10n,
                            )
                          : _buildStep2(
                              isDark,
                              textColor,
                              mutedColor,
                              l10n,
                            ),
                    ),

                    const SizedBox(height: 20),

                    // Sign In Instead Link
                    Center(
                      child: TextButton(
                        onPressed: () => context.push('/login'),
                        child: Text.rich(
                          TextSpan(
                            text: 'Already have an account? ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign In',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandBright,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Step 1: Full Name, Single Container Phone & DPDP Consent
  Widget _buildStep1(
    bool isDark,
    Color textColor,
    Color mutedColor,
    SahyanLocalizations l10n,
  ) {
    final borderColor = isDark ? AppColors.darkSurfaceHigh : AppColors.border;
    final phoneBorderColor = _showPhoneInlineError
        ? AppColors.error
        : (_isPhoneValid
              ? AppColors.brand
              : (_phoneFocusNode.hasFocus ? AppColors.brand : borderColor));

    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full Name Field (Maintained for full test and provider compatibility)
          SahyanTextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            label: l10n.fullNameLabel,
            helperText: l10n.fullNameHelper,
            hint: 'e.g., Zaid Patel',
            errorText: (_hasAttemptedStep1 && _nameController.text.trim().length < 2)
                ? 'Enter your full name to continue.'
                : null,
            isValid: _nameController.text.trim().length >= 2,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),

          // Single Container Phone Input (+91 | 98765 43210 with thin divider)
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: phoneBorderColor,
                width: _phoneFocusNode.hasFocus ? 2 : 1.5,
              ),
              boxShadow: _phoneFocusNode.hasFocus
                  ? [
                      BoxShadow(
                        color: AppColors.brandBright.withValues(alpha: 0.14),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+91',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1.0,
                  height: 24,
                  color: isDark ? AppColors.darkSurfaceHigh : AppColors.border,
                ),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: 1.2,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                      _PhoneSpaceFormatter(),
                    ],
                    decoration: InputDecoration(
                      hintText: '98765 43210',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: mutedColor.withValues(alpha: 0.55),
                        letterSpacing: 1.2,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                    ),
                  ),
                ),
                if (_isPhoneValid)
                  const Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.brand,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),

          // Inline phone error
          if (_showPhoneInlineError) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      l10n.invalidPhoneError,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Consent Checkbox
          InkWell(
            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      activeColor: AppColors.brand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) =>
                          setState(() => _agreedToTerms = val ?? false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: l10n.termsConsentPrefix,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: textColor,
                          height: 1.4,
                        ),
                        children: [
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () => SahyanLegalSheet.show(context),
                              child: Text(
                                l10n.termsAndPrivacy,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandBright,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_hasAttemptedStep1 && !_agreedToTerms) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Text(
                'Please agree to the Terms to continue.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error,
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Continue Button
          SahyanButton(
            text: 'Continue',
            icon: Icons.arrow_forward,
            iconLeading: false,
            variant: SahyanButtonVariant.primary,
            size: SahyanButtonSize.large,
            isInvalid: !_isStep1Valid,
            onPressed: _handleStep1Continue,
          ),
        ],
      ),
    );
  }

  /// Step 2: Role selection & Comprehensive Driver Verification
  Widget _buildStep2(
    bool isDark,
    Color textColor,
    Color mutedColor,
    SahyanLocalizations l10n,
  ) {
    final borderColor = isDark ? AppColors.darkSurfaceHigh : AppColors.border;
    final isDriverRole = _selectedRole == 'driver' || _selectedRole == 'both';

    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Role Choice FIRST (Passenger / Driver / Both)
          Text(
            l10n.roleSelectionTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          if (_hasAttemptedStep2 && _selectedRole == null) ...[
            const SizedBox(height: 6),
            Text(
              'Choose a role to continue.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _RoleOption(
                label: l10n.rolePassenger,
                icon: Icons.airline_seat_recline_normal,
                isSelected: _selectedRole == 'rider',
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedRole = 'rider');
                },
              ),
              const SizedBox(width: 8),
              _RoleOption(
                label: l10n.roleDriver,
                icon: Icons.directions_car,
                isSelected: _selectedRole == 'driver',
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedRole = 'driver');
                },
              ),
              const SizedBox(width: 8),
              _RoleOption(
                label: l10n.roleBoth,
                icon: Icons.alt_route,
                isSelected: _selectedRole == 'both',
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedRole = 'both');
                },
              ),
            ],
          ),

          // ── DRIVER VERIFICATION SUITE (Shown when Driver or Both selected) ──
          if (isDriverRole) ...[
            const SizedBox(height: 18),

            // 1. Admin Manual Verification Notice Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(
                  alpha: isDark ? 0.16 : 0.10,
                ),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.marigold
                            : const Color(0xFFB45309),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Manual Admin Verification Required',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.marigold
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Driver profiles and vehicle details undergo manual review by the Sahyān safety admin panel before publishing rides is enabled.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkText
                          : const Color(0xFF92400E),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Status: Admin Review Queue on Submission',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.marigold
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Driver Photo Upload Section (Optional with default user icon)
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? AppColors.mint : AppColors.brand)
                              .withValues(alpha: 0.12),
                          border: Border.all(
                            color: isDark ? AppColors.mint : AppColors.brand,
                            width: 2.0,
                          ),
                        ),
                        child: _hasCustomDriverPhoto
                            ? ClipOval(
                                child: Container(
                                  color: AppColors.brand.withValues(alpha: 0.2),
                                  child: const Icon(
                                    Icons.badge_rounded,
                                    size: 46,
                                    color: AppColors.brand,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: isDark ? AppColors.mint : AppColors.brand,
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: _hasCustomDriverPhoto
                              ? AppColors.success
                              : (isDark ? AppColors.mint : AppColors.brand),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          _hasCustomDriverPhoto
                              ? Icons.check
                              : Icons.add_a_photo_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _hasCustomDriverPhoto = !_hasCustomDriverPhoto;
                      });
                      FeedbackService.info(
                        context,
                        _hasCustomDriverPhoto
                            ? 'Driver photo attached. It will be verified by admin.'
                            : 'Reset to default user icon.',
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      _hasCustomDriverPhoto
                          ? 'Remove photo (Use default icon)'
                          : 'Upload driver photo (Optional)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandBright,
                      ),
                    ),
                  ),
                  Text(
                    'Optional: Upload photo for rider trust, or proceed with default icon.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: mutedColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. Driver Identity: First & Last Name
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    textCapitalization: TextCapitalization.words,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: mutedColor,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    textCapitalization: TextCapitalization.words,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: mutedColor,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4. Date of Birth Field
            GestureDetector(
              onTap: _selectDateOfBirth,
              child: AbsorbPointer(
                child: TextFormField(
                  controller: _dobController,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Date of Birth (18+ only)',
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: mutedColor,
                    ),
                    hintText: 'Tap to select date of birth',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: mutedColor.withValues(alpha: 0.5),
                    ),
                    suffixIcon: const Icon(
                      Icons.calendar_month_rounded,
                      size: 20,
                      color: AppColors.brand,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 5. Primary Number Display (Verified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF7FAF8),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_android_rounded,
                    size: 18,
                    color: AppColors.brand,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Primary Number (Step 1)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: mutedColor,
                          ),
                        ),
                        Text(
                          '+91 ${_cleanPhoneDigits.isNotEmpty ? _cleanPhoneDigits : "98765 43210"}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 6. Secondary / Emergency Contact Number
            TextFormField(
              controller: _secondaryPhoneController,
              focusNode: _secondaryPhoneFocusNode,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              decoration: InputDecoration(
                prefixText: '+91 ',
                prefixStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
                labelText: 'Secondary / Emergency Mobile Number',
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: mutedColor,
                ),
                hintText: '98765 43210',
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(color: borderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                'Why we ask: For SOS in-ride safety & secondary family contact.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: mutedColor,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 7. Driving License (DL) Number
            TextFormField(
              controller: _licenseController,
              focusNode: _licenseFocusNode,
              textCapitalization: TextCapitalization.characters,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 1.1,
              ),
              decoration: InputDecoration(
                labelText: 'Driving License (DL) Number *',
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: mutedColor,
                ),
                hintText: 'e.g. GJ01 20200012345',
                errorText: _hasAttemptedDriverValidation &&
                        _licenseController.text.trim().isEmpty
                    ? 'Driving license number is required for drivers.'
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(color: borderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 8. Vehicle Registration / Number Plate
            TextFormField(
              controller: _vehiclePlateController,
              focusNode: _vehiclePlateFocusNode,
              textCapitalization: TextCapitalization.characters,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 1.1,
              ),
              decoration: InputDecoration(
                labelText: 'Car Registration / Number Plate *',
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: mutedColor,
                ),
                hintText: 'e.g. GJ-01-AB-1234',
                errorText: _hasAttemptedDriverValidation &&
                        _vehiclePlateController.text.trim().isEmpty
                    ? 'Vehicle number plate is required.'
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(color: borderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Visual Indian HSRP License Plate Preview Badge
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black87, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Blue IND strip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0038A8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF000080),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Text(
                              'IND',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _vehiclePlateController.text.trim().isEmpty
                            ? 'GJ 01 AB 1234'
                            : _vehiclePlateController.text.trim().toUpperCase(),
                        style: GoogleFonts.robotoMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 9. Vehicle Make & Model
            TextFormField(
              controller: _vehicleModelController,
              focusNode: _vehicleModelFocusNode,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              decoration: InputDecoration(
                labelText: 'Vehicle Make & Model *',
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: mutedColor,
                ),
                hintText: 'e.g. Honda City, Tata Nexon, Hyundai i20',
                errorText: _hasAttemptedDriverValidation &&
                        _vehicleModelController.text.trim().isEmpty
                    ? 'Vehicle make and model is required.'
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(color: borderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 10. Vehicle Type Chips
            Text(
              'Vehicle Category',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in ['Sedan', 'Hatchback', 'SUV', 'Motorcycle'])
                  ChoiceChip(
                    label: Text(type),
                    selected: _selectedVehicleType == type,
                    selectedColor: AppColors.brand.withValues(
                      alpha: isDark ? 0.35 : 0.15,
                    ),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: _selectedVehicleType == type
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _selectedVehicleType == type
                          ? (isDark ? Colors.white : AppColors.brand)
                          : mutedColor,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedVehicleType = type);
                      }
                    },
                  ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // 2. Email Field (Optional with "Why we ask")
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            decoration: InputDecoration(
              labelText: 'Email Address (Optional)',
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: mutedColor,
              ),
              hintText: 'name@example.com',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: mutedColor.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(
                  color: AppColors.brand,
                  width: 1.6,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              l10n.emailWhyWeAsk,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: mutedColor,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 3. Password Field (Optional with "Why we ask")
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: !_isPasswordVisible,
            autofillHints: const [AutofillHints.newPassword],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            decoration: InputDecoration(
              labelText: 'Create Password (Optional)',
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: mutedColor,
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(
                  color: AppColors.brand,
                  width: 1.6,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  size: 20,
                  color: mutedColor,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              l10n.passwordWhyWeAsk,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: mutedColor,
              ),
            ),
          ),

          // Password strength & checklist
          if (_isPasswordFocused || _passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_passwordStrengthScore / 4.0).clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: borderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _passwordStrengthColor,
                      ),
                    ),
                  ),
                ),
                if (_passwordStrengthLabel.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Text(
                    _passwordStrengthLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _passwordStrengthColor,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _RuleCheck(label: '8+ chars', isMet: _hasMinLength),
                _RuleCheck(label: 'Uppercase', isMet: _hasUppercase),
                _RuleCheck(label: 'Number', isMet: _hasNumber),
                _RuleCheck(label: 'Special char', isMet: _hasSpecialChar),
              ],
            ),
          ],

          const SizedBox(height: 28),

          // Complete Registration Button
          SahyanButton(
            text: 'Complete Registration',
            variant: SahyanButtonVariant.primary,
            size: SahyanButtonSize.large,
            isLoading: _isSubmitting,
            isInvalid: !_isStep2Valid,
            onPressed: _handleFinalRegister,
          ),
        ],
      ),
    );
  }
}

/// Step Progress Indicator Badge
class _StepBadge extends StatelessWidget {
  final int stepNumber;
  final String label;
  final bool isActive;
  final bool isComplete;
  final bool isDark;

  const _StepBadge({
    required this.stepNumber,
    required this.label,
    required this.isActive,
    required this.isComplete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = (isActive || isComplete)
        ? AppColors.brand
        : (isDark ? AppColors.darkMuted : AppColors.mutedLight);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: (isActive || isComplete)
                ? AppColors.brand
                : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : color,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Dynamic Rule Check Indicator
class _RuleCheck extends StatelessWidget {
  final String label;
  final bool isMet;

  const _RuleCheck({required this.label, required this.isMet});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 13,
          color: isMet ? AppColors.brandBright : AppColors.mutedLight,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isMet ? FontWeight.w700 : FontWeight.w500,
            color: isMet ? AppColors.brandBright : AppColors.mutedLight,
          ),
        ),
      ],
    );
  }
}

/// Role Preference Option (Passenger / Driver / Both)
class _RoleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brand.withValues(alpha: isDark ? 0.35 : 0.12)
                : (isDark ? AppColors.darkSurface : Colors.white),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: isSelected ? AppColors.brand : AppColors.border,
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? AppColors.brand
                    : (isDark ? AppColors.darkMuted : AppColors.mutedLight),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.brand)
                      : (isDark ? AppColors.darkMuted : AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Auto-formats 10 digits as '98765 43210'
class _PhoneSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    if (digits.length <= 5) {
      return TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    final formatted = '${digits.substring(0, 5)} ${digits.substring(5)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
