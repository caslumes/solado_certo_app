import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';

abstract class CustomOrderRepositoryInterface {
  Future<CustomOrdersPageEntity> getRequests(int page);

  Future<CustomOrderDetailEntity> getRequest(String id);

  Future<CustomOrderDetailEntity> createRequest(NewCustomOrder request);

  Future<CustomOrderDetailEntity> sendPhoto(String id, UploadFile file);

  Future<CustomOrderDetailEntity> complement(
    String id,
    CustomOrderComplement complement,
  );

  Future<CustomOrderDetailEntity> cancel(String id, {String? reason});

  Future<CustomOrderDetailEntity> checkout(
    String id, {
    required String addressId,
    required String shippingOptionId,
    required String idempotencyKey,
  });
}
