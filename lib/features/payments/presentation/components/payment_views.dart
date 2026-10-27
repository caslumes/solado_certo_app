import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/presentation/components/amount_row.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment_amounts.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';

class PaymentOrderHeader extends StatelessWidget {
  const PaymentOrderHeader({super.key, required this.order, this.position});

  final OrderEntity order;
  final String? position;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          position == null
              ? 'Pedido ${order.number}'
              : 'Pedido ${order.number} ($position)',
          style: textTheme.bodyMedium,
        ),
        Text('Vendido por ${order.sellerName}', style: textTheme.bodySmall),
      ],
    );
  }
}

class PixPaymentView extends StatelessWidget {
  const PixPaymentView({super.key, required this.payment});

  final PaymentEntity payment;

  Future<void> _copy(BuildContext context, String payload) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: payload));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Código Pix copiado.')));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pix = payment.pix;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12.0,
      children: [
        Text('Pague com Pix', style: textTheme.bodyMedium),
        Text(formatCurrency(payment.amount), style: textTheme.titleLarge),
        if (pix == null)
          Text('Gerando o código Pix…', style: textTheme.bodySmall)
        else ...[
          Center(
            child: QrImageView(
              data: pix.payload,
              size: 220,
              backgroundColor: Colors.white,
              semanticsLabel: 'QR code do Pix',
            ),
          ),
          Text(
            'Escaneie o QR code ou copie o código e cole no app do seu banco.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
          SelectableText(pix.payload, maxLines: 3, style: textTheme.bodySmall),
          OutlinedButton.icon(
            onPressed: () => _copy(context, pix.payload),
            icon: const Icon(Icons.copy),
            label: Text('Copiar código Pix'.toUpperCase()),
          ),
          if (pix.expiresAt case final expiresAt?)
            Text(
              'Pague até ${formatDateTime(expiresAt)}.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
        ],
        const _Waiting(),
      ],
    );
  }
}

class BoletoPaymentView extends StatelessWidget {
  const BoletoPaymentView({
    super.key,
    required this.payment,
    required this.onOpen,
  });

  final PaymentEntity payment;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final url = payment.boletoUrl ?? payment.invoiceUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12.0,
      children: [
        Text('Boleto gerado', style: textTheme.bodyMedium),
        Text(formatCurrency(payment.amount), style: textTheme.titleLarge),
        if (payment.dueDate case final dueDate?)
          Text(
            'Vencimento: ${formatDate(dueDate)}',
            style: textTheme.bodySmall,
          ),
        if (url != null)
          OutlinedButton.icon(
            onPressed: () => onOpen(url),
            icon: const Icon(Icons.open_in_new),
            label: Text('Abrir boleto'.toUpperCase()),
          ),
        Text(
          'A confirmação do boleto pode levar até 3 dias úteis depois do '
          'pagamento. Você pode fechar esta tela: o pedido é atualizado '
          'sozinho.',
          style: textTheme.bodySmall,
        ),
        const _Waiting(),
      ],
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8.0,
      children: [
        const SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        Text(
          'Aguardando a confirmação do pagamento',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class PaymentApprovedView extends StatelessWidget {
  const PaymentApprovedView({
    super.key,
    required this.order,
    required this.payment,
  });

  final OrderEntity order;
  final PaymentEntity payment;

  String get _paidWith => switch (payment.card) {
    final card? => 'Cartão ${card.brand} final ${card.last4}',
    null => payment.method.label,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final capturedAt = payment.capturedAt;
    final discount = order.subtotal + order.shippingTotal - payment.amount;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 64,
          color: AppColors.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Pagamento aprovado!',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          capturedAt == null
              ? 'Pago com $_paidWith.'
              : 'Pago com $_paidWith em ${formatDateTime(capturedAt)}.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall,
        ),
        Text(
          'Agora o vendedor prepara o envio.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        PaymentOrderHeader(order: order),
        for (final item in order.items)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity} × ${item.title}',
                    style: textTheme.bodyLarge,
                  ),
                ),
                Text(formatCurrency(item.subtotal), style: textTheme.bodyLarge),
              ],
            ),
          ),
        const Divider(height: 32),
        AmountRow(label: 'Subtotal', value: order.subtotal),
        AmountRow(label: 'Frete', value: order.shippingTotal),
        if (discount >= 0.01)
          AmountRow(label: 'Desconto', value: discount, isDiscount: true),
        const Divider(),
        AmountRow(label: 'Total pago', value: payment.amount, emphasized: true),
      ],
    );
  }
}

String paymentMethodHint(PaymentMethod method) => switch (method) {
  PaymentMethod.pix =>
    '${PaymentAmounts.pixDiscountPercent}% de desconto · aprovação na hora',
  PaymentMethod.boleto => 'Aprovação em até 3 dias úteis após o pagamento',
  PaymentMethod.creditCard => 'À vista',
};
