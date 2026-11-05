import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/bloc/paged_list_cubit.dart';
import 'package:solado_certo_app/features/admin/domain/entities/admin_entities.dart';
import 'package:solado_certo_app/features/admin/domain/usecases/admin_use_cases.dart';
import 'package:solado_certo_app/features/admin/presentation/components/admin_list_view.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_status.dart';

typedef AdminPaymentsCubit =
    PagedListCubit<AdminPaymentEntity, AdminPaymentFilter>;
typedef AdminPaymentsState =
    PagedListState<AdminPaymentEntity, AdminPaymentFilter>;

class AdminPaymentsPage extends StatelessWidget {
  const AdminPaymentsPage({super.key});

  static Route<void> route({bool refundGivenUp = false}) {
    final getPayments = getIt<GetAdminPaymentsUseCase>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => AdminPaymentsCubit(
          loader: (filter, page) async =>
              pageResult(await getPayments.execute(filter, page)),
          filter: refundGivenUp ? refundsGivenUp : all,
        )..load(),
        child: const AdminPaymentsPage(),
      ),
    );
  }

  static const all = AdminPaymentFilter();
  static const refundsGivenUp = AdminPaymentFilter(refundGivenUp: true);

  static final _filterOptions = <(AdminPaymentFilter, String)>[
    (all, 'Todos'),
    (refundsGivenUp, 'Estornos recusados'),
    for (final status in PaymentStatus.values)
      (AdminPaymentFilter(status: status), status.label),
  ];

  static AdminPaymentFilter _option(AdminPaymentFilter filter) {
    for (final (option, _) in _filterOptions) {
      if (option.status == filter.status &&
          option.refundGivenUp == filter.refundGivenUp) {
        return option;
      }
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminPaymentsCubit>();

    return AdminScaffold(
      title: 'Pagamentos',
      body: AdminListView<AdminPaymentEntity, AdminPaymentFilter>(
        header: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: BlocBuilder<AdminPaymentsCubit, AdminPaymentsState>(
            buildWhen: (previous, current) => previous.filter != current.filter,
            builder: (context, state) => AdminFilterChips<AdminPaymentFilter>(
              options: _filterOptions,
              selected: _option(state.filter),
              onSelected: cubit.applyFilter,
            ),
          ),
        ),
        emptyText: 'Nenhum pagamento encontrado.',
        itemBuilder: (context, payment) => AdminTile(
          key: ValueKey(payment.id),
          title: 'Pedido ${payment.orderNumber}',
          tags: [
            AdminTag(label: payment.status.label),
            if (payment.refundGivenUp)
              const AdminTag(label: 'Estorno recusado', highlight: true),
          ],
          lines: [
            '${payment.method.label} · ${formatCurrency(payment.amount)}',
            if (payment.failureReason case final reason?) 'Falha: $reason',
            if (payment.refundError case final error?)
              'Erro no estorno: $error',
          ],
          footnote: 'Criado em ${formatDateTime(payment.createdAt)}',
        ),
      ),
    );
  }
}
