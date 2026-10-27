import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/cart/domain/entities/cart.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';

class CheckoutSelection {
  final String addressId;

  final Map<String, String> shipping;

  const CheckoutSelection({required this.addressId, required this.shipping});
}

class CheckoutPlanEntity {
  final ShippingAddressEntity address;
  final List<PlannedOrderEntity> orders;
  final double subtotal;
  final double shippingTotal;
  final double discountTotal;
  final double total;

  const CheckoutPlanEntity({
    required this.address,
    required this.orders,
    required this.subtotal,
    required this.shippingTotal,
    required this.discountTotal,
    required this.total,
  });
}

class PlannedOrderEntity {
  final String sellerId;
  final String sellerName;
  final List<OrderItemEntity> items;
  final double subtotal;
  final double shippingTotal;
  final double discountTotal;
  final double total;

  const PlannedOrderEntity({
    required this.sellerId,
    required this.sellerName,
    required this.items,
    required this.subtotal,
    required this.shippingTotal,
    required this.discountTotal,
    required this.total,
  });
}

class CheckoutResultEntity {
  final String id;
  final List<OrderEntity> orders;
  final double total;

  const CheckoutResultEntity({
    required this.id,
    required this.orders,
    required this.total,
  });
}

class CheckoutConflict implements Exception {
  final Failure failure;
  final CartEntity cart;

  const CheckoutConflict({required this.failure, required this.cart});
}
