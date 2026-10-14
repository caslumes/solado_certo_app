import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/shipping_option.dart';
import 'package:solado_certo_app/features/checkout/domain/entities/checkout.dart';
import 'package:solado_certo_app/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/profile/domain/entities/address.dart';

/// Step 1: where the orders go.
class CheckoutAddressStep extends StatelessWidget {
  const CheckoutAddressStep({
    super.key,
    required this.state,
    required this.onSelect,
    required this.onAdd,
  });

  final CheckoutState state;
  final ValueChanged<String> onSelect;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            state.addresses.isEmpty
                ? 'Cadastre um endereço para receber seus pedidos.'
                : 'Onde você quer receber?',
            style: textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 8),
        for (final address in state.addresses)
          CheckoutChoiceTile(
            key: ValueKey(address.id),
            selected: address.id == state.addressId,
            title: address.label ?? address.receiver,
            subtitle: formatAddress(address),
            onTap: () => onSelect(address.id),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text('Adicionar endereço'.toUpperCase()),
            ),
          ),
        ),
      ],
    );
  }
}

/// Step 2: a shipping option for each item, grouped by seller.
class CheckoutShippingStep extends StatelessWidget {
  const CheckoutShippingStep({
    super.key,
    required this.state,
    required this.onSelect,
  });

  final CheckoutState state;
  final void Function(String advertisementId, String optionId) onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Cada vendedor envia um pacote. O frete do pedido é a opção mais '
            'cara escolhida entre os itens dele.',
            style: textTheme.bodySmall,
          ),
        ),
        for (final group in state.cart.groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Vendido por ${group.sellerName}',
              style: textTheme.bodyMedium,
            ),
          ),
          for (final item in group.items) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                '${item.quantity} × ${item.title}',
                style: textTheme.bodyLarge,
              ),
            ),
            if (item.shippingOptions.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: CheckoutWarning(
                  text:
                      'Este produto não tem opção de envio. Remova-o do '
                      'carrinho para continuar.',
                ),
              ),
            for (final option in item.shippingOptions)
              CheckoutChoiceTile(
                key: ValueKey('${item.advertisementId}/${option.id}'),
                selected: state.shipping[item.advertisementId] == option.id,
                title: shippingOptionName(option),
                subtitle: deliveryTime(option.deliveryDays),
                trailing: formatCurrency(option.price),
                onTap: () => onSelect(item.advertisementId, option.id),
              ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _AmountRow(
              label: 'Frete deste vendedor',
              value: state.shippingFor(group),
            ),
          ),
          const Divider(height: 1),
        ],
      ],
    );
  }
}

/// Step 3: the orders the server will create, with its totals.
class CheckoutReviewStep extends StatelessWidget {
  const CheckoutReviewStep({super.key, required this.plan});

  final CheckoutPlanEntity plan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final count = plan.orders.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Entrega', style: textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(plan.address.receiver, style: textTheme.bodyLarge),
        Text(formatShippingAddress(plan.address), style: textTheme.bodySmall),
        const SizedBox(height: 16),
        if (count > 1) ...[
          Text(
            'Serão criados $count pedidos, um para cada vendedor.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
        ],
        for (final order in plan.orders) ...[
          _PlannedOrderCard(order: order),
          const SizedBox(height: 12),
        ],
        _AmountRow(label: 'Subtotal', value: plan.subtotal),
        _AmountRow(label: 'Frete', value: plan.shippingTotal),
        _AmountRow(
          label: 'Desconto',
          value: plan.discountTotal,
          isDiscount: true,
        ),
        const Divider(),
        _AmountRow(label: 'Total', value: plan.total, emphasized: true),
        const SizedBox(height: 8),
        Text(
          'O pagamento é feito depois de confirmar o pedido.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PlannedOrderCard extends StatelessWidget {
  const _PlannedOrderCard({required this.order});

  final PlannedOrderEntity order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.secondaryColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4.0,
          children: [
            Text('Pedido de ${order.sellerName}', style: textTheme.bodyMedium),
            for (final item in order.items) _ItemLine(item: item),
            const Divider(),
            _AmountRow(label: 'Subtotal', value: order.subtotal),
            _AmountRow(label: 'Frete', value: order.shippingTotal),
            if (order.discountTotal > 0)
              _AmountRow(
                label: 'Desconto',
                value: order.discountTotal,
                isDiscount: true,
              ),
            _AmountRow(label: 'Total do pedido', value: order.total),
          ],
        ),
      ),
    );
  }
}

class _ItemLine extends StatelessWidget {
  const _ItemLine({required this.item});

  final OrderItemEntity item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8.0,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.quantity} × ${item.title}',
                style: textTheme.bodyLarge,
              ),
              Text(
                shippingOptionName(item.shippingOption),
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Text(formatCurrency(item.subtotal), style: textTheme.bodyLarge),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.isDiscount = false,
  });

  final String label;
  final double value;
  final bool emphasized;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = emphasized ? textTheme.bodyMedium : textTheme.bodyLarge;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          isDiscount && value > 0
              ? '- ${formatCurrency(value)}'
              : formatCurrency(value),
          style: style,
        ),
      ],
    );
  }
}

/// A selectable row, like a radio button, for addresses and shipping.
class CheckoutChoiceTile extends StatelessWidget {
  const CheckoutChoiceTile({
    super.key,
    required this.selected,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      selected: selected,
      onTap: onTap,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? AppColors.primaryColor : AppColors.tertiaryColor,
      ),
      title: Text(title, style: textTheme.bodyLarge),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: textTheme.bodySmall),
      trailing: trailing == null
          ? null
          : Text(trailing!, style: textTheme.bodyLarge),
    );
  }
}

class CheckoutWarning extends StatelessWidget {
  const CheckoutWarning({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.warningBackgroundColor,
      child: Row(
        spacing: 8.0,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warningColor),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.warningColor),
            ),
          ),
        ],
      ),
    );
  }
}

String shippingOptionName(ShippingOptionEntity option) =>
    option.carrier == null ? option.name : '${option.name} (${option.carrier})';

String deliveryTime(int days) =>
    days == 1 ? 'Até 1 dia útil' : 'Até $days dias úteis';

String formatAddress(AddressEntity address) => _address(
  street: address.street,
  number: address.number,
  complement: address.complement,
  district: address.district,
  city: address.city,
  state: address.state,
  zipCode: address.zipCode,
);

String formatShippingAddress(ShippingAddressEntity address) => _address(
  street: address.street,
  number: address.number,
  complement: address.complement,
  district: address.district,
  city: address.city,
  state: address.state,
  zipCode: address.zipCode,
);

String _address({
  required String street,
  required String number,
  required String? complement,
  required String district,
  required String city,
  required String state,
  required String zipCode,
}) {
  final cep = zipCode.length == 8
      ? '${zipCode.substring(0, 5)}-${zipCode.substring(5)}'
      : zipCode;
  final line = complement == null
      ? '$street, $number'
      : '$street, $number, $complement';
  return '$line\n$district, $city - $state\nCEP $cep';
}
