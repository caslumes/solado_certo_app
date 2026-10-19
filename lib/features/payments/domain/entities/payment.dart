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

  /// Set once the money was asked back, after the buyer cancelled a paid
  /// order; the status stays captured until the gateway returns it.
  final DateTime? refundRequestedAt;

  /// Where the buyer gives the bank account to get a boleto refunded.
  final String? refundUrl;
  final DateTime? refundedAt;
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
    this.refundRequestedAt,
    this.refundUrl,
    this.refundedAt,
    required this.createdAt,
  });

  /// Whether the money is on its way back: asked for, or still to be asked
  /// for when [orderCancelled] (the gateway was out when the buyer
  /// cancelled; the backend tries again).
  bool refundPending({required bool orderCancelled}) =>
      status == PaymentStatus.captured &&
      (refundRequestedAt != null || orderCancelled);

  /// A boleto's refund waits for the buyer's bank account, given at
  /// [refundUrl].
  bool get awaitsRefundAccount =>
      status == PaymentStatus.captured && refundUrl != null;

  /// The status as the buyer reads it, with the reason of a failure or the
  /// refund on its way.
  String statusLabel({bool orderCancelled = false}) =>
      switch ((status, failureReason)) {
        _ when refundPending(orderCancelled: orderCancelled) =>
          'Estorno solicitado',
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
