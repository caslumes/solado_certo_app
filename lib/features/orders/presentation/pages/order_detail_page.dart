import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_image.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/orders/domain/usecases/order_use_cases.dart';
import 'package:solado_certo_app/features/orders/presentation/bloc/order_detail_cubit.dart';
import 'package:solado_certo_app/features/orders/presentation/components/amount_row.dart';
import 'package:solado_certo_app/features/orders/presentation/components/order_status_chip.dart';
import 'package:solado_certo_app/features/orders/presentation/components/order_texts.dart';

/// One order with its items, address, totals and status history (RF-019).
/// The buyer can cancel it while it awaits payment.
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, this.onChanged});

  /// Receives the order every time it is loaded or changed here, so the
  /// list shows the same status.
  final ValueChanged<OrderEntity>? onChanged;

  static Route<void> route(
    String orderId, {
    ValueChanged<OrderEntity>? onChanged,
  }) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => OrderDetailCubit(
          getOrderUseCase: getIt<GetOrderUseCase>(),
          cancelOrderUseCase: getIt<CancelOrderUseCase>(),
          orderId: orderId,
        )..load(),
        child: OrderDetailPage(onChanged: onChanged),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final cubit = context.read<OrderDetailCubit>();
    final textTheme = Theme.of(context).textTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancelar pedido?', style: textTheme.bodyMedium),
        content: Text(
          'Os produtos voltam a ficar à venda e o pedido não poderá ser '
          'retomado.',
          style: textTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
    if (confirmed == true) cubit.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<OrderDetailCubit, OrderDetailState>(
      listener: (context, state) {
        if (state is OrderDetailLoadFailure &&
            state.failure is UnauthorizedFailure) {
          return _signOut(context);
        }
        if (state is! OrderDetailLoaded || state.cancelling) return;
        onChanged?.call(state.detail.order);
        final failure = state.failure;
        if (failure is UnauthorizedFailure) return _signOut(context);
        final message = failure?.message ?? state.notice;
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          iconTheme: Theme.of(context).iconTheme,
          title: Text('Pedido'.toUpperCase(), style: textTheme.bodyMedium),
        ),
        body: switch (state) {
          OrderDetailLoaded(:final detail) => _Detail(detail: detail),
          OrderDetailLoadFailure(:final failure) => _LoadError(
            failure: failure,
          ),
          OrderDetailLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        },
        bottomNavigationBar: switch (state) {
          OrderDetailLoaded(:final detail, :final cancelling)
              when detail.canCancel =>
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: ShoeTextButton(
                  isLoading: cancelling,
                  onPressed: () => _confirmCancel(context),
                  text: 'Cancelar pedido',
                ),
              ),
            ),
          _ => null,
        },
      ),
    );
  }

  static void _signOut(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.read<AuthBloc>().add(SignOutEvent());
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.detail});

  final OrderDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final order = detail.order;

    return RefreshIndicator(
      onRefresh: () => context.read<OrderDetailCubit>().load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text('Pedido ${order.number}', style: textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            'Feito em ${formatDateTime(order.createdAt)}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OrderStatusChip(status: order.status),
          ),
          if (order.status == OrderStatus.awaitingPayment) ...[
            const SizedBox(height: 12),
            Text(
              'Os produtos ficam reservados para você até o pagamento.',
              style: textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          Text('Vendido por ${order.sellerName}', style: textTheme.bodyMedium),
          for (final item in order.items) _ItemRow(item: item),
          const Divider(height: 32),
          Text('Entrega', style: textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(order.address.receiver, style: textTheme.bodyLarge),
          Text(
            formatShippingAddress(order.address),
            style: textTheme.bodySmall,
          ),
          const Divider(height: 32),
          AmountRow(label: 'Subtotal', value: order.subtotal),
          AmountRow(label: 'Frete', value: order.shippingTotal),
          AmountRow(
            label: 'Desconto',
            value: order.discountTotal,
            isDiscount: true,
          ),
          const Divider(),
          AmountRow(label: 'Total', value: order.total, emphasized: true),
          const Divider(height: 32),
          Text('Histórico', style: textTheme.bodyMedium),
          const SizedBox(height: 8),
          for (final (index, change) in detail.history.indexed)
            _HistoryEntry(
              change: change,
              isLatest: index == detail.history.length - 1,
            ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderItemEntity item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final option = item.shippingOption;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12.0,
        children: [
          SizedBox.square(
            dimension: 56,
            child: ProductImage(url: item.coverImageUrl),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: textTheme.bodyLarge),
                Text(
                  '${item.quantity} × ${formatCurrency(item.unitPrice)}',
                  style: textTheme.bodySmall,
                ),
                Text(
                  '${shippingOptionName(option)} · '
                  '${deliveryTime(option.deliveryDays)}',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(formatCurrency(item.subtotal), style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// One status change in the order's timeline.
class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({required this.change, required this.isLatest});

  final OrderStatusChangeEntity change;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reason = change.reasonLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12.0,
        children: [
          Icon(
            isLatest ? Icons.radio_button_checked : Icons.circle_outlined,
            size: 18,
            color: isLatest ? AppColors.primaryColor : AppColors.tertiaryColor,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(change.to.label, style: textTheme.bodyLarge),
                Text(
                  reason == null
                      ? formatDateTime(change.createdAt)
                      : '${formatDateTime(change.createdAt)} · $reason',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
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
              onPressed: () => context.read<OrderDetailCubit>().load(),
              text: 'Tentar novamente',
            ),
          ],
        ),
      ),
    );
  }
}
