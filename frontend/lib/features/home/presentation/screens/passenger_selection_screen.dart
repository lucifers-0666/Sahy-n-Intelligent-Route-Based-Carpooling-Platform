import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';

/// Dedicated Passenger Selection Screen for Sahyan.
/// Allows passengers to specify how many seats they are requesting for their journey,
/// enforcing the platform 1 to 6 seat booking boundary.
class PassengerSelectionScreen extends StatefulWidget {
  final int initialSeats;

  const PassengerSelectionScreen({
    super.key,
    this.initialSeats = 2,
  });

  @override
  State<PassengerSelectionScreen> createState() =>
      _PassengerSelectionScreenState();
}

class _PassengerSelectionScreenState extends State<PassengerSelectionScreen> {
  late int _seats;
  bool _minusPressed = false;
  bool _plusPressed = false;

  static const int minSeats = 1;
  static const int maxSeats = 6;

  @override
  void initState() {
    super.initState();
    _seats = widget.initialSeats.clamp(minSeats, maxSeats);
  }

  void _decrement() {
    if (_seats <= minSeats) return;
    HapticFeedback.selectionClick();
    setState(() {
      _minusPressed = true;
      _seats--;
    });
    Future.delayed(
      const Duration(milliseconds: 120),
      () => setState(() => _minusPressed = false),
    );
  }

  void _increment() {
    if (_seats >= maxSeats) return;
    HapticFeedback.selectionClick();
    setState(() {
      _plusPressed = true;
      _seats++;
    });
    Future.delayed(
      const Duration(milliseconds: 120),
      () => setState(() => _plusPressed = false),
    );
  }

  void _confirmAndReturn() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_seats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.primaryText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Select Passengers',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryText,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Context / Explanation Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.border,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.people_alt_outlined,
                              color: AppColors.deepEmerald,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'How many seats do you need?',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryText,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Select the number of passenger seats requested for your carpool journey. Contributions are calculated per seat.',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12.5,
                                    color: AppColors.mutedText,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Large Tactile Stepper Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.border,
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryText.withValues(alpha: 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'RESERVED SEATS',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.mutedText,
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Decrement Button
                              AnimatedScale(
                                scale: _minusPressed ? 0.88 : 1.0,
                                duration: const Duration(milliseconds: 120),
                                child: Material(
                                  color: _seats > minSeats
                                      ? AppColors.lightSurface
                                      : const Color(0xFFF3F5F4),
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    onTap: _seats > minSeats ? _decrement : null,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _seats > minSeats
                                              ? AppColors.border
                                              : Colors.transparent,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.remove_rounded,
                                        size: 24,
                                        color: _seats > minSeats
                                            ? AppColors.primaryText
                                            : AppColors.border,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 32),

                              // Big Number Display
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$_seats',
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 52,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.deepEmerald,
                                      letterSpacing: -1.0,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _seats == 1 ? 'Passenger' : 'Passengers',
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 32),

                              // Increment Button
                              AnimatedScale(
                                scale: _plusPressed ? 0.88 : 1.0,
                                duration: const Duration(milliseconds: 120),
                                child: Material(
                                  color: _seats < maxSeats
                                      ? AppColors.deepEmerald
                                      : const Color(0xFFF3F5F4),
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    onTap: _seats < maxSeats ? _increment : null,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.add_rounded,
                                        size: 24,
                                        color: _seats < maxSeats
                                            ? Colors.white
                                            : AppColors.border,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Visual Seat Graphic
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(maxSeats, (index) {
                              final seatNum = index + 1;
                              final isSelected = seatNum <= _seats;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 34,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryLight
                                      : AppColors.lightSurface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.deepEmerald
                                        : AppColors.border,
                                    width: isSelected ? 1.4 : 0.8,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_rounded,
                                      size: 16,
                                      color: isSelected
                                          ? AppColors.deepEmerald
                                          : AppColors.mutedText,
                                    ),
                                    Text(
                                      '$seatNum',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? AppColors.deepEmerald
                                            : AppColors.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Luggage & Travel Notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.softMint.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.luggage_outlined,
                            size: 18,
                            color: AppColors.deepEmerald,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Luggage Guideline',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.deepEmerald,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Standard allowance accommodates 1 medium bag (up to 15 kg) per reserved passenger seat.',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 11.5,
                                    color: AppColors.primaryText.withValues(alpha: 0.85),
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
            ),

            // Bottom Confirm Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.8),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _confirmAndReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepEmerald,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Confirm $_seats Passenger Seat${_seats == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
