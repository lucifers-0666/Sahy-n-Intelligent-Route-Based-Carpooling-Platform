import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/sahyan_app_bar.dart';
import '../../../../core/widgets/sahyan_avatar.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../core/widgets/sahyan_card.dart';
import '../../../../core/widgets/sahyan_text_field.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../profile_provider.dart';

class PersonalDetailsScreen extends ConsumerStatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  ConsumerState<PersonalDetailsScreen> createState() =>
      _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends ConsumerState<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  int _bioLength = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _bioLength = _bioController.text.length;

    _bioController.addListener(() {
      if (mounted) {
        setState(() {
          _bioLength = _bioController.text.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final success = await ref
        .read(profileProvider.notifier)
        .updateProfile(
          name: _nameController.text.trim(),
          city: _cityController.text.trim(),
          bio: _bioController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personal details updated successfully'),
          backgroundColor: AppColors.primaryForest,
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    } else {
      final error =
          ref.read(profileProvider).errorMessage ?? 'Failed to update details';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.mutedRust),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final phoneDisplay =
        user?.phone ?? authState.otpSentToPhone ?? '+91 98765 43210';

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Personal Details',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
            vertical: AppSpacing.md,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Indicator Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Account Identity',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softForest,
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                      child: Text(
                        'Step 3 of 3',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryForest,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Legal Identity',
                  style: AppTypography.screenTitle.copyWith(fontSize: 22),
                ),
                Text(
                  'Help co-travelers recognize and trust you on the highway corridor.',
                  style: AppTypography.secondary,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Avatar Center Card
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          SahyanAvatar(
                            name: _nameController.text.isNotEmpty
                                ? _nameController.text
                                : 'Carpool User',
                            radius: 44,
                            isVerified: true,
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primaryForest,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.15),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: AppColors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Avatar upload ready for photo'),
                              backgroundColor: AppColors.primaryForest,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 16,
                          color: AppColors.primaryForest,
                        ),
                        label: Text(
                          'Update Profile Photo',
                          style: AppTypography.button.copyWith(
                            color: AppColors.primaryForest,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.base),

                // Form Details Card
                SahyanCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      SahyanTextField(
                        label: 'Legal Full Name',
                        hint: 'Enter your legal first and last name',
                        controller: _nameController,
                        prefixIcon: const Icon(Icons.badge_outlined),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please provide your full legal name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Phone Number (Readonly with Verified Badge)
                      Text(
                        'Phone Number',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepForest,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warmBackground,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                phoneDisplay,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.softForest,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.full,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 14,
                                    color: AppColors.primaryForest,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.primaryForest,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Email Address
                      SahyanTextField(
                        label: 'Email Address',
                        hint: 'your.email@domain.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.mail_outline_rounded),
                        helperText:
                            'Trip receipts and booking confirmations are sent here',
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Base City / Location
                      SahyanTextField(
                        label: 'Base City / Primary Region',
                        hint: 'e.g. Pune, Maharashtra',
                        controller: _cityController,
                        prefixIcon: const Icon(Icons.location_city_rounded),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Base city is required for corridor matching';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Short Bio with character counter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Short Bio',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.deepForest,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '$_bioLength/140',
                            style: AppTypography.caption.copyWith(
                              color: _bioLength > 140
                                  ? AppColors.mutedRust
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _bioController,
                        maxLength: 140,
                        maxLines: 3,
                        buildCounter:
                            (
                              context, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => null,
                        decoration: InputDecoration(
                          hintText:
                              'e.g. Regular commuter between Ahmedabad and Rajkot. Safe driving and punctual.',
                          hintStyle: AppTypography.secondary,
                          filled: true,
                          fillColor: AppColors.warmBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: const BorderSide(
                              color: AppColors.primaryForest,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Reassurance Note
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.softForest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: AppColors.primaryForest,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Your contact data is securely tokenized and shared strictly with confirmed co-travelers.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.deepForest,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                SahyanButton(
                  text: 'Save & Complete Setup',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isSaving,
                  isFullWidth: true,
                  onPressed: _handleSave,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
