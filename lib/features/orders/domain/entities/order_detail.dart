import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/entities/shipment.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';

/// An order with its status history (RF-019).
class OrderDetailEntity {
  final OrderEntity order;

  /// Oldest first; the first entry is the order's creation.
  final List<OrderStatusChangeEntity> history;
  final ShipmentEntity? shipment;
  final bool canCancel;
  final bool canConfirmDelivery;

  /// The seller's actions, only in the seller's view.
  final bool canStartProcessing;
  final bool canShip;

  const OrderDetailEntity({
    required this.order,
    required this.history,
    this.shipment,
    required this.canCancel,
    this.canConfirmDelivery = false,
    this.canStartProcessing = false,
    this.canShip = false,
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

  /// The pt-BR text for the reason codes the backend writes, as the buyer
  /// reads it.
  String? get reasonLabel => reasonLabelFor();

  /// [seller] words what the buyer did in the third person.
  String? reasonLabelFor({bool seller = false}) => switch (reason) {
    'checkout' => 'Pedido criado',
    'buyer_cancelled' =>
      seller ? 'Cancelado pelo comprador' : 'Cancelado por você',
    'payment_captured' => 'Pagamento aprovado',
    'payment_expired' => 'Prazo de pagamento encerrado',
    'seller_started_processing' =>
      seller ? 'Você iniciou a preparação' : 'O vendedor iniciou a preparação',
    'seller_shipped' => seller ? 'Você informou o envio' : 'O vendedor enviou',
    'buyer_confirmed_delivery' =>
      seller
          ? 'O comprador confirmou o recebimento'
          : 'Você confirmou o recebimento',
    _ => null,
  };
}

/// One page of the buyer's orders or the seller's sales, newest first.
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
