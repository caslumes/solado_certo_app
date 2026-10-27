import 'package:solado_certo_app/features/payments/domain/entities/payment.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment_request.dart';

abstract class PaymentRepositoryInterface {
  Future<PaymentEntity> createPayment(
    String orderId,
    PaymentRequest request,
    String idempotencyKey,
  );

  Future<List<PaymentEntity>> getPayments(String orderId);
}
