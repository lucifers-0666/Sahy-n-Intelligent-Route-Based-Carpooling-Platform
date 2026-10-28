import 'package:flutter/material.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/primary_button.dart';

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
  late final TextEditingController _customUrlController;
  String? _selectedUrl;

  late final List<PresetAvatar> _presetAvatars;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedUrl = widget.initialAvatarUrl;
    _customUrlController = TextEditingController(
      text: (widget.initialAvatarUrl != null &&
              !widget.initialAvatarUrl!.contains('dicebear.com') &&
              !widget.initialAvatarUrl!.contains('ui-avatars.com'))
          ? widget.initialAvatarUrl
          : '',
    );

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
    _customUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                      'Select a default avatar or enter custom photo URL',
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
                    backgroundImage: (_selectedUrl != null &&
                            _selectedUrl!.isNotEmpty)
                        ? NetworkImage(_selectedUrl!)
                        : null,
                    child: (_selectedUrl == null || _selectedUrl!.isEmpty)
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
                          _selectedUrl != null && _selectedUrl!.isNotEmpty
                              ? 'Active preview ready to apply'
                              : 'Default initials avatar',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedUrl != null && _selectedUrl!.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedUrl = '';
                          _customUrlController.clear();
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
                icon: Icon(Icons.link_rounded, size: 20),
                text: 'Custom Photo URL',
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

                // 2. Custom Photo URL Input with real-time preview
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Direct Image URL',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _customUrlController,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          hintText: 'https://example.com/avatar.jpg',
                          hintStyle: AppTypography.secondary.copyWith(
                            color: AppColors.mutedSage,
                          ),
                          prefixIcon: const Icon(
                            Icons.link_rounded,
                            color: AppColors.primaryForest,
                            size: 20,
                          ),
                          suffixIcon: _customUrlController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _customUrlController.clear();
                                    setState(() {
                                      _selectedUrl = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.cardBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primaryForest,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _selectedUrl = val.trim();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Supports JPG, PNG, WebP, or SVG image URLs hosted on Cloudinary, Imgur, Gravatar, Unsplash, or public CDNs.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.4,
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
}

