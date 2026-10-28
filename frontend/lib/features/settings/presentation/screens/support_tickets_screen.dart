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
import '../../domain/support_ticket_model.dart';
import '../support_tickets_provider.dart';
import '../widgets/create_ticket_sheet.dart';

class SupportTicketsScreen extends ConsumerWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportTicketsProvider);
    final notifier = ref.read(supportTicketsProvider.notifier);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: SahyanAppBar(
        title: l10n.supportTicketsTitle,
        subtitle: l10n.supportTicketsSubtitle,
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          l10n.newTicketButton,
          style: AppTypography.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: () {
          CreateTicketSheet.show(context);
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryForest,
          onRefresh: () => notifier.loadTickets(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerMargin,
                    AppSpacing.md,
                    AppSpacing.containerMargin,
                    AppSpacing.xs,
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
                          label: l10n.filterOpen,
                          status: 'open',
                          current: state.statusFilter,
                          onTap: () => notifier.setFilter('open'),
                        ),
                        _buildFilterChip(
                          label: l10n.filterInProgress,
                          status: 'in_progress',
                          current: state.statusFilter,
                          onTap: () => notifier.setFilter('in_progress'),
                        ),
                        _buildFilterChip(
                          label: l10n.filterResolved,
                          status: 'resolved',
                          current: state.statusFilter,
                          onTap: () => notifier.setFilter('resolved'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

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
                            l10n.errorLoadingTickets,
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
                            onPressed: () => notifier.loadTickets(),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (state.tickets.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.support_agent_outlined,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.noTicketsFound,
                            style: AppTypography.cardTitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.noTicketsFoundSubtitle,
                            textAlign: TextAlign.center,
                            style: AppTypography.caption,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SahyanButton(
                            text: l10n.createTicketPromptAction,
                            onPressed: () => CreateTicketSheet.show(context),
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
                      final ticket = state.tickets[index];
                      return _buildTicketCard(context, ticket, l10n);
                    }, childCount: state.tickets.length),
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

  Widget _buildTicketCard(
    BuildContext context,
    SupportTicketModel ticket,
    dynamic l10n,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SahyanCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: () {
          context.push('/support-tickets/${ticket.id}', extra: ticket);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ticket.ticketNumber,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryForest,
                    letterSpacing: 0.5,
                  ),
                ),
                _buildStatusBadge(ticket.status, l10n),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              ticket.subject,
              style: AppTypography.cardTitle.copyWith(fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              ticket.description,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.border, height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(ticket.updatedAt),
                  style: AppTypography.caption.copyWith(fontSize: 10),
                ),
                Row(
                  children: [
                    Text(
                      '${ticket.messages.length} ${l10n.messagesCountSuffix}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryForest,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.primaryForest,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, dynamic l10n) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'in_progress':
        bg = const Color(0xFFEBF3FE);
        fg = const Color(0xFF1D58D8);
        label = l10n.statusInProgress;
        break;
      case 'resolved':
        bg = AppColors.softForest;
        fg = AppColors.primaryForest;
        label = l10n.statusResolved;
        break;
      case 'closed':
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        label = l10n.statusClosed;
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = l10n.statusOpen;
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
