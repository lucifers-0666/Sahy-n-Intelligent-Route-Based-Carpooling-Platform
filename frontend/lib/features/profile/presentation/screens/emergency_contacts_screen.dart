import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/app_text_field.dart';
import 'package:sahyan/core/widgets/primary_button.dart';
import 'package:sahyan/shared/models/user_model.dart';
import 'package:sahyan/features/profile/presentation/profile_provider.dart';

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends ConsumerState<EmergencyContactsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileProvider.notifier).loadEmergencyContacts();
    });
  }

  void _showContactBottomSheet({EmergencyContact? contact}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ContactFormBottomSheet(contact: contact),
    );
  }

  void _confirmDelete(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove Contact', style: AppTypography.cardTitle),
        content: Text(
          'Are you sure you want to remove ${contact.name} from your emergency contacts?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mutedRust,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref
                  .read(profileProvider.notifier)
                  .deleteEmergencyContact(contact.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.primaryForest,
                      content: Text('Emergency contact removed successfully'),
                    ),
                  );
                } else {
                  final error =
                      ref.read(profileProvider).errorMessage ??
                      'Failed to delete contact';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.mutedRust,
                      content: Text(error),
                    ),
                  );
                }
              }
            },
            child: Text(
              'Remove',
              style: AppTypography.button.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final contacts = profileState.emergencyContacts;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        title: Text('Emergency Contacts', style: AppTypography.screenTitle),
      ),
      body: SafeArea(
        child: profileState.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryForest,
                ),
              )
            : RefreshIndicator(
                color: AppColors.primaryForest,
                onRefresh: () async {
                  await ref
                      .read(profileProvider.notifier)
                      .loadEmergencyContacts();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Safety Information Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.softForest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryForest.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryForest,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Trusted Safety Circle',
                                    style: AppTypography.cardTitle.copyWith(
                                      color: AppColors.deepForest,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'During your trips, ride tracking links and emergency SOS alerts can be sent to these contacts.',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.deepForest,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Your Contacts (${contacts.length})',
                              style: AppTypography.cardTitle,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: AppColors.primaryForest,
                            ),
                            label: Text(
                              'Add Contact',
                              style: AppTypography.button.copyWith(
                                color: AppColors.primaryForest,
                              ),
                            ),
                            onPressed: () => _showContactBottomSheet(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (contacts.isEmpty)
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 36,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppColors.softForest,
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child: const Icon(
                                    Icons.contact_emergency_outlined,
                                    size: 32,
                                    color: AppColors.primaryForest,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Emergency Contacts Yet',
                                  style: AppTypography.screenTitle.copyWith(
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Add trusted family members or friends who can be reached during an emergency.',
                                  style: AppTypography.secondary,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                PrimaryButton(
                                  text: 'Add First Contact',
                                  onPressed: () => _showContactBottomSheet(),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: contacts.length,
                          separatorBuilder: (ctx, i) =>
                              const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final c = contacts[i];
                            return Card(
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
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.softForest,
                                      child: Text(
                                        c.name.isNotEmpty
                                            ? c.name[0].toUpperCase()
                                            : 'C',
                                        style: AppTypography.cardTitle.copyWith(
                                          color: AppColors.primaryForest,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                c.name,
                                                style: AppTypography.bodyLarge
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppColors.warmBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: AppColors.border,
                                                  ),
                                                ),
                                                child: Text(
                                                  c.relationship,
                                                  style: AppTypography.caption
                                                      .copyWith(
                                                        color: AppColors
                                                            .textSecondary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.phone_outlined,
                                                size: 14,
                                                color: AppColors.primaryForest,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  c.phone,
                                                  style: AppTypography.secondary
                                                      .copyWith(
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: AppColors.textSecondary,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      tooltip: 'Edit Contact',
                                      onPressed: () =>
                                          _showContactBottomSheet(contact: c),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: AppColors.mutedRust,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      tooltip: 'Delete Contact',
                                      onPressed: () => _confirmDelete(c),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _ContactFormBottomSheet extends ConsumerStatefulWidget {
  final EmergencyContact? contact;

  const _ContactFormBottomSheet({this.contact});

  @override
  ConsumerState<_ContactFormBottomSheet> createState() =>
      _ContactFormBottomSheetState();
}

class _ContactFormBottomSheetState
    extends ConsumerState<_ContactFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String _relationship = 'Family';

  final List<String> _relationshipOptions = [
    'Family',
    'Parent',
    'Spouse',
    'Sibling',
    'Friend',
    'Colleague',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    final rawPhone = widget.contact?.phone ?? '';
    final formattedPhone = rawPhone.startsWith('+91')
        ? rawPhone.substring(3)
        : rawPhone;
    _phoneController = TextEditingController(text: formattedPhone);
    if (widget.contact != null &&
        _relationshipOptions.contains(widget.contact!.relationship)) {
      _relationship = widget.contact!.relationship;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final notifier = ref.read(profileProvider.notifier);
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    bool success;
    if (widget.contact == null) {
      success = await notifier.addEmergencyContact(
        name: name,
        phone: phone,
        relationship: _relationship,
      );
    } else {
      success = await notifier.updateEmergencyContact(
        id: widget.contact!.id,
        name: name,
        phone: phone,
        relationship: _relationship,
      );
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryForest,
            content: Text(
              widget.contact == null
                  ? 'Emergency contact added'
                  : 'Emergency contact updated',
            ),
          ),
        );
      } else {
        final error =
            ref.read(profileProvider).errorMessage ?? 'Operation failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.mutedRust, content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.contact != null;
    final isSaving = ref.watch(profileProvider).isSaving;
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Contact' : 'Add Emergency Contact',
                        style: AppTypography.screenTitle.copyWith(fontSize: 20),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Contact Name',
                    hint: 'e.g. Meera Patel',
                    controller: _nameController,
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.textSecondary,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter contact name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Phone Number',
                    hint: '10-digit mobile number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.phone_android_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+91',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter phone number';
                      }
                      final clean = val.trim().replaceAll(
                        RegExp(r'[\s\-]'),
                        '',
                      );
                      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
                        return 'Enter a valid 10-digit Indian mobile number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Relationship', style: AppTypography.fieldLabel),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _relationship,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.people_outline_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    items: _relationshipOptions.map((rel) {
                      return DropdownMenuItem(
                        value: rel,
                        child: Text(rel, style: AppTypography.bodyLarge),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _relationship = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: isEditing ? 'Update Contact' : 'Save Contact',
                    isLoading: isSaving,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
