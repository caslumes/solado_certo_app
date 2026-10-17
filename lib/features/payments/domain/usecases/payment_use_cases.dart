import 'package:solado_certo_app/features/payments/domain/entities/payment.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment_request.dart';
import 'package:solado_certo_app/features/payments/domain/repositories/payment_repository.dart';

class CreatePaymentUseCase {
  final PaymentRepositoryInterface paymentRepository;

  CreatePaymentUseCase(this.paymentRepository);

  Future<PaymentEntity> execute(
    String orderId,
    PaymentRequest request,
    String idempotencyKey,
  ) => paymentRepository.createPayment(orderId, request, idempotencyKey);
}

class GetPaymentsUseCase {
  final PaymentRepositoryInterface paymentRepository;

  GetPaymentsUseCase(this.paymentRepository);

  Future<List<PaymentEntity>> execute(String orderId) =>
      paymentRepository.getPayments(orderId);
}
