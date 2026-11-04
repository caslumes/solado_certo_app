import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/features/support/domain/enum/support_ticket_status.dart';

class SupportTicketStatusChip extends StatelessWidget {
  const SupportTicketStatusChip({super.key, required this.status});

  final SupportTicketStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      SupportTicketStatus.awaitingCustomer => (
        AppColors.warningBackgroundColor,
        AppColors.warningColor,
      ),
      SupportTicketStatus.resolved || SupportTicketStatus.closed => (
        AppColors.secondaryColor,
        AppColors.tertiaryColor,
      ),
      _ => (AppColors.primaryColor, Colors.white),
    };

    return DecoratedBox(
      decoration: BoxDecoration(color: background),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          status.label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: foreground),
        ),
      ),
    );
  }
}
