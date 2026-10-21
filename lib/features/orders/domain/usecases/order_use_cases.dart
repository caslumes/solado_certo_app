import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/orders/domain/repositories/order_repository.dart';

class GetOrdersUseCase {
  final OrderRepositoryInterface orderRepository;

  GetOrdersUseCase(this.orderRepository);

  Future<OrdersPageEntity> execute(int page) => orderRepository.getOrders(page);
}

class GetOrderUseCase {
  final OrderRepositoryInterface orderRepository;

  GetOrderUseCase(this.orderRepository);

  Future<OrderDetailEntity> execute(String id) => orderRepository.getOrder(id);
}

class CancelOrderUseCase {
  final OrderRepositoryInterface orderRepository;

  CancelOrderUseCase(this.orderRepository);

  Future<OrderDetailEntity> execute(String id) =>
      orderRepository.cancelOrder(id);
}

class GetSellerOrdersUseCase {
  final OrderRepositoryInterface orderRepository;

  GetSellerOrdersUseCase(this.orderRepository);

  Future<OrdersPageEntity> execute(int page, {OrderStatus? status}) =>
      orderRepository.getSellerOrders(page, status: status);
}

class GetSellerOrderUseCase {
  final OrderRepositoryInterface orderRepository;

  GetSellerOrderUseCase(this.orderRepository);

  Future<OrderDetailEntity> execute(String id) =>
      orderRepository.getSellerOrder(id);
}

class StartProcessingUseCase {
  final OrderRepositoryInterface orderRepository;

  StartProcessingUseCase(this.orderRepository);

  Future<OrderDetailEntity> execute(String id) =>
      orderRepository.startProcessing(id);
}

class ShipOrderUseCase {
  final OrderRepositoryInterface orderRepository;

  ShipOrderUseCase(this.orderRepository);

  Future<OrderDetailEntity> execute(
    String id, {
    required String carrier,
    required String trackingCode,
  }) => orderRepository.shipOrder(
    id,
    carrier: carrier,
    trackingCode: trackingCode,
  );
}
