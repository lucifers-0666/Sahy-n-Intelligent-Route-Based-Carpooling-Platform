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
import 'package:sahyan/features/vehicles/domain/vehicle_type.dart';
import 'package:sahyan/features/vehicles/presentation/vehicle_provider.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  VehicleType _selectedType = VehicleType.hatchback;
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _regController = TextEditingController();
  final _yearController = TextEditingController(text: '2023');
  final _colorController = TextEditingController();
  int _seatCapacity = 4;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _regController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _onVehicleTypeChanged(VehicleType type) {
    setState(() {
      _selectedType = type;
      _seatCapacity = type.defaultSeatCapacity;
    });
  }

  Future<void> _submit() async {
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
          .addVehicle(
            registrationNumber: normalizedReg,
            vehicleType: _selectedType.code,
            make: _makeController.text.trim(),
            model: _modelController.text.trim(),
            year: parsedYear,
            color: _colorController.text.trim(),
            seatCapacity: _seatCapacity,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vehicle registered successfully! Driver capability enabled.',
            ),
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
      appBar: const SahyanAppBar(title: 'Add Vehicle'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Live Vehicle Illustration Preview Card
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedType.displayName,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_selectedType.isElectric) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.softForest,
                                borderRadius: BorderRadius.circular(AppRadii.full),
                              ),
                              child: Text(
                                'EV',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_selectedType.categoryGroup.displayName} \u2022 Default Capacity: ${_selectedType.defaultSeatCapacity} seats',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Form Container
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
                          'Vehicle Information',
                          style: AppTypography.cardTitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select your vehicle category and provide official registration details.',
                          style: AppTypography.secondary.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Vehicle Type Selector Dropdown with all 19 categories
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
                                          '${type.displayName} (${type.categoryGroup.displayName})',
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
                                  _onVehicleTypeChanged(val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Make Field
                        AppTextField(
                          label: 'Make',
                          hint: 'e.g. Maruti Suzuki, Hyundai, Tata, Honda',
                          controller: _makeController,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Make required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Model Field
                        AppTextField(
                          label: 'Model',
                          hint: 'e.g. Swift VXI, Creta, Nexon, Activa',
                          controller: _modelController,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Model required';
                            }
                            return null;
                          },
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
                              return 'Registration number is required';
                            }
                            final clean = val.replaceAll(' ', '');
                            if (clean.length < 4 || clean.length > 15) {
                              return 'Enter a valid registration number (4-15 chars)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Year Field
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

                        // Color Field
                        AppTextField(
                          label: 'Color',
                          hint: 'e.g. Arctic White, Silky Silver, Black',
                          controller: _colorController,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Color required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Seat Capacity Counter
                        Text(
                          'Available Passenger Seat Capacity',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Number of passenger seats you can offer (excluding driver).',
                          style: AppTypography.caption,
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
                                        alpha: 0.5,
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
                                        alpha: 0.5,
                                      ),
                                onPressed: _seatCapacity < 20
                                    ? () => setState(() => _seatCapacity++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Register CTA Button
                PrimaryButton(
                  text: 'Register Vehicle',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
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
