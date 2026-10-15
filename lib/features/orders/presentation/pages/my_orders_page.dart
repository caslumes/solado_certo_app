import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_image.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:solado_certo_app/features/orders/presentation/components/order_status_chip.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/order_detail_page.dart';

/// The Pedidos tab (RF-019): the buyer's orders, newest first.
class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
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
      context.read<OrdersBloc>().add(LoadMoreOrdersEvent());
    }
  }

  /// A short first page can leave nothing to scroll, so no scroll event
  /// would ask for the next one.
  void _checkFill() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) _onScroll();
    });
  }

  void _open(OrderEntity order) {
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
    return BlocConsumer<OrdersBloc, OrdersState>(
      listenWhen: (previous, current) =>
          current.failure != null ||
          (current.status == OrdersStatus.loaded &&
              current.orders.length != previous.orders.length),
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return _checkFill();
        if (failure is UnauthorizedFailure) {
          context.read<AuthBloc>().add(SignOutEvent());
          return;
        }
        if (state.status != OrdersStatus.loaded) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message)));
      },
      builder: (context, state) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(
            'Pedidos'.toUpperCase(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        body: switch (state.status) {
          OrdersStatus.loaded when state.orders.isEmpty => const _NoOrders(),
          OrdersStatus.loaded => _OrderList(
            state: state,
            controller: _scrollController,
            onOpen: _open,
          ),
          OrdersStatus.failure => _LoadError(failure: state.failure!),
          OrdersStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          // Signed-out visitors are sent to sign in instead of this tab.
          OrdersStatus.initial => const SizedBox.shrink(),
        },
      ),
    );
  }
}

Future<void> _refresh(BuildContext context) async {
  final bloc = context.read<OrdersBloc>();
  bloc.add(LoadOrdersEvent());
  await bloc.stream.firstWhere((s) => s.status != OrdersStatus.loading);
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.state,
    required this.controller,
    required this.onOpen,
  });

  final OrdersState state;
  final ScrollController controller;
  final ValueChanged<OrderEntity> onOpen;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ListView.separated(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.orders.length + (state.loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == state.orders.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final order = state.orders[index];
          return OrderTile(
            key: ValueKey(order.id),
            order: order,
            onTap: () => onOpen(order),
          );
        },
      ),
    );
  }
}

class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order, required this.onTap});

  final OrderEntity order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final first = order.items.first;
    final others = order.items.length - 1;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12.0,
          children: [
            SizedBox.square(
              dimension: 64,
              child: ProductImage(url: first.coverImageUrl),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4.0,
                children: [
                  Text('Pedido ${order.number}', style: textTheme.bodyMedium),
                  Text(
                    others == 0
                        ? first.title
                        : '${first.title} e mais $others '
                              '${others == 1 ? 'item' : 'itens'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge,
                  ),
                  Text(
                    '${order.sellerName} · ${formatDate(order.createdAt)}',
                    style: textTheme.bodySmall,
                  ),
                  OrderStatusChip(status: order.status),
                ],
              ),
            ),
            Text(formatCurrency(order.total), style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _NoOrders extends StatelessWidget {
  const _NoOrders();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 64),
          const Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.tertiaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Você ainda não fez pedidos',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Seus pedidos aparecem aqui depois do checkout.',
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
              onPressed: () =>
                  context.read<OrdersBloc>().add(LoadOrdersEvent()),
              text: 'Tentar novamente',
            ),
          ],
        ),
      ),
    );
  }
}
