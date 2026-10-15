import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/orders/data/models/order_model.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/repositories/order_repository.dart';

class ApiOrderRepository implements OrderRepositoryInterface {
  static const pageSize = 10;

  final ClientInterface client;

  ApiOrderRepository(this.client);

  @override
  Future<OrdersPageEntity> getOrders(int page) async {
    final response = await client.get('/orders?page=$page&limit=$pageSize');
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
}
