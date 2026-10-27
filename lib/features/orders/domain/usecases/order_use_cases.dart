import 'package:solado_certo_app/core/files/downloaded_file.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_filter.dart';
import 'package:solado_certo_app/features/orders/domain/entities/prescription.dart';
import 'package:solado_certo_app/features/orders/domain/repositories/order_repository.dart';

class GetOrdersUseCase {
  final OrderRepositoryInterface orderRepository;

  GetOrdersUseCase(this.orderRepository);

  Future<OrdersPageEntity> execute(
    int page, {
    OrderFilter filter = const OrderFilter(),
  }) => orderRepository.getOrders(page, filter: filter);
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

class ConfirmDeliveryUseCase {
  final OrderRepositoryInterface orderRepository;

  ConfirmDeliveryUseCase(this.orderRepository);

  Future<OrderDetailEntity> execute(String id) =>
      orderRepository.confirmDelivery(id);
}

class GetSellerOrdersUseCase {
  final OrderRepositoryInterface orderRepository;

  GetSellerOrdersUseCase(this.orderRepository);

  Future<OrdersPageEntity> execute(
    int page, {
    OrderFilter filter = const OrderFilter(),
  }) => orderRepository.getSellerOrders(page, filter: filter);
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

class UploadPrescriptionUseCase {
  final OrderRepositoryInterface orderRepository;

  UploadPrescriptionUseCase(this.orderRepository);

  Future<PrescriptionEntity> execute(
    String orderId,
    String itemId,
    UploadFile file,
  ) => orderRepository.uploadPrescription(orderId, itemId, file);
}

class RejectPrescriptionUseCase {
  final OrderRepositoryInterface orderRepository;

  RejectPrescriptionUseCase(this.orderRepository);

  Future<PrescriptionEntity> execute(
    String orderId,
    String documentId, {
    required String reason,
  }) => orderRepository.rejectPrescription(orderId, documentId, reason: reason);
}

class OpenDocumentUseCase {
  final OrderRepositoryInterface orderRepository;

  OpenDocumentUseCase(this.orderRepository);

  Future<DownloadedFile> execute(String url) =>
      orderRepository.openDocument(url);
}
