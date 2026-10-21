import 'package:solado_certo_app/features/catalog/domain/entities/shipping_option.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/entities/shipment.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';

OrderEntity orderFromJson(Map<String, dynamic> json) => OrderEntity(
  id: json['id'] as String,
  number: json['number'] as String,
  status: OrderStatus.fromApi(json['status'] as String),
  sellerId: json['seller']['id'] as String,
  sellerName: json['seller']['name'] as String,
  buyerName: (json['buyer'] as Map<String, dynamic>?)?['name'] as String?,
  address: shippingAddressFromJson(json['address'] as Map<String, dynamic>),
  items: [for (final item in json['items'] as List) orderItemFromJson(item)],
  subtotal: double.parse(json['subtotal'] as String),
  shippingTotal: double.parse(json['shipping_total'] as String),
  discountTotal: double.parse(json['discount_total'] as String),
  total: double.parse(json['total'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  paidAt: _date(json['paid_at']),
  deliveredAt: _date(json['delivered_at']),
);

DateTime? _date(Object? value) =>
    value is String ? DateTime.parse(value) : null;

ShipmentEntity shipmentFromJson(Map<String, dynamic> json) => ShipmentEntity(
  carrier: json['carrier'] as String,
  trackingCode: json['tracking_code'] as String,
  status: json['status'] as String,
  postedAt: _date(json['posted_at']),
  deliveredAt: _date(json['delivered_at']),
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

OrdersPageEntity ordersPageFromJson(Map<String, dynamic> json) =>
    OrdersPageEntity(
      items: [
        for (final order in json['items'] as List? ?? const [])
          orderFromJson(order),
      ],
      currentPage: json['current_page'] as int,
      hasNext: json['has_next'] as bool,
    );

OrderDetailEntity orderDetailFromJson(Map<String, dynamic> json) =>
    OrderDetailEntity(
      order: orderFromJson(json),
      history: [
        for (final change in json['history'] as List? ?? const [])
          OrderStatusChangeEntity(
            from: switch (change['from']) {
              final String from => OrderStatus.fromApi(from),
              _ => null,
            },
            to: OrderStatus.fromApi(change['to'] as String),
            reason: change['reason'] as String?,
            createdAt: DateTime.parse(change['created_at'] as String),
          ),
      ],
      shipment: switch (json['shipment']) {
        final Map<String, dynamic> shipment => shipmentFromJson(shipment),
        _ => null,
      },
      canCancel: json['can_cancel'] as bool? ?? false,
      canConfirmDelivery: json['can_confirm_delivery'] as bool? ?? false,
      canStartProcessing: json['can_start_processing'] as bool? ?? false,
      canShip: json['can_ship'] as bool? ?? false,
    );
