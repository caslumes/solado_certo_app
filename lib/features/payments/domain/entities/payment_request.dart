import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';

class PaymentRequest {
  final PaymentMethod method;

  /// The buyer's CPF, digits only; sent only before the first payment.
  final String? taxId;
  final CardDetails? card;

  const PaymentRequest({required this.method, this.taxId, this.card});
}

/// Sent to the backend once and never stored by the app.
class CardDetails {
  final String holderName;
  final String number;
  final String expiryMonth;

  /// Four digits, e.g. `2030`.
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
