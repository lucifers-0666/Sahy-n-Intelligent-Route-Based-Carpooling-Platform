import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/core/theme/app_theme.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/booking_model.dart';
import '../../data/review_repository.dart';

class RateTripSheet extends ConsumerStatefulWidget {
  final BookingModel? booking;
  final String? driverName;

  const RateTripSheet({
    super.key,
    this.booking,
    this.driverName,
  });

  static Future<void> show(
    BuildContext context, {
    BookingModel? booking,
    String? driverName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: RateTripSheet(booking: booking, driverName: driverName),
      ),
    );
  }

  @override
  ConsumerState<RateTripSheet> createState() => _RateTripSheetState();
}

class _RateTripSheetState extends ConsumerState<RateTripSheet> {
  int _rating = 5;
  final Set<String> _selectedTags = {'Punctual', 'Smooth Driving', 'Clean Vehicle'};
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  static const List<String> _availableTags = [
    'Punctual',
    'Smooth Driving',
    'Clean Vehicle',
    'Polite',
    'Safe Route',
    'Great Music',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);
    final bookingId = widget.booking?.id ?? 'demo-booking-id';
    final repo = ref.read(reviewRepositoryProvider);

    await repo.submitReview(
      bookingId: bookingId,
      rating: _rating,
      tags: _selectedTags.toList(),
      comment: _commentController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you! Your $_rating-star review has been recorded.'),
          backgroundColor: SahyanColors.primaryDark,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driverName ??
        widget.booking?.ride?.driverName ??
        'Driver';

    return Container(
      decoration: const BoxDecoration(
        color: SahyanColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(color: SahyanColors.border, width: 0.8),
          left: BorderSide(color: SahyanColors.border, width: 0.8),
          right: BorderSide(color: SahyanColors.border, width: 0.8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: SahyanColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Text(
            'Rate Your Experience',
            style: AppTypography.cardTitle.copyWith(
              color: SahyanColors.primaryDark,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'How was your journey with $driver?',
            style: AppTypography.caption.copyWith(
              color: SahyanColors.textMuted,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Interactive 5-Star Picker with Tactile Bounce
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isSelected = starIndex <= _rating;

              return GestureDetector(
                onTap: () {
                  setState(() => _rating = starIndex);
                },
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('star-$starIndex-${_rating >= starIndex}'),
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 38,
                          color: isSelected ? const Color(0xFFFBBF24) : SahyanColors.border,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Multi-Select Feedback Chips
          Text(
            'What went well?',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: SahyanColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.map((tag) {
              final isChosen = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isChosen,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
                backgroundColor: SahyanColors.canvas,
                selectedColor: SahyanColors.primaryMint.withValues(alpha: 0.2),
                checkmarkColor: SahyanColors.primaryDark,
                side: BorderSide(
                  color: isChosen ? SahyanColors.primaryMint : SahyanColors.border,
                  width: 0.8,
                ),
                labelStyle: AppTypography.caption.copyWith(
                  color: isChosen ? SahyanColors.primaryDark : SahyanColors.textMain,
                  fontWeight: isChosen ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Optional comment
          TextField(
            controller: _commentController,
            maxLines: 3,
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Add an optional note about your trip experience...',
              hintStyle: AppTypography.caption.copyWith(color: SahyanColors.textMuted),
              filled: true,
              fillColor: SahyanColors.canvas,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: SahyanColors.border, width: 0.8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: SahyanColors.border, width: 0.8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: SahyanColors.primaryDark, width: 1.2),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 20),

          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: SahyanColors.primaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Submit Review',
                    style: AppTypography.button.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
