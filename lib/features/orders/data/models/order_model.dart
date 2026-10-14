import 'package:solado_certo_app/features/catalog/domain/entities/shipping_option.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';

OrderEntity orderFromJson(Map<String, dynamic> json) => OrderEntity(
  id: json['id'] as String,
  number: json['number'] as String,
  status: OrderStatus.fromApi(json['status'] as String),
  sellerId: json['seller']['id'] as String,
  sellerName: json['seller']['name'] as String,
  address: shippingAddressFromJson(json['address'] as Map<String, dynamic>),
  items: [for (final item in json['items'] as List) orderItemFromJson(item)],
  subtotal: double.parse(json['subtotal'] as String),
  shippingTotal: double.parse(json['shipping_total'] as String),
  discountTotal: double.parse(json['discount_total'] as String),
  total: double.parse(json['total'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
);

OrderItemEntity orderItemFromJson(Map<String, dynamic> json) {
  final option = json['shipping_option'] as Map<String, dynamic>;
  return OrderItemEntity(
    advertisementId: json['advertisement_id'] as String,
    title: json['title'] as String,
    coverImageUrl: json['cover_image_url'] as String?,
    quantity: json['quantity'] as int,
    unitPrice: double.parse(json['unit_price'] as String),
    subtotal: double.parse(json['subtotal'] as String),
    shippingOption: ShippingOptionEntity(
      id: option['id'] as String,
      name: option['name'] as String,
      carrier: option['carrier'] as String?,
      price: double.parse(option['price'] as String),
      deliveryDays: option['delivery_days'] as int,
    ),
  );
}

ShippingAddressEntity shippingAddressFromJson(Map<String, dynamic> json) =>
    ShippingAddressEntity(
      label: json['label'] as String?,
      receiver: json['receiver'] as String,
      zipCode: json['zip_code'] as String,
      street: json['street'] as String,
      number: json['number'] as String,
      complement: json['complement'] as String?,
      district: json['district'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
    );
