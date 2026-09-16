import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/design_system.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../bookings/domain/booking_model.dart';
import '../../../bookings/presentation/bookings_provider.dart';

class PaymentCheckoutScreen extends ConsumerStatefulWidget {
  final BookingModel booking;

  const PaymentCheckoutScreen({super.key, required this.booking});

  @override
  ConsumerState<PaymentCheckoutScreen> createState() =>
      _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends ConsumerState<PaymentCheckoutScreen> {
  String _selectedMethod = 'upi';
  bool _isLoading = false;
  String? _errorMessage;

  final double _platformFee = 20.0;
  final double _tollSplit = 40.0;

  double get _baseFare => widget.booking.totalContribution;
  double get _totalAmount => _baseFare + _platformFee + _tollSplit;

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);

      // Step 1: Create Payment Order
      final orderRes = await apiClient.post(
        '/payments/order',
        body: {'bookingId': widget.booking.id},
      );

      String? transactionId;
      if (orderRes is Map<String, dynamic>) {
        final tx = orderRes['transaction'];
        if (tx is Map<String, dynamic>) {
          transactionId = (tx['id'] ?? tx['_id'])?.toString();
        }
      }

      if (transactionId == null || transactionId.isEmpty) {
        throw Exception('Failed to initialize payment order.');
      }

      // Step 2: Verify in Escrow Sandbox
      final verifyRes = await apiClient.post(
        '/payments/verify',
        body: {
          'transactionId': transactionId,
          'gatewayReference': 'sayan_pay_${DateTime.now().millisecondsSinceEpoch}',
          'method': _selectedMethod,
        },
      );

      if (verifyRes is Map<String, dynamic> && verifyRes['success'] == true) {
        // Refresh booking in global provider
        await ref
            .read(bookingsNotifierProvider.notifier)
            .fetchBookingById(widget.booking.id);

        if (!mounted) return;

        setState(() => _isLoading = false);

        // Show Success Modal
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.softForest,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primaryForest,
                    size: 38,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  'Payment Authorized',
                  style: AppTypography.screenTitle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '₹${_totalAmount.toStringAsFixed(0)} placed securely in escrow. Funds will only be released to the driver upon successful trip completion.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SahyanButton(
                  text: 'View Boarding Pass',
                  isFullWidth: true,
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    context.go('/active-journey', extra: widget.booking);
                  },
                ),
              ],
            ),
          ),
        );
      } else {
        throw Exception('Verification failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Trip Payment & Escrow',
        subtitle: 'Secure Contribution Checkout',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Shield Guarantee
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryForest.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: AppColors.primaryForest.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primaryForest,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sahyān Escrow Protection',
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 14,
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your contribution is held securely in escrow until destination is verified.',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.base),

              // Fare Breakdown Card
              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fare Contribution Breakdown',
                      style: AppTypography.sectionHeader.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    _buildRow(
                      'Ride Seat Contribution (${widget.booking.requestedSeats} Seat${widget.booking.requestedSeats > 1 ? 's' : ''})',
                      '₹${_baseFare.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRow(
                      'Safety & Platform Fee',
                      '₹${_platformFee.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRow(
                      'Toll & FASTag Pool Split',
                      '₹${_tollSplit.toStringAsFixed(0)}',
                    ),
                    const Divider(height: AppSpacing.xl, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Payable',
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${_totalAmount.toStringAsFixed(0)}',
                          style: AppTypography.screenTitle.copyWith(
                            fontSize: 22,
                            color: AppColors.primaryForest,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.base),

              // Payment Method Selector
              Text(
                'Select Payment Gateway',
                style: AppTypography.sectionHeader.copyWith(fontSize: 15),
              ),
              const SizedBox(height: AppSpacing.sm),

              _buildPaymentOption(
                id: 'upi',
                title: 'UPI Instant (GPay / PhonePe / Paytm)',
                subtitle: 'Zero fee direct escrow transfer',
                icon: Icons.qr_code_2_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPaymentOption(
                id: 'card',
                title: 'Credit / Debit Card',
                subtitle: 'Visa, MasterCard, RuPay with 3D Secure',
                icon: Icons.credit_card_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPaymentOption(
                id: 'netbanking',
                title: 'Net Banking',
                subtitle: 'All major Indian scheduled banks',
                icon: Icons.account_balance_rounded,
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.mutedRust.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                      color: AppColors.mutedRust.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.mutedRust,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.mutedRust,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              SahyanButton(
                text: _isLoading
                    ? 'Authorizing Secure Payment...'
                    : 'Authorize ₹${_totalAmount.toStringAsFixed(0)} in Escrow',
                icon: Icons.lock_outline_rounded,
                isFullWidth: true,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _processPayment,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.secondary),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.softForest.withValues(alpha: 0.35) : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: isSelected ? AppColors.primaryForest : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryForest : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppColors.deepForest : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryForest
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
