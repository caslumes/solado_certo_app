import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/support/domain/entities/support_ticket.dart';
import 'package:solado_certo_app/features/support/domain/usecases/support_use_cases.dart';
import 'package:solado_certo_app/features/support/presentation/bloc/support_tickets_cubit.dart';
import 'package:solado_certo_app/features/support/presentation/components/support_ticket_status_chip.dart';
import 'package:solado_certo_app/features/support/presentation/pages/support_ticket_detail_page.dart';
import 'package:solado_certo_app/features/support/presentation/pages/support_ticket_form_page.dart';

class MySupportTicketsPage extends StatefulWidget {
  const MySupportTicketsPage({
    super.key,
    this.openTicket = _openTicket,
    this.openForm = _openForm,
  });

  final Future<void> Function(BuildContext context, String ticketId) openTicket;
  final Future<void> Function(BuildContext context) openForm;

  static Future<void> _openTicket(BuildContext context, String ticketId) =>
      Navigator.of(context).push(SupportTicketDetailPage.route(ticketId));

  static Future<void> _openForm(BuildContext context) =>
      Navigator.of(context).push(SupportTicketFormPage.route());

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => SupportTicketsCubit(
          getTicketsUseCase: getIt<GetSupportTicketsUseCase>(),
        )..load(),
        child: const MySupportTicketsPage(),
      ),
    );
  }

  @override
  State<MySupportTicketsPage> createState() => _MySupportTicketsPageState();
}

class _MySupportTicketsPageState extends State<MySupportTicketsPage> {
  static const _loadMoreExtent = 400.0;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < _loadMoreExtent) {
      context.read<SupportTicketsCubit>().loadMore();
    }
  }

  void _checkFill() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) _onScroll();
    });
  }

  Future<void> _thenReload(Future<void> navigation) async {
    final cubit = context.read<SupportTicketsCubit>();
    await navigation;
    if (!cubit.isClosed) cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: Theme.of(context).iconTheme,
        title: Text('Meus chamados'.toUpperCase(), style: textTheme.bodyMedium),
      ),
      body: BlocConsumer<SupportTicketsCubit, SupportTicketsState>(
        listenWhen: (previous, current) =>
            current.failure != null ||
            (current.status == SupportTicketsStatus.loaded &&
                current.tickets.length != previous.tickets.length),
        listener: (context, state) {
          final failure = state.failure;
          if (failure == null) return _checkFill();
          if (failure is UnauthorizedFailure) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            context.read<AuthBloc>().add(SignOutEvent());
            return;
          }
          if (state.status != SupportTicketsStatus.loaded) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(failure.message)));
        },
        builder: (context, state) => switch (state.status) {
          SupportTicketsStatus.loaded when state.tickets.isEmpty =>
            const _NoTickets(),
          SupportTicketsStatus.loaded => RefreshIndicator(
            onRefresh: context.read<SupportTicketsCubit>().load,
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.tickets.length + (state.loadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == state.tickets.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final ticket = state.tickets[index];
                return _TicketTile(
                  key: ValueKey(ticket.id),
                  ticket: ticket,
                  onTap: () =>
                      _thenReload(widget.openTicket(context, ticket.id)),
                );
              },
            ),
          ),
          SupportTicketsStatus.failure => _LoadError(failure: state.failure!),
          SupportTicketsStatus.loading || SupportTicketsStatus.initial =>
            const Center(child: CircularProgressIndicator()),
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ShoeTextButton(
            onPressed: () => _thenReload(widget.openForm(context)),
            text: 'Abrir chamado',
          ),
        ),
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({super.key, required this.ticket, required this.onTap});

  final SupportTicketEntity ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4.0,
          children: [
            Text(ticket.subject, style: textTheme.bodyMedium),
            SupportTicketStatusChip(status: ticket.status),
            Text(
              [
                ticket.category.label,
                if (ticket.orderNumber case final number?) 'Pedido $number',
              ].join(' · '),
              style: textTheme.bodySmall,
            ),
            Text(
              'Atualizado em ${formatDateTime(ticket.updatedAt)}',
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 12,
                color: AppColors.tertiaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoTickets extends StatelessWidget {
  const _NoTickets();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: context.read<SupportTicketsCubit>().load,
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 64),
          const Icon(
            Icons.support_agent,
            size: 48,
            color: AppColors.tertiaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum chamado',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Quando precisar de ajuda com um pedido, abra um chamado.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16.0,
          children: [
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            ShoeTextButton(
              onPressed: context.read<SupportTicketsCubit>().load,
              text: 'Tentar novamente',
            ),
          ],
        ),
      ),
    );
  }
}
