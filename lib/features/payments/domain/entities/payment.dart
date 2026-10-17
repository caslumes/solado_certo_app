import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_status.dart';

/// One attempt to pay an order. An order can have several: a refused card
/// followed by a Pix, for example.
class PaymentEntity {
  final String id;
  final String orderId;
  final PaymentMethod method;
  final PaymentStatus status;
  final double amount;

  /// The last day to pay a Pix or boleto.
  final DateTime? dueDate;

  /// A code such as `card_refused` or `overdue`.
  final String? failureReason;

  /// The gateway's explanation of a refused card.
  final String? failureMessage;
  final PixChargeEntity? pix;
  final String? boletoUrl;
  final String? invoiceUrl;
  final CardSummaryEntity? card;
  final DateTime? capturedAt;
  final DateTime createdAt;

  const PaymentEntity({
    required this.id,
    required this.orderId,
    required this.method,
    required this.status,
    required this.amount,
    this.dueDate,
    this.failureReason,
    this.failureMessage,
    this.pix,
    this.boletoUrl,
    this.invoiceUrl,
    this.card,
    this.capturedAt,
    required this.createdAt,
  });

  /// The status as the buyer reads it, with the reason of a failure.
  String get statusLabel => switch ((status, failureReason)) {
    (PaymentStatus.failed, 'card_refused') => 'Cartão recusado',
    (PaymentStatus.failed, 'overdue') => 'Vencido',
    _ => status.label,
  };
}

class PixChargeEntity {
  /// The copy-and-paste code; the QR code is drawn from it.
  final String payload;
  final DateTime? expiresAt;

  const PixChargeEntity({required this.payload, this.expiresAt});
}

class CardSummaryEntity {
  final String last4;
  final String brand;

  const CardSummaryEntity({required this.last4, required this.brand});
}
