import 'package:solado_certo_app/features/catalog/domain/entities/shipping_option.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';

/// One seller's order, created by checkout.
class OrderEntity {
  final String id;
  final String number;
  final OrderStatus status;
  final String sellerId;
  final String sellerName;
  final ShippingAddressEntity address;
  final List<OrderItemEntity> items;
  final double subtotal;
  final double shippingTotal;
  final double discountTotal;
  final double total;
  final DateTime createdAt;

  const OrderEntity({
    required this.id,
    required this.number,
    required this.status,
    required this.sellerId,
    required this.sellerName,
    required this.address,
    required this.items,
    required this.subtotal,
    required this.shippingTotal,
    required this.discountTotal,
    required this.total,
    required this.createdAt,
  });
}

class OrderItemEntity {
  final String advertisementId;
  final String title;
  final String? coverImageUrl;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final ShippingOptionEntity shippingOption;

  const OrderItemEntity({
    required this.advertisementId,
    required this.title,
    this.coverImageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.shippingOption,
  });
}

/// The delivery address as it was at checkout; later edits don't change it.
class ShippingAddressEntity {
  final String? label;
  final String receiver;
  final String zipCode;
  final String street;
  final String number;
  final String? complement;
  final String district;
  final String city;
  final String state;

  const ShippingAddressEntity({
    this.label,
    required this.receiver,
    required this.zipCode,
    required this.street,
    required this.number,
    this.complement,
    required this.district,
    required this.city,
    required this.state,
  });
}
