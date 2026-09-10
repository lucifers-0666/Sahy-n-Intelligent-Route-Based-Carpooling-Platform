import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/design_system.dart';
import '../providers/saved_places_provider.dart';

class SavedPlacesScreen extends ConsumerWidget {
  const SavedPlacesScreen({super.key});

  IconData _getPlaceIcon(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline;
      case 'college':
      case 'university':
        return Icons.school_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  void _showAddPlaceDialog(BuildContext context, WidgetRef ref) {
    final labelController = TextEditingController(text: 'Home');
    final addressController = TextEditingController();
    final landmarkController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Saved Place',
                style: AppTypography.screenTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSpacing.md),
              SahyanTextField(
                label: 'Place Name / Label',
                hint: 'e.g. Home, Work, University',
                controller: labelController,
              ),
              const SizedBox(height: AppSpacing.sm),
              SahyanTextField(
                label: 'Full Address',
                hint: 'Street name, Area, City',
                controller: addressController,
              ),
              const SizedBox(height: AppSpacing.sm),
              SahyanTextField(
                label: 'Nearby Landmark (Optional)',
                hint: 'e.g. Near Metro Station',
                controller: landmarkController,
              ),
              const SizedBox(height: AppSpacing.lg),
              SahyanButton(
                text: 'Save Place',
                icon: Icons.check_rounded,
                isFullWidth: true,
                onPressed: () {
                  if (addressController.text.trim().isNotEmpty) {
                    ref
                        .read(savedPlacesProvider.notifier)
                        .addPlace(
                          label: labelController.text.trim(),
                          address: addressController.text.trim(),
                          landmark: landmarkController.text.trim().isNotEmpty
                              ? landmarkController.text.trim()
                              : null,
                        );
                    Navigator.of(ctx).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(savedPlacesProvider);

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: SahyanAppBar(
        title: 'Saved Places',
        subtitle: 'Quick points for effortless carpooling',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.primaryForest,
              size: 24,
            ),
            tooltip: 'Add Place',
            onPressed: () => _showAddPlaceDialog(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: places.isEmpty
            ? Center(
                child: SahyanEmptyState(
                  title: 'No saved places yet',
                  description:
                      'Save your frequent pickup and drop locations to book shared rides even faster.',
                  icon: Icons.location_off_outlined,
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: places.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final place = places[index];
                  return SahyanCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.softForest,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Icon(
                            _getPlaceIcon(place.label),
                            color: AppColors.primaryForest,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.label,
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                place.address,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              if (place.landmark != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Landmark: ${place.landmark}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryForest,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          tooltip: 'Delete',
                          onPressed: () {
                            ref
                                .read(savedPlacesProvider.notifier)
                                .removePlace(place.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add Location'),
        onPressed: () => _showAddPlaceDialog(context, ref),
      ),
    );
  }
}
