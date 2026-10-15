import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/app_text_field.dart';
import 'package:sahyan/core/widgets/primary_button.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/profile/presentation/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _bioController;

  late bool _notifications;
  late bool _allowSmoking;
  late bool _allowPets;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');

    _notifications = user?.preferences.notifications ?? true;
    _allowSmoking = user?.preferences.allowSmoking ?? false;
    _allowPets = user?.preferences.allowPets ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final profileNotifier = ref.read(profileProvider.notifier);

    final successProfile = await profileNotifier.updateProfile(
      name: _nameController.text.trim(),
      city: _cityController.text.trim(),
      bio: _bioController.text.trim(),
    );

    final successPrefs = await profileNotifier.updatePreferences(
      notifications: _notifications,
      allowSmoking: _allowSmoking,
      allowPets: _allowPets,
    );

    if (mounted) {
      if (successProfile && successPrefs) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primaryForest,
            content: Text('Profile and preferences updated successfully'),
          ),
        );
        Navigator.of(context).pop();
      } else {
        final error = ref.read(profileProvider).errorMessage ?? 'Update failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.mutedRust, content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(profileProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        title: Text('Edit Profile', style: AppTypography.screenTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Photo Foundation
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: AppColors.softForest,
                              backgroundImage: (user?.profilePhoto != null &&
                                      user!.profilePhoto!.isNotEmpty)
                                  ? NetworkImage(user.profilePhoto!)
                                  : null,
                              child: (user?.profilePhoto != null &&
                                      user!.profilePhoto!.isNotEmpty)
                                  ? null
                                  : const Icon(
                                      Icons.person_rounded,
                                      size: 46,
                                      color: AppColors.primaryForest,
                                    ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryForest,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Profile initials displayed. Custom photo upload will be available in upcoming release.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Personal Details Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        color: AppColors.cardBackground,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.badge_outlined,
                                    color: AppColors.primaryForest,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Personal Details',
                                      style: AppTypography.cardTitle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Full Name',
                                hint: 'Enter your full name',
                                controller: _nameController,
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Phone Number',
                                hint: 'Registered phone number',
                                controller: TextEditingController(
                                  text: user?.phone ?? '',
                                ),
                                readOnly: true,
                                enabled: false,
                                prefixIcon: const Icon(
                                  Icons.phone_android_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (user?.isVerified == true) ...[
                                        const Icon(
                                          Icons.verified_rounded,
                                          size: 16,
                                          color: AppColors.primaryForest,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        user?.isVerified == true
                                            ? 'Verified'
                                            : 'Pending',
                                        style: AppTypography.caption.copyWith(
                                          color: user?.isVerified == true
                                              ? AppColors.primaryForest
                                              : AppColors.textSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Email Address',
                                hint: 'Registered email address',
                                controller: TextEditingController(
                                  text: user?.email ?? '',
                                ),
                                readOnly: true,
                                enabled: false,
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (user?.email.isNotEmpty == true) ...[
                                        const Icon(
                                          Icons.verified_rounded,
                                          size: 16,
                                          color: AppColors.primaryForest,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        user?.email.isNotEmpty == true
                                            ? 'Registered'
                                            : 'Pending',
                                        style: AppTypography.caption.copyWith(
                                          color: user?.email.isNotEmpty == true
                                              ? AppColors.primaryForest
                                              : AppColors.textSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'City / Base Location',
                                hint: 'e.g. Surat, Gujarat',
                                controller: _cityController,
                                prefixIcon: const Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your city';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Mini Bio / About',
                                          style: AppTypography.fieldLabel,
                                        ),
                                      ),
                                      ValueListenableBuilder<TextEditingValue>(
                                        valueListenable: _bioController,
                                        builder: (context, value, _) {
                                          return Text(
                                            '${value.text.length}/140',
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color: value.text.length > 140
                                                      ? AppColors.mutedRust
                                                      : AppColors.textSecondary,
                                                ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _bioController,
                                    maxLength: 140,
                                    maxLines: 3,
                                    style: AppTypography.bodyLarge.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Brief commuter note (e.g. daily SG Highway carpooler)',
                                      counterText: '',
                                      prefixIcon: const Padding(
                                        padding: EdgeInsets.only(bottom: 36),
                                        child: Icon(
                                          Icons.notes_rounded,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Travel & Ride Preferences Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        color: AppColors.cardBackground,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.tune_rounded,
                                    color: AppColors.primaryForest,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Ride Preferences',
                                      style: AppTypography.cardTitle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                activeTrackColor: AppColors.primaryForest,
                                title: Text(
                                  'Push & SMS Notifications',
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Receive instant route matching and safety updates',
                                  style: AppTypography.secondary.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                                value: _notifications,
                                onChanged: (val) {
                                  setState(() {
                                    _notifications = val;
                                  });
                                },
                              ),
                              const Divider(color: AppColors.border, height: 1),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                activeTrackColor: AppColors.primaryForest,
                                title: Text(
                                  'Allow Smoking in Vehicle',
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Co-traveler smoking policy preference',
                                  style: AppTypography.secondary.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                                value: _allowSmoking,
                                onChanged: (val) {
                                  setState(() {
                                    _allowSmoking = val;
                                  });
                                },
                              ),
                              const Divider(color: AppColors.border, height: 1),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                activeTrackColor: AppColors.primaryForest,
                                title: Text(
                                  'Allow Pets in Ride',
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Comfort preference when travelling with pets',
                                  style: AppTypography.secondary.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                                value: _allowPets,
                                onChanged: (val) {
                                  setState(() {
                                    _allowPets = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed Bottom Save Action
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: const Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: PrimaryButton(
                text: 'Save Changes',
                isLoading: profileState.isSaving,
                onPressed: _handleSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
