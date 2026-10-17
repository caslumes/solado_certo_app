import 'package:solado_certo_app/features/payments/domain/entities/payment.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment_request.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_status.dart';

Map<String, dynamic> paymentRequestToJson(PaymentRequest request) => {
  'method': request.method.apiValue,
  if (request.taxId case final taxId?) 'tax_id': taxId,
  if (request.card case final card?)
    'card': {
      'holder_name': card.holderName,
      'number': card.number,
      'expiry_month': card.expiryMonth,
      'expiry_year': card.expiryYear,
      'cvv': card.cvv,
    },
};

PaymentEntity paymentFromJson(Map<String, dynamic> json) {
  final pix = json['pix'] as Map<String, dynamic>?;
  final card = json['card'] as Map<String, dynamic>?;
  return PaymentEntity(
    id: json['id'] as String,
    orderId: json['order_id'] as String,
    method: PaymentMethod.fromApi(json['method'] as String),
    status: PaymentStatus.fromApi(json['status'] as String),
    amount: double.parse(json['amount'] as String),
    dueDate: _date(json['due_date']),
    failureReason: json['failure_reason'] as String?,
    failureMessage: json['failure_message'] as String?,
    pix: pix == null
        ? null
        : PixChargeEntity(
            payload: pix['payload'] as String,
            expiresAt: _date(pix['expires_at']),
          ),
    boletoUrl: json['boleto_url'] as String?,
    invoiceUrl: json['invoice_url'] as String?,
    card: card == null
        ? null
        : CardSummaryEntity(
            last4: card['last4'] as String,
            brand: card['brand'] as String,
          ),
    capturedAt: _date(json['captured_at']),
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

List<PaymentEntity> paymentsFromJson(List<dynamic> json) => [
  for (final payment in json) paymentFromJson(payment as Map<String, dynamic>),
];

DateTime? _date(Object? value) => switch (value) {
  final String text => DateTime.parse(text),
  _ => null,
};
