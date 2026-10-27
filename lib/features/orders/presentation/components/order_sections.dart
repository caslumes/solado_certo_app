import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_image.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/entities/shipment.dart';
import 'package:solado_certo_app/features/orders/presentation/components/order_texts.dart';

class OrderItemRow extends StatelessWidget {
  const OrderItemRow({super.key, required this.item, this.footer});

  final OrderItemEntity item;
  final Widget? footer;

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
                ?footer,
              ],
            ),
          ),
          Text(formatCurrency(item.subtotal), style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class OrderHistoryEntry extends StatelessWidget {
  const OrderHistoryEntry({
    super.key,
    required this.change,
    required this.isLatest,
    this.seller = false,
  });

  final OrderStatusChangeEntity change;
  final bool isLatest;

  final bool seller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reason = change.reasonLabelFor(seller: seller);

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

class ShipmentSection extends StatelessWidget {
  const ShipmentSection({super.key, required this.shipment, this.openUrl});

  final ShipmentEntity shipment;
  final Future<bool> Function(Uri url)? openUrl;

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: shipment.trackingCode));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Código copiado.')));
  }

  Future<void> _track(BuildContext context, Uri url) async {
    final messenger = ScaffoldMessenger.of(context);
    if (await openUrl!(url)) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a página.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final trackingUrl = shipment.trackingUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Envio', style: textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(shipment.carrier, style: textTheme.bodyLarge),
        Row(
          children: [
            Expanded(
              child: SelectableText(
                'Código ${shipment.trackingCode}',
                style: textTheme.bodySmall,
              ),
            ),
            IconButton(
              tooltip: 'Copiar código',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy_outlined, size: 18),
              onPressed: () => _copy(context),
            ),
          ],
        ),
        if (shipment.postedAt case final postedAt?)
          Text(
            'Enviado em ${formatDateTime(postedAt)}',
            style: textTheme.bodySmall,
          ),
        if (shipment.deliveredAt case final deliveredAt?)
          Text(
            'Entregue em ${formatDateTime(deliveredAt)}',
            style: textTheme.bodySmall,
          ),
        if (trackingUrl != null && openUrl != null)
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => _track(context, trackingUrl),
            child: const Text('Acompanhar entrega'),
          ),
      ],
    );
  }
}
