import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/custom_orders/data/models/custom_order_model.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/repositories/custom_order_repository.dart';

class ApiCustomOrderRepository implements CustomOrderRepositoryInterface {
  static const pageSize = 10;

  final ClientInterface client;

  ApiCustomOrderRepository(this.client);

  @override
  Future<CustomOrdersPageEntity> getRequests(int page) async {
    final response = await client.get(
      '/custom-orders?page=$page&limit=$pageSize',
    );
    return customOrdersPageFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<CustomOrderDetailEntity> getRequest(String id) async {
    final response = await client.get('/custom-orders/$id');
    return customOrderDetailFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<CustomOrderDetailEntity> createRequest(NewCustomOrder request) async {
    final response = await client.post(
      '/custom-orders',
      data: newCustomOrderToJson(request),
    );
    return customOrderDetailFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<CustomOrderDetailEntity> sendPhoto(String id, UploadFile file) async {
    final response = await client.upload(
      '/custom-orders/$id/photo',
      method: 'PUT',
      field: 'file',
      file: file,
    );
    return customOrderDetailFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<CustomOrderDetailEntity> complement(
    String id,
    CustomOrderComplement complement,
  ) async {
    final response = await client.post(
      '/custom-orders/$id/complement',
      data: complementToJson(complement),
    );
    return customOrderDetailFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<CustomOrderDetailEntity> cancel(String id, {String? reason}) async {
    final response = await client.post(
      '/custom-orders/$id/cancel',
      data: reason == null ? null : {'reason': reason},
    );
    return customOrderDetailFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<CustomOrderDetailEntity> checkout(
    String id, {
    required String addressId,
    required String shippingOptionId,
    required String idempotencyKey,
  }) async {
    final response = await client.post(
      '/custom-orders/$id/checkout',
      data: {'address_id': addressId, 'shipping_option_id': shippingOptionId},
      headers: {'Idempotency-Key': idempotencyKey},
    );
    return customOrderDetailFromJson(response as Map<String, dynamic>);
  }
}
