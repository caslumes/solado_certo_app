import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/checkout/domain/entities/checkout.dart';

/// Shown after checkout: the order numbers and what comes next (payment).
class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({
    super.key,
    required this.result,
    this.onViewOrders,
    this.onKeepShopping,
  });

  final CheckoutResultEntity result;

  /// Open the Pedidos and Catálogo tabs once this page is closed.
  final VoidCallback? onViewOrders;
  final VoidCallback? onKeepShopping;

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
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final single = result.orders.length == 1;

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
            'Os produtos ficam reservados até o pagamento. '
            'Você pode pagar pela tela do pedido.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          for (final order in result.orders)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Pedido ${order.number}', style: textTheme.bodyLarge),
              subtitle: Text(
                '${order.sellerName} · ${order.status.label}',
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
              Text(formatCurrency(result.total), style: textTheme.bodyMedium),
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
              if (onViewOrders case final viewOrders?)
                ShoeTextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    viewOrders();
                  },
                  text: 'Ver meus pedidos',
                ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onKeepShopping?.call();
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
