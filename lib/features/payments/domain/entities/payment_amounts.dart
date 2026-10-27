import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';

extension PaymentAmounts on OrderEntity {
  static const pixDiscountPercent = 5;

  double discountFor(PaymentMethod method) {
    if (method != PaymentMethod.pix) return 0;
    final cents = (subtotal * 100).round();
    return ((cents * pixDiscountPercent + 50) ~/ 100) / 100;
  }

  double amountFor(PaymentMethod method) =>
      ((subtotal + shippingTotal - discountFor(method)) * 100).round() / 100;
}
