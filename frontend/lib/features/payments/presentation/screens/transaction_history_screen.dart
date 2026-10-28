import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/widgets/sahyan_app_bar.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../core/widgets/sahyan_card.dart';
import '../../domain/transaction_model.dart';
import '../transaction_provider.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionLedgerProvider);
    final notifier = ref.read(transactionLedgerProvider.notifier);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: SahyanAppBar(
        title: l10n.transactionHistoryTitle,
        subtitle: l10n.escrowLedgerSubtitle,
        showBackButton: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryForest,
          onRefresh: () => notifier.loadTransactions(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top Financial Summary Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerMargin,
                    AppSpacing.md,
                    AppSpacing.containerMargin,
                    AppSpacing.sm,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.darkEmerald, AppColors.deepEmerald],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryForest.withValues(
                            alpha: 0.18,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.totalContributionsLabel,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.softForest,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${state.totalAmount.toStringAsFixed(0)}',
                          style: AppTypography.screenTitle.copyWith(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Divider(color: Colors.white24, height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.lock_clock_outlined,
                              size: 16,
                              color: AppColors.softForest,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${l10n.heldInEscrowLabel}: ₹${state.escrowHeld.toStringAsFixed(0)} · ${l10n.escrowExplanationShort}',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.containerMargin,
                    vertical: AppSpacing.xs,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: l10n.filterAll,
                          status: 'all',
                          current: state.statusFilter,
                          onTap: () => notifier.setFilter('all'),
                        ),
                        _buildFilterChip(
                          label: l10n.filterInEscrow,
                          status: 'escrow_held',
                          current: state.statusFilter,
                          onTap: () => notifier.setFilter('escrow_held'),
                        ),
                        _buildFilterChip(
                          label: l10n.filterSettled,
                          status: 'settled_to_driver',
                          current: state.statusFilter,
                          onTap: () => notifier.setFilter('settled_to_driver'),
                        ),
                        _buildFilterChip(
                          label: l10n.filterRefunded,
                          status: 'refunded',
                          current: state.statusFilter,
                          onTap: () => notifier.setFilter('refunded'),
                        ),
                        _buildFilterChip(
                          label: l10n.filterFailed,
                          status: 'failed',
                          current: state.statusFilter,
                          onTap: () => notifier.setFilter('failed'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Transaction List or States
              if (state.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryForest,
                    ),
                  ),
                )
              else if (state.errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: AppColors.mutedRust,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.errorLoadingTransactions,
                            style: AppTypography.cardTitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.errorMessage!,
                            textAlign: TextAlign.center,
                            style: AppTypography.caption,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SahyanButton(
                            text: l10n.retryAction,
                            onPressed: () => notifier.loadTransactions(),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (state.transactions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.noTransactionsFound,
                            style: AppTypography.cardTitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.noTransactionsFoundSubtitle,
                            textAlign: TextAlign.center,
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.containerMargin),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final tx = state.transactions[index];
                      return _buildTransactionCard(context, tx, l10n);
                    }, childCount: state.transactions.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String status,
    required String current,
    required VoidCallback onTap,
  }) {
    final isSelected = status == current;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.full),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryForest : Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.full),
            border: Border.all(
              color: isSelected ? AppColors.primaryForest : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionModel tx,
    dynamic l10n,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SahyanCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Corridor and Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.pickupName != null && tx.dropName != null
                            ? '${tx.pickupName} → ${tx.dropName}'
                            : l10n.corridorContributionLabel,
                        style: AppTypography.cardTitle.copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormat.format(tx.createdAt),
                        style: AppTypography.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '₹${tx.amount.toStringAsFixed(0)}',
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryForest,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.border, height: 12),

            // Middle Badges: Status and Environment
            Row(
              children: [
                _buildStatusBadge(tx.status, l10n),
                const SizedBox(width: AppSpacing.xs),
                if (tx.isSandbox)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softBrass,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                        color: AppColors.champagneGold,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      l10n.sandboxSimulatedBadge,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softForest,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                        color: AppColors.primaryForest,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      l10n.liveClearingBadge,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryForest,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Footer Reference & View Receipt Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${l10n.refLabel}: ${tx.gatewayReference ?? tx.gatewayOrderId ?? tx.id}',
                    style: AppTypography.caption.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (tx.bookingId != null && tx.bookingId!.isNotEmpty)
                  InkWell(
                    onTap: () {
                      context.push('/trip-receipt', extra: null);
                    },
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.receipt_outlined,
                            size: 14,
                            color: AppColors.primaryForest,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.viewReceiptAction,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TransactionStatus status, dynamic l10n) {
    Color bg = AppColors.chipBackground;
    Color fg = AppColors.textPrimary;
    String label = '';

    switch (status) {
      case TransactionStatus.escrowHeld:
        bg = AppColors.softBrass;
        fg = const Color(0xFF7A5900);
        label = l10n.statusInEscrow;
        break;
      case TransactionStatus.settledToDriver:
        bg = AppColors.softForest;
        fg = AppColors.primaryForest;
        label = l10n.statusSettled;
        break;
      case TransactionStatus.refunded:
        bg = const Color(0xFFEFE6FD);
        fg = const Color(0xFF5521B5);
        label = l10n.statusRefunded;
        break;
      case TransactionStatus.disputed:
        bg = const Color(0xFFFFECE5);
        fg = AppColors.mutedRust;
        label = l10n.statusDisputed;
        break;
      case TransactionStatus.failed:
        bg = const Color(0xFFFFECE5);
        fg = AppColors.mutedRust;
        label = l10n.statusFailed;
        break;
      case TransactionStatus.pending:
        bg = const Color(0xFFEBF3FE);
        fg = const Color(0xFF1D58D8);
        label = l10n.statusPending;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
