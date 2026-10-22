import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/orders/data/models/order_model.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_filter.dart';
import 'package:solado_certo_app/features/orders/domain/repositories/order_repository.dart';

class ApiOrderRepository implements OrderRepositoryInterface {
  static const pageSize = 10;

  final ClientInterface client;
  final DateTime Function() _now;

  ApiOrderRepository(this.client, {DateTime Function() now = DateTime.now})
    : _now = now;

  @override
  Future<OrdersPageEntity> getOrders(
    int page, {
    OrderFilter filter = const OrderFilter(),
  }) async {
    final response = await client.get(
      '/orders?page=$page&limit=$pageSize${filter.query(_now())}',
    );
    return ordersPageFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<OrderDetailEntity> getOrder(String id) async {
    final response = await client.get('/orders/$id');
    return orderDetailFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<OrderDetailEntity> cancelOrder(String id) async {
    final response = await client.post('/orders/$id/cancel');
    return orderDetailFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<OrderDetailEntity> confirmDelivery(String id) async {
    final response = await client.post('/orders/$id/delivered');
    return orderDetailFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<OrdersPageEntity> getSellerOrders(
    int page, {
    OrderFilter filter = const OrderFilter(),
  }) async {
    final response = await client.get(
      '/seller/orders?page=$page&limit=$pageSize${filter.query(_now())}',
    );
    return ordersPageFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<OrderDetailEntity> getSellerOrder(String id) async {
    final response = await client.get('/seller/orders/$id');
    return orderDetailFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<OrderDetailEntity> startProcessing(String id) async {
    final response = await client.post('/seller/orders/$id/processing');
    return orderDetailFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<OrderDetailEntity> shipOrder(
    String id, {
    required String carrier,
    required String trackingCode,
  }) async {
    final response = await client.post(
      '/seller/orders/$id/shipment',
      data: {'carrier': carrier, 'tracking_code': trackingCode},
    );
    return orderDetailFromJson(response as Map<String, dynamic>);
  }
}
