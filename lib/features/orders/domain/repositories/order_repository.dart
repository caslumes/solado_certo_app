import 'package:solado_certo_app/core/files/downloaded_file.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_filter.dart';
import 'package:solado_certo_app/features/orders/domain/entities/prescription.dart';

abstract class OrderRepositoryInterface {
  Future<OrdersPageEntity> getOrders(
    int page, {
    OrderFilter filter = const OrderFilter(),
  });
  Future<OrderDetailEntity> getOrder(String id);

  Future<OrderDetailEntity> cancelOrder(String id);

  Future<OrderDetailEntity> confirmDelivery(String id);

  Future<OrdersPageEntity> getSellerOrders(
    int page, {
    OrderFilter filter = const OrderFilter(),
  });
  Future<OrderDetailEntity> getSellerOrder(String id);

  Future<OrderDetailEntity> startProcessing(String id);

  Future<OrderDetailEntity> shipOrder(
    String id, {
    required String carrier,
    required String trackingCode,
  });

  Future<PrescriptionEntity> uploadPrescription(
    String orderId,
    String itemId,
    UploadFile file,
  );

  Future<PrescriptionEntity> rejectPrescription(
    String orderId,
    String documentId, {
    required String reason,
  });

  Future<DownloadedFile> openDocument(String url);
}
