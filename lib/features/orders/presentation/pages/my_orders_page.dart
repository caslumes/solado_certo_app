import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_filter.dart';
import 'package:solado_certo_app/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:solado_certo_app/features/orders/presentation/components/order_filter_sheet.dart';
import 'package:solado_certo_app/features/orders/presentation/components/paged_order_list.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/order_detail_page.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  void _open(BuildContext context, OrderEntity order) {
    final bloc = context.read<OrdersBloc>();
    Navigator.of(context).push(
      OrderDetailPage.route(
        order.id,
        onChanged: (order) => bloc.add(OrderChangedEvent(order: order)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = context.select<OrdersBloc, OrderFilter>(
      (bloc) => bloc.state.filter,
    );
    void applyFilter(OrderFilter filter) =>
        context.read<OrdersBloc>().add(FilterOrdersEvent(filter: filter));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          'Pedidos'.toUpperCase(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [OrderFilterButton(filter: filter, onChanged: applyFilter)],
      ),
      body: Column(
        children: [
          if (!filter.isEmpty)
            OrderFilterBar(
              filter: filter,
              onClear: () => applyFilter(const OrderFilter()),
            ),
          Expanded(
            child: PagedOrderList(
              onOpen: (order) => _open(context, order),
              emptyTitle: filter.isEmpty
                  ? 'Você ainda não fez pedidos'
                  : 'Nenhum pedido encontrado',
              emptyMessage: filter.isEmpty
                  ? 'Seus pedidos aparecem aqui depois do checkout.'
                  : 'Mude ou limpe os filtros.',
            ),
          ),
        ],
      ),
    );
  }
}
