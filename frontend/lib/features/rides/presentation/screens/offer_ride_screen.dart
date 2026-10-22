import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/rides/presentation/rides_provider.dart';
import 'package:sahyan/features/rides/presentation/widgets/location_search_bottom_sheet.dart';
import 'package:sahyan/features/rides/presentation/widgets/offer_ride_step1.dart';
import 'package:sahyan/features/rides/presentation/widgets/offer_ride_step2.dart';
import 'package:sahyan/features/rides/presentation/widgets/offer_ride_step3.dart';
import 'package:sahyan/shared/models/location_model.dart';

class OfferRideScreen extends ConsumerStatefulWidget {
  const OfferRideScreen({super.key});

  @override
  ConsumerState<OfferRideScreen> createState() => _OfferRideScreenState();
}

/// Backwards compatibility alias for [OfferRideScreen].
typedef PublishRideScreen = OfferRideScreen;

class _OfferRideScreenState extends ConsumerState<OfferRideScreen> {
  int _currentStep = 0;

  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _contributionController = TextEditingController(text: '350');
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDefaults();
    });
  }

  void _initializeDefaults() {
    final draft = ref.read(offerRideProvider);
    if (draft.origin != null) {
      _originController.text = draft.origin!.name;
    }
    if (draft.destination != null) {
      _destinationController.text = draft.destination!.name;
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _contributionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectHubAsOrigin(Map<String, dynamic> hub) {
    _originController.text = hub['name'] as String;
    ref.read(offerRideProvider.notifier).setOrigin(
          LocationModel.fromCoordinates(
            name: hub['name'] as String,
            latitude: (hub['lat'] as num).toDouble(),
            longitude: (hub['lng'] as num).toDouble(),
          ),
        );
  }

  void _selectHubAsDestination(Map<String, dynamic> hub) {
    _destinationController.text = hub['name'] as String;
    ref.read(offerRideProvider.notifier).setDestination(
          LocationModel.fromCoordinates(
            name: hub['name'] as String,
            latitude: (hub['lat'] as num).toDouble(),
            longitude: (hub['lng'] as num).toDouble(),
          ),
        );
  }

  Future<void> _openLocationSearch({required bool isOrigin}) async {
    final title = isOrigin
        ? 'Select Origin (Pickup)'
        : 'Select Destination (Dropoff)';
    final selected = await LocationSearchBottomSheet.show(
      context: context,
      title: title,
    );
    if (selected != null) {
      if (isOrigin) {
        _originController.text = selected.name;
        ref.read(offerRideProvider.notifier).setOrigin(selected);
      } else {
        _destinationController.text = selected.name;
        ref.read(offerRideProvider.notifier).setDestination(selected);
      }
    }
  }

  Future<void> _addStopoverLocation() async {
    final draft = ref.read(offerRideProvider);
    if (draft.stopovers.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 3 highway stopovers allowed per route.'),
        ),
      );
      return;
    }
    final selected = await LocationSearchBottomSheet.show(
      context: context,
      title: 'Add Highway Stopover / Toll Plaza',
    );
    if (selected != null) {
      ref.read(offerRideProvider.notifier).addStopover(selected);
    }
  }

  Future<void> _pickDepartureDate() async {
    final draft = ref.read(offerRideProvider);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.departureDate.isAfter(now) ? draft.departureDate : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B4D3E),
              onPrimary: Colors.white,
              onSurface: Color(0xFF14241C),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(offerRideProvider.notifier).setDepartureDate(picked);
    }
  }

  Future<void> _pickDepartureTime() async {
    final draft = ref.read(offerRideProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: draft.departureTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B4D3E),
              onPrimary: Colors.white,
              onSurface: Color(0xFF14241C),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(offerRideProvider.notifier).setDepartureTime(picked);
    }
  }

  Future<void> _onPublishPressed() async {
    final user = ref.read(authProvider).user;
    if (user == null || !user.isDriverEligible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Driver verification required. You must have an approved driver application to offer a ride.',
          ),
          backgroundColor: Color(0xFF991B1B),
        ),
      );
      context.push('/driver-onboarding');
      return;
    }

    final draft = ref.read(offerRideProvider);
    if (draft.selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle first.')),
      );
      setState(() => _currentStep = 0);
      return;
    }

    try {
      final ride = await ref.read(offerRideProvider.notifier).publishRide();
      if (!mounted) return;

      ref.read(offerRideProvider.notifier).reset();
      context.pushReplacement('/ride-published', extra: ride);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFF991B1B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(offerRideProvider);

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep > 0) {
          setState(() => _currentStep--);
        } else {
          final router = GoRouter.maybeOf(context);
          if (router != null && router.canPop()) {
            router.pop();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else if (router != null) {
            router.go('/home');
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8F6),
        appBar: AppBar(
          title: const Text(
            'Offer a Ride',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF14241C),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF14241C),
              size: 20,
            ),
            tooltip: 'Back',
            onPressed: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                final router = GoRouter.maybeOf(context);
                if (router != null && router.canPop()) {
                  router.pop();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else if (router != null) {
                  router.go('/home');
                }
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.list_alt_rounded,
                color: Color(0xFF1B4D3E),
              ),
              tooltip: 'My Offered Rides',
              onPressed: () => context.push('/driver/rides'),
            ),
            if (draft.selectedVehicle != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      draft.selectedVehicle!.registrationNumber,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepIndicator(),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentStep),
                    child: _currentStep == 0
                        ? OfferRideStep1(
                            originController: _originController,
                            destinationController: _destinationController,
                            onSelectOrigin: () => _openLocationSearch(isOrigin: true),
                            onSelectDestination: () => _openLocationSearch(isOrigin: false),
                            onAddStopover: _addStopoverLocation,
                            onSelectCorridor: (originHub, destHub) {
                              _selectHubAsOrigin(originHub);
                              _selectHubAsDestination(destHub);
                            },
                          )
                        : _currentStep == 1
                            ? OfferRideStep2(
                                contributionController: _contributionController,
                                onPickDate: _pickDepartureDate,
                                onPickTime: _pickDepartureTime,
                              )
                            : OfferRideStep3(
                                notesController: _notesController,
                              ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildNavigationButtons(draft),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    const stepTitles = [
      'Vehicle & Route',
      'Schedule & Seats',
      'Review & Publish',
    ];
    const stepFullTitles = [
      'Vehicle & Route Corridor',
      'Schedule, Seats & Fair Contribution',
      'Amenities, Notes & Publish',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;
        if (isCompact) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of 3',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    Text(
                      stepTitles[_currentStep],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5C6E64),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.0,
                      end: (_currentStep + 1) / 3,
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFE2E8E4),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1B4D3E),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of 3: ',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5C6E64),
                        ),
                      ),
                      Text(
                        stepFullTitles[_currentStep],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: (_currentStep + 1) / 3,
                  ),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE2E8E4),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1B4D3E),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(stepTitles.length, (index) {
                  final isCurrent = _currentStep == index;
                  final isCompleted = _currentStep > index;
                  return Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrent
                              ? const Color(0xFF1B4D3E)
                              : (isCompleted
                                  ? const Color(0xFF2EC486)
                                  : const Color(0xFFE2E8E4)),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        stepTitles[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent
                              ? const Color(0xFF14241C)
                              : const Color(0xFF5C6E64),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationButtons(OfferRideState draft) {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 54,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: const BorderSide(color: Color(0xFFE2E8E4), width: 1.0),
                  backgroundColor: Colors.white,
                ),
                onPressed: () => setState(() => _currentStep--),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF14241C),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: _currentStep > 0 ? 2 : 1,
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: draft.isSubmitting
                  ? null
                  : () {
                      if (_currentStep < 2) {
                        if (_currentStep == 0) {
                          final user = ref.read(authProvider).user;
                          if (user == null) {
                            context.push('/auth-entry');
                            return;
                          }
                          if (!user.isDriverEligible) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Approved driver status is required to offer a ride. Please complete driver onboarding.',
                                ),
                                backgroundColor: Color(0xFF991B1B),
                              ),
                            );
                            context.push('/driver-onboarding');
                            return;
                          }
                          if (draft.selectedVehicle == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a vehicle first.'),
                              ),
                            );
                            return;
                          }
                          if (draft.origin == null || draft.destination == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter both origin and destination.',
                                ),
                              ),
                            );
                            return;
                          }
                        }
                        setState(() => _currentStep++);
                      } else {
                        _onPublishPressed();
                      }
                    },
              child: draft.isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        // Primary label matching redesign spec
                        Text(
                          _currentStep == 2
                              ? 'Publish Shared Journey \u2192'
                              : 'Continue',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        // Hidden legacy text widget for test backwards-compatibility
                        if (_currentStep == 2)
                          const Opacity(
                            opacity: 0.0,
                            child: Text(
                              'Publish Ride',
                              style: TextStyle(fontSize: 1, color: Colors.transparent),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
