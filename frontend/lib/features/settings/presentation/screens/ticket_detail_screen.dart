import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/widgets/sahyan_app_bar.dart';
import '../../../../core/widgets/sahyan_card.dart';
import '../../domain/support_ticket_model.dart';
import '../support_tickets_provider.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  final SupportTicketModel? initialTicket;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
    this.initialTicket,
  });

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _replyController = TextEditingController();
  bool _isSending = false;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supportTicketsProvider.notifier).loadTicketDetails(widget.ticketId);
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _handleSendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    final success = await ref.read(supportTicketsProvider.notifier).addReply(widget.ticketId, text);

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        _replyController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit reply. Please try again.'),
            backgroundColor: AppColors.mutedRust,
          ),
        );
      }
    }
  }

  Future<void> _handleResolveTicket() async {
    setState(() => _isResolving = true);
    final success = await ref.read(supportTicketsProvider.notifier).resolveTicket(widget.ticketId);

    if (mounted) {
      setState(() => _isResolving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support ticket marked as resolved.'),
            backgroundColor: AppColors.primaryForest,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportTicketsProvider);
    final ticket = state.selectedTicket ?? widget.initialTicket;
    final l10n = context.l10n;

    if (ticket == null) {
      return Scaffold(
        backgroundColor: AppColors.warmBackground,
        appBar: SahyanAppBar(title: l10n.ticketDetailTitle, showBackButton: true),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryForest),
        ),
      );
    }

    final dateFormat = DateFormat('hh:mm a, dd MMM');
    final isClosed = ticket.status == 'closed';
    final isResolved = ticket.status == 'resolved';

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: SahyanAppBar(
        title: ticket.ticketNumber,
        subtitle: '${l10n.categoryLabel}: ${ticket.category.replaceAll('_', ' ')}',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Ticket Header Summary
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerMargin,
                AppSpacing.sm,
                AppSpacing.containerMargin,
                AppSpacing.xs,
              ),
              child: SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ticket.subject,
                            style: AppTypography.cardTitle.copyWith(fontSize: 15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(ticket.status, l10n),
                      ],
                    ),
                    if (ticket.bookingPickup != null && ticket.bookingDrop != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.softForest,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(
                          '${l10n.corridorLabel}: ${ticket.bookingPickup} → ${ticket.bookingDrop}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryForest,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                    if (!isResolved && !isClosed) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _isResolving ? null : _handleResolveTicket,
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                          label: Text(
                            l10n.markResolvedAction,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Message Thread
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.containerMargin,
                  vertical: AppSpacing.sm,
                ),
                itemCount: ticket.messages.length,
                itemBuilder: (context, index) {
                  final msg = ticket.messages[index];
                  final isAdmin = msg.sender == 'admin';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment:
                          isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isAdmin ? l10n.supportTeamSender : msg.senderName,
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isAdmin ? AppColors.primaryForest : AppColors.textPrimary,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dateFormat.format(msg.createdAt),
                              style: AppTypography.caption.copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.82,
                          ),
                          decoration: BoxDecoration(
                            color: isAdmin ? AppColors.softForest : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(AppRadii.lg),
                              topRight: const Radius.circular(AppRadii.lg),
                              bottomLeft: Radius.circular(isAdmin ? 2 : AppRadii.lg),
                              bottomRight: Radius.circular(isAdmin ? AppRadii.lg : 2),
                            ),
                            border: Border.all(
                              color: isAdmin
                                  ? AppColors.primaryForest.withValues(alpha: 0.2)
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            msg.message,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isAdmin ? AppColors.darkEmerald : AppColors.textPrimary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Reply Composer
            if (!isClosed)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        maxLines: 2,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: l10n.replyMessageHint,
                          hintStyle: AppTypography.caption,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            borderSide: const BorderSide(
                              color: AppColors.primaryForest,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryForest,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSending ? null : _handleSendReply,
                      icon: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, size: 20),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                color: Colors.grey.shade100,
                child: Center(
                  child: Text(
                    l10n.ticketClosedNotice,
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
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
