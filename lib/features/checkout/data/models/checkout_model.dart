import 'package:solado_certo_app/features/checkout/domain/entities/checkout.dart';
import 'package:solado_certo_app/features/orders/data/models/order_model.dart';

Map<String, dynamic> checkoutSelectionToJson(CheckoutSelection selection) => {
  'address_id': selection.addressId,
  'shipping': [
    for (final MapEntry(key: advertisementId, value: optionId)
        in selection.shipping.entries)
      {'advertisement_id': advertisementId, 'shipping_option_id': optionId},
  ],
};

CheckoutPlanEntity checkoutPlanFromJson(Map<String, dynamic> json) =>
    CheckoutPlanEntity(
      address: shippingAddressFromJson(json['address'] as Map<String, dynamic>),
      orders: [
        for (final order in json['orders'] as List)
          PlannedOrderEntity(
            sellerId: order['seller']['id'] as String,
            sellerName: order['seller']['name'] as String,
            items: [
              for (final item in order['items'] as List)
                orderItemFromJson(item),
            ],
            subtotal: double.parse(order['subtotal'] as String),
            shippingTotal: double.parse(order['shipping_total'] as String),
            discountTotal: double.parse(order['discount_total'] as String),
            total: double.parse(order['total'] as String),
          ),
      ],
      subtotal: double.parse(json['subtotal'] as String),
      shippingTotal: double.parse(json['shipping_total'] as String),
      discountTotal: double.parse(json['discount_total'] as String),
      total: double.parse(json['total'] as String),
    );

CheckoutResultEntity checkoutResultFromJson(Map<String, dynamic> json) =>
    CheckoutResultEntity(
      id: json['id'] as String,
      orders: [
        for (final order in json['orders'] as List) orderFromJson(order),
      ],
      total: double.parse(json['total'] as String),
    );
