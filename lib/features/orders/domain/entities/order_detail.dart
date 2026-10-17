import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';

/// An order with its status history (RF-019).
class OrderDetailEntity {
  final OrderEntity order;

  /// Oldest first; the first entry is the order's creation.
  final List<OrderStatusChangeEntity> history;
  final bool canCancel;

  const OrderDetailEntity({
    required this.order,
    required this.history,
    required this.canCancel,
  });
}

class OrderStatusChangeEntity {
  final OrderStatus? from;
  final OrderStatus to;

  /// A code such as `checkout` or `buyer_cancelled`; see [reasonLabel].
  final String? reason;
  final DateTime createdAt;

  const OrderStatusChangeEntity({
    this.from,
    required this.to,
    this.reason,
    required this.createdAt,
  });

  /// The pt-BR text for the reason codes the backend writes.
  String? get reasonLabel => switch (reason) {
    'checkout' => 'Pedido criado',
    'buyer_cancelled' => 'Cancelado por você',
    'payment_captured' => 'Pagamento aprovado',
    'payment_expired' => 'Prazo de pagamento encerrado',
    _ => null,
  };
}

/// One page of the buyer's orders, newest first.
class OrdersPageEntity {
  final List<OrderEntity> items;
  final int currentPage;
  final bool hasNext;

  const OrdersPageEntity({
    required this.items,
    required this.currentPage,
    required this.hasNext,
  });
}
