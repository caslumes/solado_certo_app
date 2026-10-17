import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/payments/data/models/payment_model.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment_request.dart';
import 'package:solado_certo_app/features/payments/domain/repositories/payment_repository.dart';

class ApiPaymentRepository implements PaymentRepositoryInterface {
  final ClientInterface client;

  ApiPaymentRepository(this.client);

  @override
  Future<PaymentEntity> createPayment(
    String orderId,
    PaymentRequest request,
    String idempotencyKey,
  ) async {
    final response = await client.post(
      '/orders/$orderId/payments',
      data: paymentRequestToJson(request),
      headers: {'Idempotency-Key': idempotencyKey},
    );
    return paymentFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<PaymentEntity>> getPayments(String orderId) async {
    final response = await client.get('/orders/$orderId/payments');
    return paymentsFromJson(response as List? ?? const []);
  }
}
