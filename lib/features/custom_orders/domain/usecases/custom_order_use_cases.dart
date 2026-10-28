import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/repositories/custom_order_repository.dart';

class GetCustomOrdersUseCase {
  final CustomOrderRepositoryInterface customOrderRepository;

  GetCustomOrdersUseCase(this.customOrderRepository);

  Future<CustomOrdersPageEntity> execute(int page) =>
      customOrderRepository.getRequests(page);
}

class GetCustomOrderUseCase {
  final CustomOrderRepositoryInterface customOrderRepository;

  GetCustomOrderUseCase(this.customOrderRepository);

  Future<CustomOrderDetailEntity> execute(String id) =>
      customOrderRepository.getRequest(id);
}

class CreateCustomOrderUseCase {
  final CustomOrderRepositoryInterface customOrderRepository;

  CreateCustomOrderUseCase(this.customOrderRepository);

  Future<CustomOrderDetailEntity> execute(NewCustomOrder request) =>
      customOrderRepository.createRequest(request);
}

class SendFootPhotoUseCase {
  final CustomOrderRepositoryInterface customOrderRepository;

  SendFootPhotoUseCase(this.customOrderRepository);

  Future<CustomOrderDetailEntity> execute(String id, UploadFile file) =>
      customOrderRepository.sendPhoto(id, file);
}

class ComplementCustomOrderUseCase {
  final CustomOrderRepositoryInterface customOrderRepository;

  ComplementCustomOrderUseCase(this.customOrderRepository);

  Future<CustomOrderDetailEntity> execute(
    String id,
    CustomOrderComplement complement,
  ) => customOrderRepository.complement(id, complement);
}

class CancelCustomOrderUseCase {
  final CustomOrderRepositoryInterface customOrderRepository;

  CancelCustomOrderUseCase(this.customOrderRepository);

  Future<CustomOrderDetailEntity> execute(String id, {String? reason}) =>
      customOrderRepository.cancel(id, reason: reason);
}

class CheckoutCustomOrderUseCase {
  final CustomOrderRepositoryInterface customOrderRepository;

  CheckoutCustomOrderUseCase(this.customOrderRepository);

  Future<CustomOrderDetailEntity> execute(
    String id, {
    required String addressId,
    required String shippingOptionId,
    required String idempotencyKey,
  }) => customOrderRepository.checkout(
    id,
    addressId: addressId,
    shippingOptionId: shippingOptionId,
    idempotencyKey: idempotencyKey,
  );
}

class GetSellerCustomOrdersUseCase {
  final CustomOrderRepositoryInterface customOrderRepository;

  GetSellerCustomOrdersUseCase(this.customOrderRepository);

  Future<CustomOrdersPageEntity> execute(int page) =>
      customOrderRepository.getSellerRequests(page);
}

class GetSellerCustomOrderUseCase {
  final CustomOrderRepositoryInterface customOrderRepository;

  GetSellerCustomOrderUseCase(this.customOrderRepository);

  Future<CustomOrderDetailEntity> execute(String id) =>
      customOrderRepository.getSellerRequest(id);
}

class ReviewCustomOrderUseCase {
  final CustomOrderRepositoryInterface customOrderRepository;

  ReviewCustomOrderUseCase(this.customOrderRepository);

  Future<CustomOrderDetailEntity> execute(String id) =>
      customOrderRepository.review(id);
}

class AcceptCustomOrderUseCase {
  final CustomOrderRepositoryInterface customOrderRepository;

  AcceptCustomOrderUseCase(this.customOrderRepository);

  Future<CustomOrderDetailEntity> execute(String id, String quotedPrice) =>
      customOrderRepository.accept(id, quotedPrice);
}

class RejectCustomOrderUseCase {
  final CustomOrderRepositoryInterface customOrderRepository;

  RejectCustomOrderUseCase(this.customOrderRepository);

  Future<CustomOrderDetailEntity> execute(String id, String reason) =>
      customOrderRepository.reject(id, reason);
}

class RequestCustomOrderInfoUseCase {
  final CustomOrderRepositoryInterface customOrderRepository;

  RequestCustomOrderInfoUseCase(this.customOrderRepository);

  Future<CustomOrderDetailEntity> execute(String id, String question) =>
      customOrderRepository.requestInfo(id, question);
}

class SendFittingReportUseCase {
  final CustomOrderRepositoryInterface customOrderRepository;

  SendFittingReportUseCase(this.customOrderRepository);

  Future<CustomOrderDetailEntity> execute(
    String id, {
    required UploadFile file,
    required String adaptationInstructions,
  }) => customOrderRepository.sendReport(
    id,
    file: file,
    adaptationInstructions: adaptationInstructions,
  );
}
