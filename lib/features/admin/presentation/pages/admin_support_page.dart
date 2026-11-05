import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/bloc/paged_list_cubit.dart';
import 'package:solado_certo_app/features/admin/presentation/components/admin_list_view.dart';
import 'package:solado_certo_app/features/support/domain/entities/support_ticket.dart';
import 'package:solado_certo_app/features/support/domain/usecases/support_use_cases.dart';
import 'package:solado_certo_app/features/support/presentation/components/support_ticket_status_chip.dart';
import 'package:solado_certo_app/features/support/presentation/pages/support_ticket_detail_page.dart';

typedef SupportQueueCubit =
    PagedListCubit<SupportQueueItemEntity, SupportQueueFilter>;
typedef SupportQueueState =
    PagedListState<SupportQueueItemEntity, SupportQueueFilter>;

class AdminSupportPage extends StatelessWidget {
  const AdminSupportPage({super.key, this.openTicket = _openTicket});

  final Future<void> Function(BuildContext context, String ticketId) openTicket;

  static Future<void> _openTicket(BuildContext context, String ticketId) =>
      Navigator.of(
        context,
      ).push(SupportTicketDetailPage.route(ticketId, admin: true));

  static Route<void> route() {
    final getQueue = getIt<GetSupportQueueUseCase>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => SupportQueueCubit(
          loader: (filter, page) async {
            final result = await getQueue.execute(filter, page);
            return (
              items: result.items,
              page: result.currentPage,
              hasNext: result.hasNext,
            );
          },
          filter: SupportQueueFilter.active,
        )..load(),
        child: const AdminSupportPage(),
      ),
    );
  }

  Future<void> _open(BuildContext context, String ticketId) async {
    final cubit = context.read<SupportQueueCubit>();
    await openTicket(context, ticketId);
    if (!cubit.isClosed) cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SupportQueueCubit>();

    return AdminScaffold(
      title: 'Suporte',
      body: AdminListView<SupportQueueItemEntity, SupportQueueFilter>(
        header: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: BlocBuilder<SupportQueueCubit, SupportQueueState>(
            buildWhen: (previous, current) => previous.filter != current.filter,
            builder: (context, state) => AdminFilterChips<SupportQueueFilter>(
              options: [
                for (final filter in SupportQueueFilter.values)
                  (filter, filter.label),
              ],
              selected: state.filter,
              onSelected: cubit.applyFilter,
            ),
          ),
        ),
        emptyText: 'Nenhum chamado nesta fila.',
        itemBuilder: (context, item) {
          final ticket = item.ticket;
          return AdminTile(
            key: ValueKey(ticket.id),
            title: ticket.subject,
            tags: [SupportTicketStatusChip(status: ticket.status)],
            lines: [
              [
                ticket.category.label,
                if (ticket.orderNumber case final number?) 'Pedido $number',
              ].join(' · '),
              'Aberto por ${item.openedBy}',
              switch (item.assignedTo) {
                _ when ticket.assignedToMe => 'Responsável: você',
                final name? => 'Responsável: $name',
                null => 'Sem responsável',
              },
            ],
            footnote: 'Atualizado em ${formatDateTime(ticket.updatedAt)}',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(context, ticket.id),
          );
        },
      ),
    );
  }
}
