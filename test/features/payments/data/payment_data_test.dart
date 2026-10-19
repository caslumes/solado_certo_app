import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/payments/data/models/payment_model.dart';
import 'package:solado_certo_app/features/payments/data/repositories/api_payment_repository.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment_amounts.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment_request.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_status.dart';

import '../../../support/builders.dart';

class MockClient extends Mock implements ClientInterface {}

/// A pending Pix as `POST /orders/:id/payments` answers it.
Map<String, dynamic> pixJson() => {
  'id': 'p1',
  'order_id': 'o1',
  'method': 'pix',
  'status': 'pending',
  'amount': '105.30',
  'due_date': '2026-10-17',
  'failure_reason': null,
  'failure_message': null,
  'pix': {
    'payload': '00020101021226820014br.gov.bcb.pix',
    'expires_at': '2026-10-18T02:59:59Z',
  },
  'boleto_url': null,
  'invoice_url': 'https://sandbox.asaas.com/i/1',
  'card': null,
  'captured_at': null,
  'refunded_at': null,
  'created_at': '2026-10-15T12:30:00Z',
  'updated_at': '2026-10-15T12:30:00Z',
};

Map<String, dynamic> refusedCardJson() => {
  ...pixJson(),
  'id': 'p2',
  'method': 'credit_card',
  'status': 'failed',
  'amount': '109.80',
  'due_date': null,
  'failure_reason': 'card_refused',
  'failure_message': 'Transação não autorizada.',
  'pix': null,
  'invoice_url': null,
  'card': {'last4': '3151', 'brand': 'MASTERCARD'},
};

void main() {
  group('models', () {
    test('reads a pending Pix with its code', () {
      final payment = paymentFromJson(pixJson());

      expect(payment.method, PaymentMethod.pix);
      expect(payment.status, PaymentStatus.pending);
      expect(payment.amount, 105.3);
      expect(payment.dueDate, DateTime(2026, 10, 17));
      expect(payment.pix?.payload, '00020101021226820014br.gov.bcb.pix');
      expect(payment.pix?.expiresAt, DateTime.utc(2026, 10, 18, 2, 59, 59));
      expect(payment.invoiceUrl, 'https://sandbox.asaas.com/i/1');
      expect(payment.card, isNull);
      expect(payment.statusLabel(), 'Aguardando pagamento');
    });

    test('reads a refused card with the gateway message', () {
      final payment = paymentFromJson(refusedCardJson());

      expect(payment.method, PaymentMethod.creditCard);
      expect(payment.status, PaymentStatus.failed);
      expect(payment.failureMessage, 'Transação não autorizada.');
      expect(payment.card?.last4, '3151');
      expect(payment.dueDate, isNull);
      expect(payment.pix, isNull);
      expect(payment.statusLabel(), 'Cartão recusado');
    });

    test('reads a boleto refund waiting for the bank account', () {
      final payment = paymentFromJson({
        ...pixJson(),
        'method': 'boleto',
        'status': 'captured',
        'pix': null,
        'captured_at': '2026-10-15T13:00:00Z',
        'refund_requested_at': '2026-10-16T12:00:00Z',
        'refund_url': 'https://sandbox.asaas.com/r/1',
      });

      expect(payment.refundRequestedAt, DateTime.utc(2026, 10, 16, 12));
      expect(payment.refundUrl, 'https://sandbox.asaas.com/r/1');
      expect(payment.awaitsRefundAccount, isTrue);
      expect(payment.statusLabel(), 'Estorno solicitado');
    });

    test('labels the refund of a cancelled order before it is asked for', () {
      final payment = paymentFromJson({
        ...pixJson(),
        'status': 'captured',
        'captured_at': '2026-10-15T13:00:00Z',
      });

      expect(payment.statusLabel(), 'Aprovado');
      expect(payment.statusLabel(orderCancelled: true), 'Estorno solicitado');
      expect(payment.awaitsRefundAccount, isFalse);

      final refunded = paymentFromJson({
        ...pixJson(),
        'status': 'refunded',
        'refunded_at': '2026-10-16T12:00:00Z',
      });
      expect(refunded.refundedAt, DateTime.utc(2026, 10, 16, 12));
      expect(refunded.statusLabel(orderCancelled: true), 'Estornado');
    });

    test('rejects unknown methods and statuses', () {
      expect(
        () => paymentFromJson({...pixJson(), 'method': 'cash'}),
        throwsArgumentError,
      );
      expect(
        () => paymentFromJson({...pixJson(), 'status': 'lost'}),
        throwsArgumentError,
      );
    });

    test('sends the card and the CPF only when given', () {
      expect(
        paymentRequestToJson(const PaymentRequest(method: PaymentMethod.pix)),
        {'method': 'pix'},
      );
      expect(
        paymentRequestToJson(
          const PaymentRequest(
            method: PaymentMethod.creditCard,
            taxId: '52998224725',
            card: CardDetails(
              holderName: 'MARIA SOUZA',
              number: '4444444444444444',
              expiryMonth: '05',
              expiryYear: '2030',
              cvv: '123',
            ),
          ),
        ),
        {
          'method': 'credit_card',
          'tax_id': '52998224725',
          'card': {
            'holder_name': 'MARIA SOUZA',
            'number': '4444444444444444',
            'expiry_month': '05',
            'expiry_year': '2030',
            'cvv': '123',
          },
        },
      );
    });
  });

  test('Pix takes 5% off the subtotal, rounded like the backend', () {
    final order = buildOrder();

    expect(order.discountFor(PaymentMethod.pix), 4.5);
    expect(order.amountFor(PaymentMethod.pix), 105.3);
    expect(order.amountFor(PaymentMethod.boleto), 109.8);
    expect(order.amountFor(PaymentMethod.creditCard), 109.8);
    // 5% of 89.91 is 4.4955: half a cent rounds up.
    expect(buildOrder(subtotal: 89.91).discountFor(PaymentMethod.pix), 4.5);
    expect(buildOrder(subtotal: 89.89).discountFor(PaymentMethod.pix), 4.49);
  });

  group('repository', () {
    late MockClient client;
    late ApiPaymentRepository repository;

    setUp(() {
      client = MockClient();
      repository = ApiPaymentRepository(client);
    });

    test('creates a payment with the idempotency key', () async {
      when(
        () => client.post(
          any(),
          data: any(named: 'data'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => pixJson());

      final payment = await repository.createPayment(
        'o1',
        const PaymentRequest(method: PaymentMethod.pix),
        'key-1',
      );

      expect(payment.id, 'p1');
      verify(
        () => client.post(
          '/orders/o1/payments',
          data: {'method': 'pix'},
          headers: {'Idempotency-Key': 'key-1'},
        ),
      ).called(1);
    });

    test('lists the payments of an order', () async {
      when(
        () => client.get('/orders/o1/payments'),
      ).thenAnswer((_) async => [pixJson(), refusedCardJson()]);

      final payments = await repository.getPayments('o1');

      expect(payments.map((p) => p.id), ['p1', 'p2']);
    });
  });
}
