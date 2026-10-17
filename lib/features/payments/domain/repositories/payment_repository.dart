import 'package:solado_certo_app/features/payments/domain/entities/payment.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment_request.dart';

abstract class PaymentRepositoryInterface {
  /// Creates a charge for the order. A refused card comes back as a failed
  /// payment, not as an error.
  Future<PaymentEntity> createPayment(
    String orderId,
    PaymentRequest request,
    String idempotencyKey,
  );

  /// The order's payment attempts, newest first. The server checks pending
  /// ones with the gateway before answering.
  Future<List<PaymentEntity>> getPayments(String orderId);
}
