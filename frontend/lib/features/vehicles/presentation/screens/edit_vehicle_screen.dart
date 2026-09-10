import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_radii.dart';
import 'package:sahyan/app/theme/app_spacing.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/app_text_field.dart';
import 'package:sahyan/core/widgets/primary_button.dart';
import 'package:sahyan/core/widgets/sahyan_app_bar.dart';
import 'package:sahyan/core/widgets/vehicles/vehicle_icon.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_type.dart';
import 'package:sahyan/features/vehicles/presentation/vehicle_provider.dart';
import 'package:sahyan/features/vehicles/presentation/screens/add_vehicle_screen.dart';

class EditVehicleScreen extends ConsumerStatefulWidget {
  final VehicleModel vehicle;

  const EditVehicleScreen({super.key, required this.vehicle});

  @override
  ConsumerState<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends ConsumerState<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  late VehicleType _selectedType;
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _regController;
  late final TextEditingController _yearController;
  late final TextEditingController _colorController;
  late int _seatCapacity;
  late String _status;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.vehicle.type;
    _makeController = TextEditingController(text: widget.vehicle.make);
    _modelController = TextEditingController(text: widget.vehicle.model);
    _regController = TextEditingController(
      text: widget.vehicle.registrationNumber,
    );
    _yearController = TextEditingController(
      text: widget.vehicle.year.toString(),
    );
    _colorController = TextEditingController(text: widget.vehicle.color);
    _seatCapacity = widget.vehicle.seatCapacity;
    _status = widget.vehicle.status;
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _regController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final parsedYear = int.parse(_yearController.text.trim());
      final normalizedReg = _regController.text
          .trim()
          .replaceAll(' ', '')
          .toUpperCase();

      await ref
          .read(vehiclesProvider.notifier)
          .updateVehicle(
            id: widget.vehicle.id,
            registrationNumber: normalizedReg,
            vehicleType: _selectedType.code,
            make: _makeController.text.trim(),
            model: _modelController.text.trim(),
            year: parsedYear,
            color: _colorController.text.trim(),
            seatCapacity: _seatCapacity,
            status: _status,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle updated successfully!'),
            backgroundColor: AppColors.primaryForest,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('ApiException: ', '')),
            backgroundColor: AppColors.mutedRust,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(title: 'Edit Vehicle'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Live Vehicle Illustration Preview
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 90,
                        alignment: Alignment.center,
                        child: VehicleIcon.illustration(
                          type: _selectedType,
                          width: 140,
                          height: 80,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _selectedType.displayName,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_selectedType.categoryGroup.displayName} \u2022 Capacity: $_seatCapacity seats',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                Card(
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
                        Text(
                          'Update Vehicle Details',
                          style: AppTypography.cardTitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Update vehicle specifications and active fleet status.',
                          style: AppTypography.secondary.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Vehicle Type Dropdown
                        Text(
                          'Vehicle Category',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.warmBackground,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<VehicleType>(
                              value: _selectedType,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textPrimary,
                              ),
                              items: VehicleType.values.map((type) {
                                return DropdownMenuItem<VehicleType>(
                                  value: type,
                                  child: Row(
                                    children: [
                                      VehicleIcon.illustration(
                                        type: type,
                                        width: 32,
                                        height: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          type.displayName,
                                          style: AppTypography.bodyMedium.copyWith(
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedType = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Status Toggle
                        Text(
                          'Status',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.warmBackground,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _status,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                  value: 'active',
                                  child: Text('Active'),
                                ),
                                DropdownMenuItem(
                                  value: 'inactive',
                                  child: Text('Inactive'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _status = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Make
                        AppTextField(
                          label: 'Make',
                          hint: 'e.g. Maruti Suzuki, Hyundai, Tata, Honda',
                          controller: _makeController,
                          validator: (val) =>
                              val == null || val.trim().isEmpty
                                  ? 'Make required'
                                  : null,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Model
                        AppTextField(
                          label: 'Model',
                          hint: 'e.g. Swift VXI, Creta, Nexon, Activa',
                          controller: _modelController,
                          validator: (val) =>
                              val == null || val.trim().isEmpty
                                  ? 'Model required'
                                  : null,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Registration Number
                        AppTextField(
                          label: 'Registration Number',
                          hint: 'e.g. GJ01AB1234',
                          controller: _regController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9\s]'),
                            ),
                            UpperCaseTextFormatter(),
                          ],
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Registration number required';
                            }
                            final clean = val.replaceAll(' ', '');
                            if (clean.length < 4 || clean.length > 15) {
                              return 'Enter a valid registration number (4-15 chars)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Year
                        AppTextField(
                          label: 'Manufacturing Year',
                          hint: 'e.g. 2023',
                          controller: _yearController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Year required';
                            }
                            final y = int.tryParse(val.trim());
                            final currentYear = DateTime.now().year;
                            if (y == null || y < 1990 || y > currentYear + 1) {
                              return 'Year must be between 1990 and ${currentYear + 1}';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Color
                        AppTextField(
                          label: 'Color',
                          hint: 'e.g. Arctic White, Silky Silver, Black',
                          controller: _colorController,
                          validator: (val) =>
                              val == null || val.trim().isEmpty
                                  ? 'Color required'
                                  : null,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Seat Capacity Counter
                        Text(
                          'Available Seat Capacity',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warmBackground,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.airline_seat_recline_normal_rounded,
                                color: AppColors.primaryForest,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$_seatCapacity ${_seatCapacity == 1 ? "Passenger Seat" : "Passenger Seats"}',
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                ),
                                color: _seatCapacity > 1
                                    ? AppColors.primaryForest
                                    : AppColors.textSecondary.withValues(
                                        alpha: 0.3,
                                      ),
                                onPressed: _seatCapacity > 1
                                    ? () => setState(() => _seatCapacity--)
                                    : null,
                              ),
                              Text(
                                '$_seatCapacity',
                                style: AppTypography.screenTitle.copyWith(
                                  fontSize: 18,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                ),
                                color: _seatCapacity < 20
                                    ? AppColors.primaryForest
                                    : AppColors.textSecondary.withValues(
                                        alpha: 0.3,
                                      ),
                                onPressed: _seatCapacity < 20
                                    ? () => setState(() => _seatCapacity++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Vehicle Availability Status Switch
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warmBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Active for Carpooling',
                                      style: AppTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'When inactive, this vehicle will not be selectable for offering rides.',
                                      style: AppTypography.secondary.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _status == 'active',
                                activeTrackColor: AppColors.primaryForest,
                                onChanged: (val) {
                                  setState(() {
                                    _status = val ? 'active' : 'inactive';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Save Changes CTA
                PrimaryButton(
                  text: 'Save Changes',
                  isLoading: _isSubmitting,
                  onPressed: _save,
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
