import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_status.dart';

class PaymentEntity {
  final String id;
  final String orderId;
  final PaymentMethod method;
  final PaymentStatus status;
  final double amount;

  final DateTime? dueDate;

  final String? failureReason;

  final String? failureMessage;
  final PixChargeEntity? pix;
  final String? boletoUrl;
  final String? invoiceUrl;
  final CardSummaryEntity? card;
  final DateTime? capturedAt;

  final DateTime? refundRequestedAt;

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

  bool refundPending({required bool orderCancelled}) =>
      status == PaymentStatus.captured &&
      (refundRequestedAt != null || orderCancelled);

  bool get awaitsRefundAccount =>
      status == PaymentStatus.captured && refundUrl != null;

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
  final String payload;
  final DateTime? expiresAt;

  const PixChargeEntity({required this.payload, this.expiresAt});
}

class CardSummaryEntity {
  final String last4;
  final String brand;

  const CardSummaryEntity({required this.last4, required this.brand});
}
