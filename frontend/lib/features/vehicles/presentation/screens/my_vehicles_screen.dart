import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_radii.dart';
import 'package:sahyan/app/theme/app_spacing.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/primary_button.dart';
import 'package:sahyan/core/widgets/sahyan_app_bar.dart';
import 'package:sahyan/core/widgets/vehicles/vehicle_icon.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_type.dart';
import 'package:sahyan/features/vehicles/presentation/vehicle_provider.dart';

class MyVehiclesScreen extends ConsumerWidget {
  const MyVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: SahyanAppBar(
        title: 'My Vehicles',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryForest),
            tooltip: 'Add Vehicle',
            onPressed: () => context.push('/vehicles/add'),
          ),
        ],
      ),
      body: SafeArea(
        child: vehiclesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryForest),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.mutedRust,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Failed to Load Vehicles',
                    style: AppTypography.screenTitle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    error.toString(),
                    style: AppTypography.secondary,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    text: 'Try Again',
                    onPressed: () =>
                        ref.read(vehiclesProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
          ),
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildVehicleList(context, ref, vehicles);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.softForest,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const VehicleIcon.illustration(
                type: VehicleType.sedan,
                width: 90,
                height: 56,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Vehicles Registered',
              style: AppTypography.screenTitle.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Register your vehicle to unlock driver privileges, offer rides along your commute route, and share travel costs.',
              style: AppTypography.secondary.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              text: 'Add Your First Vehicle',
              onPressed: () => context.push('/vehicles/add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleList(
    BuildContext context,
    WidgetRef ref,
    List<VehicleModel> vehicles,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Registered Fleet (${vehicles.length})',
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: 4),
          Text(
            'Active vehicles eligible for route pooling and ride offerings.',
            style: AppTypography.secondary.copyWith(fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          ...vehicles.map(
            (vehicle) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _buildVehicleCard(context, ref, vehicle),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.primaryForest),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
              ),
            ),
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.primaryForest,
              size: 20,
            ),
            label: Text(
              'Add Another Vehicle',
              style: AppTypography.button.copyWith(
                color: AppColors.primaryForest,
              ),
            ),
            onPressed: () => context.push('/vehicles/add'),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(
    BuildContext context,
    WidgetRef ref,
    VehicleModel vehicle,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 36,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: VehicleIcon.illustration(
                    type: vehicle.type,
                    width: 46,
                    height: 30,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              vehicle.displayName,
                              style: AppTypography.screenTitle.copyWith(fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (vehicle.type.isElectric) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.softForest,
                                borderRadius: BorderRadius.circular(AppRadii.full),
                              ),
                              child: Text(
                                'EV',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warmBackground,
                          borderRadius: BorderRadius.circular(AppRadii.xs),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          vehicle.registrationNumber,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            fontSize: 11,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: vehicle.status == 'active'
                        ? AppColors.softForest
                        : AppColors.warmBackground,
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  child: Text(
                    vehicle.status == 'active' ? 'Active' : 'Inactive',
                    style: AppTypography.caption.copyWith(
                      color: vehicle.status == 'active'
                          ? AppColors.primaryForest
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildInfoPill(
                  Icons.category_outlined,
                  vehicle.type.displayName,
                ),
                _buildInfoPill(
                  Icons.airline_seat_recline_normal_rounded,
                  '${vehicle.seatCapacity} Seats',
                ),
                _buildInfoPill(Icons.palette_outlined, vehicle.color),
                _buildInfoPill(
                  Icons.calendar_today_outlined,
                  vehicle.year.toString(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppColors.primaryForest,
                  ),
                  label: Text(
                    'Edit',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryForest,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => context.push('/vehicles/edit', extra: vehicle),
                ),
                TextButton.icon(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppColors.mutedRust,
                  ),
                  label: Text(
                    'Delete',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.mutedRust,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => _confirmDelete(context, ref, vehicle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warmBackground,
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    VehicleModel vehicle,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
        title: Text('Delete Vehicle', style: AppTypography.screenTitle.copyWith(fontSize: 18)),
        content: Text(
          'Are you sure you want to delete ${vehicle.displayName} (${vehicle.registrationNumber})? This will remove the vehicle from your fleet.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: AppTypography.button.copyWith(color: AppColors.textSecondary)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text('Delete', style: AppTypography.button.copyWith(color: AppColors.mutedRust)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(vehiclesProvider.notifier).deleteVehicle(vehicle.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vehicle deleted.'),
                      backgroundColor: AppColors.primaryForest,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('ApiException: ', '')),
                      backgroundColor: AppColors.mutedRust,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
