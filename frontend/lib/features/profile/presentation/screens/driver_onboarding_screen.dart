import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/primary_button.dart';
import 'package:sahyan/core/widgets/verification_badge.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/profile/presentation/profile_provider.dart';
import 'package:sahyan/features/vehicles/presentation/vehicle_provider.dart';
import 'package:sahyan/features/profile/presentation/widgets/avatar_selection_sheet.dart';
import 'package:sahyan/core/utils/profile_image_helper.dart';
import 'package:sahyan/shared/models/user_model.dart';

class DriverOnboardingScreen extends ConsumerStatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  ConsumerState<DriverOnboardingScreen> createState() =>
      _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState
    extends ConsumerState<DriverOnboardingScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  final _licenseController = TextEditingController();
  final _expiryController = TextEditingController(text: '31/12/2035');

  bool _agreeSafetyPolicy = false;
  bool _agreeCostSharingOnly = false;
  String _selectedDocType = 'Smart Card DL';
  String? _uploadedDocName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null && user.licenseNumber.isNotEmpty) {
        _licenseController.text = user.licenseNumber;
      }
    });
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_agreeSafetyPolicy || !_agreeCostSharingOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the safety and cost-sharing compliance declarations to continue.',
          ),
          backgroundColor: AppColors.mutedRust,
        ),
      );
      return;
    }

    final success = await ref
        .read(profileProvider.notifier)
        .submitDriverApplication(
          licenseNumber: _licenseController.text.trim().toUpperCase(),
          licenseDocUrl:
              _uploadedDocName != null
                  ? 'https://cdn.sahyan.internal/dl/${_licenseController.text.trim().toUpperCase()}.pdf'
                  : null,
        );

    if (!mounted) return;

    if (success) {
      ref.read(authProvider.notifier).checkAuthStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Driver application submitted successfully. Verification is in progress.',
          ),
          backgroundColor: AppColors.primaryForest,
        ),
      );
    } else {
      final error = ref.read(profileProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to submit driver application.'),
          backgroundColor: AppColors.mutedRust,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final profileState = ref.watch(profileProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.warmBackground,
        appBar: AppBar(
          title: Text('Driver Verification', style: AppTypography.screenTitle),
          backgroundColor: AppColors.warmBackground,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: AppColors.primaryForest,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign In Required',
                  style: AppTypography.screenTitle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in or register to complete driver identity onboarding.',
                  style: AppTypography.secondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Sign In',
                  onPressed: () => context.push('/auth-entry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Status branch 1: Approved driver
    if (user.isDriverEligible) {
      return _buildApprovedView(context, user);
    }

    // Status branch 2: Application submitted and pending review
    if (user.isDriverSubmitted) {
      return _buildSubmittedView(context, user);
    }

    // Status branch 3: Application rejected with action required
    if (user.isDriverRejected && _currentStep == 0) {
      return _buildRejectedView(context, user);
    }

    // Status branch 4: Wizard onboarding (not_started / in_progress / re-applying)
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        title: Text('Driver Onboarding', style: AppTypography.screenTitle),
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWizardProgress(),
                const SizedBox(height: 20),
                if (_currentStep == 0)
                  _buildStepIdentity(user)
                else if (_currentStep == 1)
                  _buildStepLicence()
                else if (_currentStep == 2)
                  _buildStepVehicle(vehiclesAsync)
                else
                  _buildStepReview(user, vehiclesAsync),
                const SizedBox(height: 28),
                _buildStepActions(profileState.isSaving),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWizardProgress() {
    final stepLabels = ['Identity', 'Licence', 'Vehicle', 'Review'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(stepLabels.length, (index) {
          final isPast = _currentStep > index;
          final isCurrent = _currentStep == index;
          final circleColor =
              isPast
                  ? AppColors.primaryForest
                  : isCurrent
                  ? AppColors.deepForest
                  : AppColors.border;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleColor,
                  ),
                  child: Center(
                    child:
                        isPast
                            ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                            : Text(
                              '${index + 1}',
                              style: AppTypography.caption.copyWith(
                                color:
                                    isCurrent
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stepLabels[index],
                    style: AppTypography.caption.copyWith(
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color:
                          isCurrent
                              ? AppColors.deepForest
                              : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (index < stepLabels.length - 1)
                  Container(
                    width: 14,
                    height: 1,
                    color: AppColors.border,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepIdentity(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Step 1: Identity & Contact Confirmation',
          style: AppTypography.cardTitle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          'Sahyān requires phone-verified drivers to ensure passenger safety and platform accountability.',
          style: AppTypography.secondary,
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          color: AppColors.cardBackground,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.softForest,
                      backgroundImage: getProfileImageProvider(user.profilePhoto),
                      onBackgroundImageError:
                          (user.profilePhoto != null && user.profilePhoto!.isNotEmpty)
                              ? (exception, stackTrace) {}
                              : null,
                      child: (user.profilePhoto == null || user.profilePhoto!.isEmpty)
                          ? const Icon(Icons.person_rounded, size: 26, color: AppColors.primaryForest)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Driver Profile Photo', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            user.profilePhoto != null && user.profilePhoto!.isNotEmpty
                                ? 'Photo active for passenger pickup match'
                                : 'Choose a clear face photo or default avatar',
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final chosen = await AvatarSelectionSheet.show(
                          context,
                          currentUrl: user.profilePhoto,
                          userName: user.name,
                        );
                        if (chosen != null) {
                          await ref.read(profileProvider.notifier).updateProfile(
                            name: user.name,
                            city: user.city,
                            profilePhoto: chosen,
                          );
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const Divider(color: AppColors.border, height: 20),
                _buildInfoRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Full Name',
                  value: user.name,
                ),
                const Divider(color: AppColors.border, height: 20),
                _buildInfoRow(
                  icon: Icons.phone_android_rounded,
                  title: 'Mobile Phone',
                  value: user.phone,
                  trailing:
                      user.isVerified
                          ? const VerificationBadge(
                            isVerified: true,
                            label: 'Verified',
                          )
                          : TextButton(
                            onPressed: () => context.push('/otp'),
                            child: const Text('Verify Phone'),
                          ),
                ),
                const Divider(color: AppColors.border, height: 20),
                _buildInfoRow(
                  icon: Icons.location_city_rounded,
                  title: 'Base City',
                  value: user.city.isNotEmpty ? user.city : 'Gujarat Region',
                ),
                const Divider(color: AppColors.border, height: 20),
                _buildInfoRow(
                  icon: Icons.email_outlined,
                  title: 'Email Address',
                  value:
                      user.email.isNotEmpty
                          ? user.email
                          : 'Pending registration',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.softForest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryForest.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                color: AppColors.primaryForest,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your personal identity information is strictly protected under the DPDP Act. It is only visible to confirmed passengers on scheduled journeys.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.deepForest,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepLicence() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Step 2: Driving Licence Verification',
          style: AppTypography.cardTitle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          'Provide your valid Indian Driving Licence (LMV) number and documentation for administrative review.',
          style: AppTypography.secondary,
        ),
        const SizedBox(height: 16),
        Text(
          'Driving Licence Number (Required)',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _licenseController,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\s\-]')),
            LengthLimitingTextInputFormatter(18),
          ],
          decoration: InputDecoration(
            hintText: 'e.g. GJ01 2022 0001234',
            hintStyle: AppTypography.secondary.copyWith(color: AppColors.mutedSage),
            prefixIcon: const Icon(
              Icons.badge_outlined,
              color: AppColors.primaryForest,
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryForest,
                width: 1.5,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Driving licence number is required';
            }
            final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
            if (cleaned.length < 8) {
              return 'Licence number must be at least 8 alphanumeric characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Licence Validity Expiry Date',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _expiryController,
          decoration: InputDecoration(
            hintText: 'DD/MM/YYYY',
            prefixIcon: const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.primaryForest,
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Document Format',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildDocTypeChip('Smart Card DL'),
            const SizedBox(width: 10),
            _buildDocTypeChip('mParivahan Digital'),
            const SizedBox(width: 10),
            _buildDocTypeChip('DigiLocker QR'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  _uploadedDocName != null
                      ? AppColors.primaryForest
                      : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Icon(
                _uploadedDocName != null
                    ? Icons.check_circle_outline_rounded
                    : Icons.cloud_upload_outlined,
                size: 36,
                color:
                    _uploadedDocName != null
                        ? AppColors.primaryForest
                        : AppColors.mutedSage,
              ),
              const SizedBox(height: 8),
              Text(
                _uploadedDocName ?? 'Licence Document / Photo Submission',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Upload a clear PDF or photo of your driving licence card.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryForest,
                  side: const BorderSide(color: AppColors.primaryForest),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _uploadedDocName =
                        'DL_${_licenseController.text.trim().replaceAll(' ', '_')}.pdf';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Driving licence document attached.'),
                      backgroundColor: AppColors.primaryForest,
                    ),
                  );
                },
                icon: const Icon(Icons.attach_file_rounded, size: 16),
                label: Text(
                  _uploadedDocName != null
                      ? 'Replace Document'
                      : 'Attach Document',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocTypeChip(String label) {
    final isSelected = _selectedDocType == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedDocType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.softForest : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryForest : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color:
                isSelected ? AppColors.primaryForest : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStepVehicle(AsyncValue<List<dynamic>> vehiclesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Step 3: Associate Registered Vehicle',
          style: AppTypography.cardTitle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          'A verified vehicle with active registration is required to offer shared carpool journeys.',
          style: AppTypography.secondary,
        ),
        const SizedBox(height: 16),
        vehiclesAsync.when(
          loading:
              () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(
                    color: AppColors.primaryForest,
                  ),
                ),
              ),
          error:
              (err, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.mutedRust),
                ),
                child: Column(
                  children: [
                    Text(
                      'Unable to load vehicles: ${err.toString()}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.mutedRust,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed:
                          () => ref.read(vehiclesProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.directions_car_outlined,
                      size: 40,
                      color: AppColors.mutedSage,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Vehicles Registered Yet',
                      style: AppTypography.cardTitle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You can register your vehicle now or proceed and add it before publishing your first ride.',
                      style: AppTypography.secondary,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryForest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => context.push('/vehicles/add'),
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Register Vehicle Now',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                ...vehicles.map((v) {
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    color: AppColors.cardBackground,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.softForest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: AppColors.primaryForest,
                        ),
                      ),
                      title: Text(
                        '${v.make} ${v.model}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${v.registrationNumber} • ${v.seatCapacity} Seats',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softForest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Ready',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryForest,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryForest,
                    side: const BorderSide(color: AppColors.primaryForest),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => context.push('/vehicles/add'),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Another Vehicle'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStepReview(
    UserModel user,
    AsyncValue<List<dynamic>> vehiclesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Step 4: Review Application & Safety Consent',
          style: AppTypography.cardTitle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          'Please verify the details below and confirm compliance with Sahyān carpooling standards.',
          style: AppTypography.secondary,
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          color: AppColors.cardBackground,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Driver Applicant',
                  value: user.name,
                ),
                const Divider(color: AppColors.border, height: 16),
                _buildInfoRow(
                  icon: Icons.phone_android_rounded,
                  title: 'Verified Contact',
                  value: user.phone,
                ),
                const Divider(color: AppColors.border, height: 16),
                _buildInfoRow(
                  icon: Icons.badge_outlined,
                  title: 'Licence Number',
                  value:
                      _licenseController.text.isNotEmpty
                          ? _licenseController.text.trim().toUpperCase()
                          : 'Not Provided',
                ),
                const Divider(color: AppColors.border, height: 16),
                _buildInfoRow(
                  icon: Icons.directions_car_outlined,
                  title: 'Registered Fleet',
                  value: vehiclesAsync.maybeWhen(
                    data:
                        (v) =>
                            v.isNotEmpty
                                ? '${v.length} Vehicle(s) Associated'
                                : 'None Registered',
                    orElse: () => 'Verifying...',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _agreeSafetyPolicy,
          onChanged: (val) => setState(() => _agreeSafetyPolicy = val ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primaryForest,
          title: Text(
            'I confirm that I hold a valid permanent driving licence, follow all traffic laws, and commit to passenger safety.',
            style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
          ),
        ),
        CheckboxListTile(
          value: _agreeCostSharingOnly,
          onChanged:
              (val) => setState(() => _agreeCostSharingOnly = val ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primaryForest,
          title: Text(
            'I acknowledge that Sahyān is a peer-to-peer carpooling cost-sharing platform and not a commercial taxi service.',
            style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildStepActions(bool isSaving) {
    if (_currentStep < 3) {
      return Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => setState(() => _currentStep--),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryForest,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (_currentStep == 1) {
                  if (!_formKey.currentState!.validate()) return;
                }
                setState(() => _currentStep++);
              },
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return PrimaryButton(
      text: 'Submit Application for Review',
      isLoading: isSaving,
      onPressed: _handleSubmitApplication,
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryForest),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildApprovedView(BuildContext context, UserModel user) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        title: Text('Driver Account', style: AppTypography.screenTitle),
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppColors.softForest,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  size: 44,
                  color: AppColors.primaryForest,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Approved Sahyān Driver',
                style: AppTypography.screenTitle.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your driving licence and documents are verified. You are authorized to publish and offer carpool journeys.',
                style: AppTypography.secondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                color: AppColors.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.badge_outlined,
                        title: 'Verified Licence Number',
                        value:
                            user.licenseNumber.isNotEmpty
                                ? user.licenseNumber
                                : 'Verified on Record',
                      ),
                      const Divider(color: AppColors.border, height: 16),
                      _buildInfoRow(
                        icon: Icons.shield_outlined,
                        title: 'Verification Status',
                        value: 'Active & In Good Standing',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Offer a Ride',
                onPressed: () => context.go('/offer-ride'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryForest,
                  side: const BorderSide(color: AppColors.primaryForest),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => context.push('/vehicles'),
                child: const Text('Manage Fleet & Vehicles'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmittedView(BuildContext context, UserModel user) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        title: Text('Driver Status', style: AppTypography.screenTitle),
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFDBA74)),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 40,
                  color: Color(0xFFC2410C),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Application Under Review',
                style: AppTypography.screenTitle.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your driver application and licence details have been submitted. Administrative review typically takes 24 to 48 hours.',
                style: AppTypography.secondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFFED7AA)),
                ),
                color: const Color(0xFFFFFBEB),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.badge_outlined,
                        title: 'Submitted Licence Number',
                        value:
                            user.licenseNumber.isNotEmpty
                                ? user.licenseNumber
                                : 'Under Verification',
                      ),
                      const Divider(color: Color(0xFFFED7AA), height: 16),
                      _buildInfoRow(
                        icon: Icons.checklist_rounded,
                        title: 'Review Stages',
                        value: 'Document Audit In Progress',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Refresh Verification Status',
                onPressed: () {
                  ref.read(authProvider.notifier).checkAuthStatus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Checking latest verification status...'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/profile');
                  }
                },
                child: Text(
                  'Back to Account Profile',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primaryForest,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRejectedView(BuildContext context, UserModel user) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        title: Text('Driver Application', style: AppTypography.screenTitle),
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Action Required on Application',
                style: AppTypography.screenTitle.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your driver application could not be approved due to documentation criteria.',
                style: AppTypography.secondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reason for Rejection:',
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFF991B1B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.rejectionReason.isNotEmpty
                          ? user.rejectionReason
                          : 'Uploaded documentation was unclear or did not meet platform safety criteria.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFF7F1D1D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Re-Submit Driver Details',
                onPressed: () {
                  setState(() {
                    _currentStep = 1;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/help-support'),
                child: Text(
                  'Contact Safety Lead & Support',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
