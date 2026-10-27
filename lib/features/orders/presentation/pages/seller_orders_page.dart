import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_filter.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/orders/domain/usecases/order_use_cases.dart';
import 'package:solado_certo_app/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:solado_certo_app/features/orders/presentation/components/order_filter_sheet.dart';
import 'package:solado_certo_app/features/orders/presentation/components/paged_order_list.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/seller_order_detail_page.dart';

const _tabs = [
  (OrderStatus.paid, 'Novos', 'Nenhum pedido novo'),
  (OrderStatus.processing, 'Em preparação', 'Nenhum pedido em preparação'),
  (OrderStatus.shipped, 'Enviados', 'Nenhum pedido enviado'),
  (OrderStatus.delivered, 'Entregues', 'Nenhum pedido entregue'),
  (OrderStatus.cancelled, 'Cancelados', 'Nenhum pedido cancelado'),
];

class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const SellerOrdersPage());

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> {
  OrderFilter _period = const OrderFilter();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          iconTheme: Theme.of(context).iconTheme,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(
            'Minhas vendas'.toUpperCase(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            OrderFilterButton(
              filter: _period,
              withStatus: false,
              onChanged: (period) => setState(() => _period = period),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final (_, label, _) in _tabs) Tab(text: label)],
          ),
        ),
        body: Column(
          children: [
            if (!_period.isEmpty)
              OrderFilterBar(
                filter: _period,
                onClear: () => setState(() => _period = const OrderFilter()),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final (status, _, empty) in _tabs)
                    _SalesTab(
                      key: ValueKey(status),
                      status: status,
                      period: _period,
                      empty: empty,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesTab extends StatefulWidget {
  const _SalesTab({
    super.key,
    required this.status,
    required this.period,
    required this.empty,
  });

  final OrderStatus status;
  final OrderFilter period;
  final String empty;

  @override
  State<_SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<_SalesTab> {
  late final _bloc = OrdersBloc.sales(
    getSellerOrdersUseCase: getIt<GetSellerOrdersUseCase>(),
    status: widget.status,
  )..add(FilterOrdersEvent(filter: widget.period));

  @override
  void didUpdateWidget(_SalesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.period != oldWidget.period) {
      _bloc.add(FilterOrdersEvent(filter: widget.period));
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _open(OrderEntity order) async {
    await Navigator.of(context).push(SellerOrderDetailPage.route(order.id));
    if (!_bloc.isClosed) _bloc.add(LoadOrdersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: PagedOrderList(
        onOpen: _open,
        showBuyer: true,
        emptyTitle: widget.empty,
        emptyMessage: widget.period.isEmpty
            ? 'Os pedidos aparecem aqui depois do pagamento.'
            : 'Nenhuma venda neste período.',
      ),
    );
  }
}
