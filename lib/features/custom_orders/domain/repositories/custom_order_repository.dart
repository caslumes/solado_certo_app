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

  Future<CustomOrdersPageEntity> getSellerRequests(int page);

  Future<CustomOrderDetailEntity> getSellerRequest(String id);

  Future<CustomOrderDetailEntity> review(String id);

  Future<CustomOrderDetailEntity> accept(String id, String quotedPrice);

  Future<CustomOrderDetailEntity> reject(String id, String reason);

  Future<CustomOrderDetailEntity> requestInfo(String id, String question);

  Future<CustomOrderDetailEntity> sendReport(
    String id, {
    required UploadFile file,
    required String adaptationInstructions,
  });
}
