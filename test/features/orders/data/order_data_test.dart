import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/files/downloaded_file.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/orders/data/models/order_model.dart';
import 'package:solado_certo_app/features/orders/data/repositories/api_order_repository.dart';
import 'package:solado_certo_app/features/orders/domain/enum/document_status.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';

import '../../checkout/data/checkout_data_test.dart' show checkoutJson;

class MockClient extends Mock implements ClientInterface {}

Map<String, dynamic> orderJson() =>
    (checkoutJson()['orders'] as List).single as Map<String, dynamic>;

Map<String, dynamic> pageJson() => {
  'items': [orderJson()],
  'current_page': 2,
  'total_pages': 3,
  'total_items': 21,
  'has_next': true,
  'has_previous': true,
};

const prescriptionJson = {
  'id': 'd1',
  'order_id': 'o1',
  'order_item_id': 'i1',
  'type': 'prescription',
  'status': 'rejected',
  'rejection_reason': 'Ilegível',
  'url': '/documents/d1',
  'created_at': '2026-10-14T12:30:00Z',
};

Map<String, dynamic> detailJson() => {
  ...orderJson(),
  'status': 'cancelled',
  'history': [
    {
      'from': null,
      'to': 'awaiting_payment',
      'reason': 'checkout',
      'created_at': '2026-10-14T12:00:00Z',
    },
    {
      'from': 'awaiting_payment',
      'to': 'cancelled',
      'reason': 'buyer_cancelled',
      'created_at': '2026-10-14T13:30:00Z',
    },
  ],
  'can_cancel': false,
};

void main() {
  group('models', () {
    test('reads a page of orders', () {
      final page = ordersPageFromJson(pageJson());

      expect(page.currentPage, 2);
      expect(page.hasNext, isTrue);
      expect(page.items.single.number, 'SC-20261014-564NZP');
    });

    test('reads the prescription of an item', () {
      final item = orderItemFromJson({
        ...(orderJson()['items'] as List).single as Map<String, dynamic>,
        'id': 'i1',
        'prescription_required': true,
        'prescription': prescriptionJson,
        'can_upload_prescription': true,
        'can_reject_prescription': false,
      });

      expect(item.prescriptionRequired, isTrue);
      expect(item.prescription?.status, DocumentStatus.rejected);
      expect(item.prescription?.rejectionReason, 'Ilegível');
      expect(item.prescription?.url, '/documents/d1');
      expect(item.canUploadPrescription, isTrue);
      expect(item.canRejectPrescription, isFalse);
      expect(item.awaitsPrescription, isTrue);
    });

    test('an item without the prescription fields needs none', () {
      final item = orderItemFromJson(
        (orderJson()['items'] as List).single as Map<String, dynamic>,
      );

      expect(item.prescriptionRequired, isFalse);
      expect(item.prescription, isNull);
      expect(item.awaitsPrescription, isFalse);
    });

    test('reads an empty page', () {
      final page = ordersPageFromJson({
        'items': <Map<String, dynamic>>[],
        'current_page': 1,
        'has_next': false,
      });

      expect(page.items, isEmpty);
    });

    test('reads the detail with its history', () {
      final detail = orderDetailFromJson(detailJson());

      expect(detail.order.status, OrderStatus.cancelled);
      expect(detail.canCancel, isFalse);
      final [created, cancelled] = detail.history;
      expect(created.from, isNull);
      expect(created.to, OrderStatus.awaitingPayment);
      expect(created.reasonLabel, 'Pedido criado');
      expect(created.createdAt, DateTime.utc(2026, 10, 14, 12));
      expect(cancelled.from, OrderStatus.awaitingPayment);
      expect(cancelled.to, OrderStatus.cancelled);
      expect(cancelled.reasonLabel, 'Cancelado por você');
    });

    test('every backend status has a label', () {
      for (final status in [
        'awaiting_payment',
        'paid',
        'processing',
        'shipped',
        'delivered',
        'cancelled',
        'returned',
      ]) {
        expect(OrderStatus.fromApi(status).label, isNotEmpty);
      }
    });
  });

  group('ApiOrderRepository', () {
    late MockClient client;
    late ApiOrderRepository repository;

    setUp(() {
      client = MockClient();
      repository = ApiOrderRepository(client);
    });

    test('asks for a page of 10 orders', () async {
      when(() => client.get(any())).thenAnswer((_) async => pageJson());

      final page = await repository.getOrders(2);

      expect(page.items, hasLength(1));
      verify(() => client.get('/orders?page=2&limit=10')).called(1);
    });

    test('gets one order', () async {
      when(() => client.get(any())).thenAnswer((_) async => detailJson());

      final detail = await repository.getOrder('o1');

      expect(detail.history, hasLength(2));
      verify(() => client.get('/orders/o1')).called(1);
    });

    test('uploads a prescription as the file field', () async {
      const file = UploadFile(bytes: [1, 2, 3], filename: 'receita.pdf');
      when(
        () => client.upload(
          any(),
          field: any(named: 'field'),
          file: file,
        ),
      ).thenAnswer((_) async => prescriptionJson);

      final prescription = await repository.uploadPrescription(
        'o1',
        'i1',
        file,
      );

      expect(prescription.id, 'd1');
      verify(
        () => client.upload(
          '/orders/o1/items/i1/prescription',
          field: 'file',
          file: file,
        ),
      ).called(1);
    });

    test('rejects a prescription with the reason', () async {
      when(
        () => client.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => prescriptionJson);

      await repository.rejectPrescription('o1', 'd1', reason: 'Ilegível');

      verify(
        () => client.post(
          '/seller/orders/o1/documents/d1/reject',
          data: {'reason': 'Ilegível'},
        ),
      ).called(1);
    });

    test('downloads a document', () async {
      const file = DownloadedFile(bytes: [1], contentType: 'image/png');
      when(() => client.download(any())).thenAnswer((_) async => file);

      expect(await repository.openDocument('/documents/d1'), file);
      verify(() => client.download('/documents/d1')).called(1);
    });

    test('cancels an order', () async {
      when(() => client.post(any())).thenAnswer((_) async => detailJson());

      final detail = await repository.cancelOrder('o1');

      expect(detail.order.status, OrderStatus.cancelled);
      verify(() => client.post('/orders/o1/cancel')).called(1);
    });
  });
}
