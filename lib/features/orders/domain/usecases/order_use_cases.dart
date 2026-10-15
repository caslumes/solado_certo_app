import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
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
