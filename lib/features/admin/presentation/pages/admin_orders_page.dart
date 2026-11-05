import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/bloc/paged_list_cubit.dart';
import 'package:solado_certo_app/features/admin/domain/entities/admin_entities.dart';
import 'package:solado_certo_app/features/admin/domain/usecases/admin_use_cases.dart';
import 'package:solado_certo_app/features/admin/presentation/components/admin_list_view.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';

typedef AdminOrdersCubit = PagedListCubit<AdminOrderEntity, AdminOrderFilter>;
typedef AdminOrdersState = PagedListState<AdminOrderEntity, AdminOrderFilter>;

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  static Route<void> route() {
    final getOrders = getIt<GetAdminOrdersUseCase>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => AdminOrdersCubit(
          loader: (filter, page) async =>
              pageResult(await getOrders.execute(filter, page)),
          filter: const AdminOrderFilter(),
        )..load(),
        child: const AdminOrdersPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminOrdersCubit>();

    return AdminScaffold(
      title: 'Pedidos',
      body: AdminListView<AdminOrderEntity, AdminOrderFilter>(
        header: BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
          buildWhen: (previous, current) => previous.filter != current.filter,
          builder: (context, state) {
            final filter = state.filter;
            return Column(
              children: [
                AdminSearchField(
                  hintText: 'Número do pedido ou comprador',
                  initialValue: filter.search,
                  onSubmitted: (search) => cubit.applyFilter(
                    AdminOrderFilter(search: search, status: filter.status),
                  ),
                ),
                AdminFilterChips<OrderStatus?>(
                  options: [
                    (null, 'Todos'),
                    for (final status in OrderStatus.values)
                      (status, status.label),
                  ],
                  selected: filter.status,
                  onSelected: (status) => cubit.applyFilter(
                    AdminOrderFilter(search: filter.search, status: status),
                  ),
                ),
              ],
            );
          },
        ),
        emptyText: 'Nenhum pedido encontrado.',
        itemBuilder: (context, order) => AdminTile(
          key: ValueKey(order.id),
          title: 'Pedido ${order.number}',
          tags: [AdminTag(label: order.status.label)],
          lines: [
            'Comprador: ${order.buyerName} (${order.buyerEmail})',
            if (order.sellerName case final seller?) 'Vendedor: $seller',
            'Total: ${formatCurrency(order.total)}',
          ],
          footnote: [
            'Criado em ${formatDateTime(order.createdAt)}',
            if (order.paidAt case final paidAt?)
              'pago em ${formatDateTime(paidAt)}',
          ].join(' · '),
        ),
      ),
    );
  }
}
