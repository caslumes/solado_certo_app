import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/entities/shipment.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';

class OrderDetailEntity {
  final OrderEntity order;

  final List<OrderStatusChangeEntity> history;
  final ShipmentEntity? shipment;
  final bool canCancel;
  final bool canConfirmDelivery;

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

  final String? reason;
  final DateTime createdAt;

  const OrderStatusChangeEntity({
    this.from,
    required this.to,
    this.reason,
    required this.createdAt,
  });

  String? get reasonLabel => reasonLabelFor();

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
    'delivery_deadline_passed' => 'Dado como entregue 30 dias após o envio',
    _ => null,
  };
}

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
