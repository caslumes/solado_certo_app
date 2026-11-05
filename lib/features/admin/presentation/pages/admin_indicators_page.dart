import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/admin/domain/entities/admin_entities.dart';
import 'package:solado_certo_app/features/admin/domain/usecases/admin_use_cases.dart';
import 'package:solado_certo_app/features/admin/presentation/bloc/indicators_cubit.dart';
import 'package:solado_certo_app/features/admin/presentation/components/admin_list_view.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';

class AdminIndicatorsPage extends StatelessWidget {
  const AdminIndicatorsPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) =>
            IndicatorsCubit(getIndicatorsUseCase: getIt<GetIndicatorsUseCase>())
              ..load(),
        child: const AdminIndicatorsPage(),
      ),
    );
  }

  void _onStateChanged(BuildContext context, IndicatorsState state) {
    final failure = state.failure;
    if (failure is UnauthorizedFailure) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      context.read<AuthBloc>().add(SignOutEvent());
      return;
    }
    if (failure != null && state.indicators != null) {
      showAdminNotice(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<IndicatorsCubit>();

    return AdminScaffold(
      title: 'Indicadores',
      body: BlocConsumer<IndicatorsCubit, IndicatorsState>(
        listenWhen: (_, current) => current.failure != null,
        listener: _onStateChanged,
        builder: (context, state) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: AdminFilterChips<IndicatorPeriod>(
                options: [
                  for (final period in IndicatorPeriod.values)
                    (period, period.label),
                ],
                selected: state.period,
                onSelected: cubit.load,
              ),
            ),
            Expanded(
              child: switch (state) {
                IndicatorsState(:final indicators?) => RefreshIndicator(
                  onRefresh: cubit.load,
                  child: _Indicators(indicators: indicators),
                ),
                IndicatorsState(:final failure?) => AdminLoadError(
                  failure: failure,
                  onRetry: cubit.load,
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Indicators extends StatelessWidget {
  const _Indicators({required this.indicators});

  final IndicatorsEntity indicators;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final i = indicators;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Text(
          'De ${formatDate(i.from)} a ${formatDate(i.to)}',
          style: textTheme.bodySmall,
        ),
        const _Section('Pedidos'),
        _Stats([
          _Stat('Pedidos', '${i.orders}'),
          _Stat('Pedidos pagos', '${i.paidOrders}'),
          _Stat('Valor pago', formatCurrency(i.paidAmount)),
        ]),
        if (i.ordersByStatus.isNotEmpty)
          _Breakdown([
            for (final MapEntry(:key, :value) in i.ordersByStatus.entries)
              (key.label, '$value'),
          ]),
        const _Section('Pagamentos'),
        if (i.paymentsByStatus.isEmpty)
          Text('Nenhum pagamento no período.', style: textTheme.bodySmall)
        else
          _Breakdown([
            for (final MapEntry(:key, :value) in i.paymentsByStatus.entries)
              (key.label, '${value.count} · ${formatCurrency(value.amount)}'),
          ]),
        _Stats([
          _Stat(
            'Estornos recusados agora',
            '${i.refundsGivenUp}',
            highlight: i.refundsGivenUp > 0,
          ),
        ]),
        const _Section('Usuários'),
        _Stats([
          _Stat('Novos usuários', '${i.newUsers}'),
          _Stat('Bloqueados agora', '${i.blockedUsers}'),
          _Stat('Suspensos agora', '${i.suspendedUsers}'),
        ]),
        const _Section('Anúncios'),
        _Stats([
          _Stat('Novos anúncios', '${i.newAds}'),
          _Stat('Publicados agora', '${i.publishedAds}'),
        ]),
        const _Section('Suporte'),
        _Stats([
          _Stat('Chamados abertos', '${i.ticketsOpened}'),
          _Stat('Chamados resolvidos', '${i.ticketsResolved}'),
          _Stat(
            'Em aberto agora',
            '${i.openTickets}',
            highlight: i.openTickets > 0,
          ),
        ]),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;
}

class _Stats extends StatelessWidget {
  const _Stats(this.stats);

  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            for (final stat in stats)
              Container(
                width: width,
                padding: const EdgeInsets.all(12),
                color: stat.highlight
                    ? AppColors.warningBackgroundColor
                    : AppColors.secondaryColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4.0,
                  children: [
                    Text(stat.value, style: textTheme.headlineSmall),
                    Text(stat.label, style: textTheme.bodySmall),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown(this.rows);

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: textTheme.bodySmall)),
                  Text(value, style: textTheme.bodySmall),
                ],
              ),
            ),
          const Divider(height: 1, color: AppColors.secondaryColor),
        ],
      ),
    );
  }
}
