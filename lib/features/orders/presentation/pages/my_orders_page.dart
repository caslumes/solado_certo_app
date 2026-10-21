import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:solado_certo_app/features/orders/presentation/components/paged_order_list.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/order_detail_page.dart';

/// The Pedidos tab (RF-019): the buyer's orders, newest first.
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          'Pedidos'.toUpperCase(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      body: PagedOrderList(
        onOpen: (order) => _open(context, order),
        emptyTitle: 'Você ainda não fez pedidos',
        emptyMessage: 'Seus pedidos aparecem aqui depois do checkout.',
      ),
    );
  }
}
