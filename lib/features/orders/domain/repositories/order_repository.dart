import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';

abstract class OrderRepositoryInterface {
  /// The buyer's orders, newest first; [page] starts at 1.
  Future<OrdersPageEntity> getOrders(int page);
  Future<OrderDetailEntity> getOrder(String id);

  /// Cancels an order still awaiting payment and puts its units back on sale.
  Future<OrderDetailEntity> cancelOrder(String id);
}
