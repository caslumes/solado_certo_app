import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';

abstract class OrderRepositoryInterface {
  /// The buyer's orders, newest first; [page] starts at 1.
  Future<OrdersPageEntity> getOrders(int page);
  Future<OrderDetailEntity> getOrder(String id);

  /// Cancels an order still awaiting payment and puts its units back on sale.
  Future<OrderDetailEntity> cancelOrder(String id);

  /// The seller's paid orders with [status] (all when null), most recently
  /// paid first.
  Future<OrdersPageEntity> getSellerOrders(int page, {OrderStatus? status});
  Future<OrderDetailEntity> getSellerOrder(String id);

  /// The seller acknowledges a paid order; the buyer can no longer cancel it.
  Future<OrderDetailEntity> startProcessing(String id);

  /// Records the carrier and tracking code; the order becomes shipped.
  Future<OrderDetailEntity> shipOrder(
    String id, {
    required String carrier,
    required String trackingCode,
  });
}
