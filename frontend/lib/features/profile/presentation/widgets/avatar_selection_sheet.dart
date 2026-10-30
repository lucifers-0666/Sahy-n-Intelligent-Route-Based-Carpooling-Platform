import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/utils/profile_image_helper.dart';
import 'package:sahyan/core/widgets/primary_button.dart';
import 'avatar_crop_dialog.dart';

class PresetAvatar {
  final String id;
  final String label;
  final String url;
  final String category;

  const PresetAvatar({
    required this.id,
    required this.label,
    required this.url,
    required this.category,
  });
}

class AvatarSelectionSheet extends StatefulWidget {
  final String? initialAvatarUrl;
  final String userName;
  final ValueChanged<String?> onAvatarSelected;

  const AvatarSelectionSheet({
    super.key,
    required this.initialAvatarUrl,
    required this.userName,
    required this.onAvatarSelected,
  });

  static Future<String?> show(
    BuildContext context, {
    String? currentUrl,
    required String userName,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AvatarSelectionSheet(
        initialAvatarUrl: currentUrl,
        userName: userName,
        onAvatarSelected: (url) => Navigator.of(ctx).pop(url),
      ),
    );
  }

  @override
  State<AvatarSelectionSheet> createState() => _AvatarSelectionSheetState();
}

class _AvatarSelectionSheetState extends State<AvatarSelectionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedUrl;
  bool _isPicking = false;

  late final List<PresetAvatar> _presetAvatars;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedUrl = widget.initialAvatarUrl;

    final safeName = Uri.encodeComponent(
      widget.userName.isNotEmpty ? widget.userName : 'Member',
    );

    _presetAvatars = [
      PresetAvatar(
        id: 'initials',
        label: 'Initials Theme',
        url:
            'https://ui-avatars.com/api/?name=$safeName&background=0B5D4B&color=fff&size=256&bold=true',
        category: 'Minimal',
      ),
      const PresetAvatar(
        id: 'ahmedabad',
        label: 'Ahmedabad Commuter',
        url:
            'https://api.dicebear.com/7.x/adventurer/png?seed=AhmedabadCommuter&backgroundColor=b6e3f4',
        category: 'Urban',
      ),
      const PresetAvatar(
        id: 'executive',
        label: 'Executive Driver',
        url:
            'https://api.dicebear.com/7.x/adventurer/png?seed=ExecutiveDriver&backgroundColor=c0aede',
        category: 'Driver',
      ),
      const PresetAvatar(
        id: 'navigator',
        label: 'Highway Navigator',
        url:
            'https://api.dicebear.com/7.x/adventurer/png?seed=HighwayNavigator&backgroundColor=d1d4f9',
        category: 'Driver',
      ),
      const PresetAvatar(
        id: 'surat',
        label: 'Surat Transit',
        url:
            'https://api.dicebear.com/7.x/adventurer/png?seed=SuratTransit&backgroundColor=ffd5dc',
        category: 'Commuter',
      ),
      const PresetAvatar(
        id: 'gandhinagar',
        label: 'Eco Commuter',
        url:
            'https://api.dicebear.com/7.x/adventurer/png?seed=GandhinagarEco&backgroundColor=ffdfbf',
        category: 'Eco',
      ),
      const PresetAvatar(
        id: 'vadodara',
        label: 'Expressway Commuter',
        url:
            'https://api.dicebear.com/7.x/adventurer/png?seed=VadodaraExpress&backgroundColor=c0aede',
        category: 'Urban',
      ),
      const PresetAvatar(
        id: 'fleet_bot',
        label: 'Green Fleet Bot',
        url:
            'https://api.dicebear.com/7.x/bottts/png?seed=SahyanDriverFleet&backgroundColor=d1d4f9',
        category: 'Fleet',
      ),
      const PresetAvatar(
        id: 'smart_bot',
        label: 'Smart Rider Bot',
        url:
            'https://api.dicebear.com/7.x/bottts/png?seed=SahyanSmartRider&backgroundColor=b6e3f4',
        category: 'Fleet',
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );

      if (pickedFile == null) {
        if (mounted) setState(() => _isPicking = false);
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      if (!mounted) return;
      setState(() => _isPicking = false);

      final croppedUri = await AvatarCropDialog.show(
        context,
        imageBytes: bytes,
        userName: widget.userName,
      );

      if (croppedUri != null && mounted) {
        setState(() {
          _selectedUrl = croppedUri;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPicking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access image: $e'),
            backgroundColor: AppColors.mutedRust,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = getProfileImageProvider(_selectedUrl);
    final hasImage = imageProvider != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Profile Picture',
                      style: AppTypography.screenTitle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select a preset avatar or upload photo from device',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Active Preview Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.softForest,
                    backgroundImage: imageProvider,
                    onBackgroundImageError:
                        hasImage ? (exception, stackTrace) {} : null,
                    child: !hasImage
                        ? const Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: AppColors.primaryForest,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Profile Photo',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasImage
                              ? (_selectedUrl!.startsWith('data:image')
                                  ? 'Custom cropped photo ready to save'
                                  : 'Preset avatar ready to apply')
                              : 'Default initials avatar',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasImage)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedUrl = '';
                        });
                      },
                      child: Text(
                        'Remove',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.mutedRust,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryForest,
            labelColor: AppColors.primaryForest,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.face_outlined, size: 20),
                text: 'Preset Avatars',
              ),
              Tab(
                icon: Icon(Icons.photo_library_outlined, size: 20),
                text: 'Upload / Storage',
              ),
            ],
          ),

          const Divider(height: 1, color: AppColors.border),

          // Tab Content
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Preset Avatars Grid
                GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _presetAvatars.length,
                  itemBuilder: (context, index) {
                    final preset = _presetAvatars[index];
                    final isSelected = _selectedUrl == preset.url;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedUrl = preset.url;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryForest
                                : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.softForest,
                              backgroundImage: NetworkImage(preset.url),
                              onBackgroundImageError: (exception, stackTrace) {},
                            ),
                            const SizedBox(height: 6),
                            Text(
                              preset.label,
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primaryForest
                                    : AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // 2. Upload from Local / Device Storage (Gallery & Camera)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Upload Option 1: Gallery / Storage
                      _buildUploadActionCard(
                        icon: Icons.photo_library_rounded,
                        title: 'Choose from Gallery / Files',
                        subtitle: 'Select an image stored on your phone or SD card',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),

                      const SizedBox(height: 12),

                      // Upload Option 2: Camera
                      _buildUploadActionCard(
                        icon: Icons.camera_alt_rounded,
                        title: 'Take Photo with Camera',
                        subtitle: 'Snap an instant picture and crop to square/circle',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),

                      const SizedBox(height: 16),

                      // Info banner about crop & local storage
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.warmBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.crop_rotate_rounded,
                              size: 18,
                              color: AppColors.primaryForest,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Built-In Crop & Scale Tools',
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.deepEmerald,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'After choosing a photo, you can rotate, pinch to zoom, pan, and choose between standard (300px) or high-res (600px) square/circular avatar formats.',
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: PrimaryButton(
              text: 'Apply Profile Photo',
              onPressed: () {
                widget.onAvatarSelected(_selectedUrl);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isPicking ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.deepEmerald,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
