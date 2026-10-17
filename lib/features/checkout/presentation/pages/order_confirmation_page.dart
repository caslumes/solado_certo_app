import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/checkout/domain/entities/checkout.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/payments/presentation/pages/payment_page.dart';

/// Shown after checkout: the order numbers and their payment, one order
/// (one seller) at a time.
class OrderConfirmationPage extends StatefulWidget {
  const OrderConfirmationPage({
    super.key,
    required this.result,
    this.onViewOrders,
    this.onKeepShopping,
    this.pay = _openPayment,
  });

  final CheckoutResultEntity result;

  /// Open the Pedidos and Catálogo tabs once this page is closed.
  final VoidCallback? onViewOrders;
  final VoidCallback? onKeepShopping;

  /// Opens the payment of an order; answers true when it was paid.
  final Future<bool?> Function(
    BuildContext context,
    OrderEntity order,
    String? position,
  )
  pay;

  static Future<bool?> _openPayment(
    BuildContext context,
    OrderEntity order,
    String? position,
  ) => Navigator.of(context).push(PaymentPage.route(order, position: position));

  static Route<void> route({
    required CheckoutResultEntity result,
    VoidCallback? onViewOrders,
    VoidCallback? onKeepShopping,
  }) {
    return MaterialPageRoute(
      builder: (_) => OrderConfirmationPage(
        result: result,
        onViewOrders: onViewOrders,
        onKeepShopping: onKeepShopping,
      ),
    );
  }

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  final _paid = <String>{};

  List<OrderEntity> get _orders => widget.result.orders;

  OrderEntity? get _nextToPay => _orders
      .where(
        (order) =>
            order.status == OrderStatus.awaitingPayment &&
            !_paid.contains(order.id),
      )
      .firstOrNull;

  String? _position(OrderEntity order) => _orders.length == 1
      ? null
      : '${_orders.indexOf(order) + 1} de ${_orders.length}';

  Future<void> _payNext() async {
    final order = _nextToPay;
    if (order == null) return;
    final paid = await widget.pay(context, order, _position(order));
    if (paid == true && mounted) setState(() => _paid.add(order.id));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final single = _orders.length == 1;
    final next = _nextToPay;

    return Scaffold(
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        title: Text(
          'Pedido realizado'.toUpperCase(),
          style: textTheme.bodyMedium,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            single ? 'Seu pedido foi criado!' : 'Seus pedidos foram criados!',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            single
                ? 'Os produtos ficam reservados até o pagamento. Você pode '
                      'pagar agora ou depois, pela tela do pedido.'
                : 'Cada vendedor recebe um pagamento separado. Os produtos '
                      'ficam reservados até o pagamento, que você pode fazer '
                      'agora ou depois, pela tela de cada pedido.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          for (final order in _orders)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Pedido ${order.number}', style: textTheme.bodyLarge),
              subtitle: Text(
                '${order.sellerName} · '
                '${_paid.contains(order.id) ? OrderStatus.paid.label : order.status.label}',
                style: textTheme.bodySmall,
              ),
              trailing: Text(
                formatCurrency(order.total),
                style: textTheme.bodyLarge,
              ),
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: textTheme.bodyMedium),
              Text(
                formatCurrency(widget.result.total),
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8.0,
            children: [
              if (next != null)
                ShoeTextButton(
                  onPressed: _payNext,
                  text: single
                      ? 'Pagar agora'
                      : 'Pagar pedido ${_position(next)}',
                ),
              if (widget.onViewOrders case final viewOrders?)
                next == null
                    ? ShoeTextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          viewOrders();
                        },
                        text: 'Ver meus pedidos',
                      )
                    : TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          viewOrders();
                        },
                        child: const Text('Ver meus pedidos'),
                      ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onKeepShopping?.call();
                },
                child: const Text('Continuar comprando'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
