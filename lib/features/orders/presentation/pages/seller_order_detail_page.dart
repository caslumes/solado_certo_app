import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/orders/domain/usecases/order_use_cases.dart';
import 'package:solado_certo_app/features/orders/presentation/bloc/seller_order_detail_cubit.dart';
import 'package:solado_certo_app/features/orders/presentation/components/amount_row.dart';
import 'package:solado_certo_app/features/orders/presentation/components/order_sections.dart';
import 'package:solado_certo_app/features/orders/presentation/components/order_status_chip.dart';
import 'package:solado_certo_app/features/orders/presentation/components/order_texts.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/ship_order_page.dart';
import 'package:solado_certo_app/features/reviews/presentation/components/item_review_summary.dart';

/// One of the seller's orders (RF-020, RF-021): who bought, where it goes,
/// what to send, and the next step, "Iniciar preparação" then "Informar
/// envio".
class SellerOrderDetailPage extends StatelessWidget {
  const SellerOrderDetailPage({super.key, this.onChanged});

  /// Receives the order every time it is loaded or changed here, so the
  /// list shows the same status.
  final ValueChanged<OrderEntity>? onChanged;

  static Route<void> route(
    String orderId, {
    ValueChanged<OrderEntity>? onChanged,
  }) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => SellerOrderDetailCubit(
          getSellerOrderUseCase: getIt<GetSellerOrderUseCase>(),
          startProcessingUseCase: getIt<StartProcessingUseCase>(),
          shipOrderUseCase: getIt<ShipOrderUseCase>(),
          orderId: orderId,
        )..load(),
        child: SellerOrderDetailPage(onChanged: onChanged),
      ),
    );
  }

  Future<void> _confirmProcessing(BuildContext context) async {
    final cubit = context.read<SellerOrderDetailCubit>();
    final textTheme = Theme.of(context).textTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Iniciar preparação?', style: textTheme.bodyMedium),
        content: Text(
          'A partir de agora o comprador não pode mais cancelar o pedido. '
          'Informe o envio assim que postar.',
          style: textTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Iniciar preparação'),
          ),
        ],
      ),
    );
    if (confirmed == true) cubit.startProcessing();
  }

  void _ship(BuildContext context, OrderEntity order) {
    Navigator.of(context).push(
      ShipOrderPage.route(
        context.read<SellerOrderDetailCubit>(),
        carrier: order.items.first.shippingOption.carrier,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<SellerOrderDetailCubit, SellerOrderDetailState>(
      listener: (context, state) {
        if (state is SellerOrderDetailLoadFailure &&
            state.failure is UnauthorizedFailure) {
          return _signOut(context);
        }
        if (state is! SellerOrderDetailLoaded || state.working) return;
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
          title: Text('Venda'.toUpperCase(), style: textTheme.bodyMedium),
        ),
        body: switch (state) {
          SellerOrderDetailLoaded(:final detail) => _Detail(detail: detail),
          SellerOrderDetailLoadFailure(:final failure) => _LoadError(
            failure: failure,
          ),
          SellerOrderDetailLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        },
        bottomNavigationBar: switch (state) {
          SellerOrderDetailLoaded(:final detail, :final working)
              when detail.canStartProcessing || detail.canShip =>
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: detail.canStartProcessing
                    ? ShoeTextButton(
                        onPressed: working
                            ? null
                            : () => _confirmProcessing(context),
                        text: 'Iniciar preparação',
                      )
                    : ShoeTextButton(
                        onPressed: working
                            ? null
                            : () => _ship(context, detail.order),
                        text: 'Informar envio',
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
    final shipment = detail.shipment;

    return RefreshIndicator(
      onRefresh: () => context.read<SellerOrderDetailCubit>().load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text('Pedido ${order.number}', style: textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            'Pago em ${formatDateTime(order.paidAt ?? order.createdAt)}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OrderStatusChip(status: order.status),
          ),
          if (_hint(order.status) case final hint?) ...[
            const SizedBox(height: 12),
            Text(hint, style: textTheme.bodySmall),
          ],
          const SizedBox(height: 24),
          Text(
            'Comprado por ${order.buyerName ?? ''}',
            style: textTheme.bodyMedium,
          ),
          for (final item in order.items)
            OrderItemRow(
              item: item,
              footer: switch (item.review) {
                final review? => ItemReviewSummary(
                  review: review,
                  title: 'Avaliação do comprador',
                ),
                null => null,
              },
            ),
          const Divider(height: 32),
          Text('Enviar para', style: textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(order.address.receiver, style: textTheme.bodyLarge),
          Text(
            formatShippingAddress(order.address),
            style: textTheme.bodySmall,
          ),
          if (shipment != null) ...[
            const Divider(height: 32),
            ShipmentSection(shipment: shipment),
          ],
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
            OrderHistoryEntry(
              change: change,
              isLatest: index == detail.history.length - 1,
              seller: true,
            ),
        ],
      ),
    );
  }

  static String? _hint(OrderStatus status) => switch (status) {
    OrderStatus.paid =>
      'Pagamento aprovado. Inicie a preparação para que o comprador não possa '
          'mais cancelar.',
    OrderStatus.processing =>
      'Poste o pedido e informe a transportadora e o código de rastreio.',
    OrderStatus.shipped => 'Aguardando o comprador confirmar o recebimento.',
    OrderStatus.cancelled =>
      'O comprador cancelou este pedido. Não o envie; o pagamento foi ou será '
          'estornado.',
    _ => null,
  };
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
              onPressed: () => context.read<SellerOrderDetailCubit>().load(),
              text: 'Tentar novamente',
            ),
          ],
        ),
      ),
    );
  }
}
