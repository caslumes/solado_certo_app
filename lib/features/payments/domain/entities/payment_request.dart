import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';

class PaymentRequest {
  final PaymentMethod method;

  final String? taxId;
  final CardDetails? card;

  const PaymentRequest({required this.method, this.taxId, this.card});
}

class CardDetails {
  final String holderName;
  final String number;
  final String expiryMonth;

  final String expiryYear;
  final String cvv;

  const CardDetails({
    required this.holderName,
    required this.number,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
  });
}
