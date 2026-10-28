import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/custom_orders/data/models/custom_order_model.dart';
import 'package:solado_certo_app/features/custom_orders/data/repositories/api_custom_order_repository.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/measurements.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/arch_type.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_action.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_status.dart';

class MockClient extends Mock implements ClientInterface {}

const measurementsJson = {
  'left': {'length_cm': 25.5, 'width_cm': 9.5},
  'right': {'length_cm': 26, 'width_cm': 9.6},
  'arch_type': 'high',
  'shoe_size': 39,
};

Map<String, dynamic> summaryJson() => {
  'id': 'c1',
  'status': 'needs_info',
  'advertisement_id': '603',
  'advertisement_title': 'Palmilha sob medida',
  'cover_url': null,
  'buyer_name': 'Maria Souza',
  'seller_name': 'Loja Pé Bem',
  'quoted_price': null,
  'created_at': '2026-10-26T12:00:00Z',
  'updated_at': '2026-10-26T13:00:00Z',
};

Map<String, dynamic> detailJson() => {
  ...summaryJson(),
  'status': 'completed',
  'quoted_price': '320.00',
  'order_id': 'o1',
  'measurements': measurementsJson,
  'technical_notes': 'Dor no calcanhar',
  'rejection_reason': null,
  'adaptation_instructions': 'Use 1 hora no primeiro dia.',
  'foot_photo_url': '/custom-orders/c1/photo',
  'fitting_report': {
    'id': 'd9',
    'url': '/documents/d9',
    'created_at': '2026-10-30T12:00:00Z',
  },
  'history': [
    {
      'previous_status': null,
      'status': 'requested',
      'changed_by': 'buyer',
      'reason': null,
      'created_at': '2026-10-26T12:00:00Z',
    },
    {
      'previous_status': 'requested',
      'status': 'needs_info',
      'changed_by': 'seller',
      'reason': 'Qual a altura do arco?',
      'created_at': '2026-10-26T13:00:00Z',
    },
    {
      'previous_status': 'approved',
      'status': 'in_production',
      'changed_by': 'system',
      'reason': null,
      'created_at': '2026-10-27T13:00:00Z',
    },
  ],
  'actions': ['cancel', 'something_new'],
};

void main() {
  group('models', () {
    test('reads the detail with measurements, report and history', () {
      final detail = customOrderDetailFromJson(detailJson());

      expect(detail.request.status, CustomOrderStatus.completed);
      expect(detail.request.quotedPrice, 320);
      expect(detail.orderId, 'o1');
      expect(
        detail.measurements,
        const Measurements(
          left: FootMeasurement(lengthCm: 25.5, widthCm: 9.5),
          right: FootMeasurement(lengthCm: 26, widthCm: 9.6),
          archType: ArchType.high,
          shoeSize: 39,
        ),
      );
      expect(detail.adaptationInstructions, 'Use 1 hora no primeiro dia.');
      expect(detail.footPhotoUrl, '/custom-orders/c1/photo');
      expect(detail.fittingReport?.url, '/documents/d9');
      final [requested, needsInfo, paid] = detail.history;
      expect(requested.from, isNull);
      expect(requested.changedBy, CustomOrderActor.buyer);
      expect(needsInfo.from, CustomOrderStatus.requested);
      expect(needsInfo.reason, 'Qual a altura do arco?');
      expect(needsInfo.changedBy, CustomOrderActor.seller);
      expect(paid.changedBy, CustomOrderActor.system);
      expect(detail.actions, {CustomOrderAction.cancel});
    });

    test('a summary without a price has none', () {
      final request = customOrderFromJson(summaryJson());

      expect(request.status, CustomOrderStatus.needsInfo);
      expect(request.quotedPrice, isNull);
      expect(request.updatedAt, DateTime.utc(2026, 10, 26, 13));
    });

    test('every backend status and arch type has a label', () {
      for (final status in [
        'requested',
        'under_review',
        'needs_info',
        'approved',
        'rejected',
        'in_production',
        'completed',
        'cancelled',
      ]) {
        expect(CustomOrderStatus.fromApi(status).apiValue, status);
        expect(CustomOrderStatus.fromApi(status).label, isNotEmpty);
      }
      for (final type in ['flat', 'normal', 'high', 'unknown']) {
        expect(ArchType.fromApi(type).apiValue, type);
      }
    });

    test('writes a complement with only what changed', () {
      expect(
        complementToJson(const CustomOrderComplement(message: 'Arco alto')),
        {'message': 'Arco alto'},
      );
      expect(
        complementToJson(
          CustomOrderComplement(
            message: 'Corrigi',
            measurements: measurementsFromJson(measurementsJson),
            technicalNotes: 'Uso diário',
          ),
        ),
        {
          'message': 'Corrigi',
          'measurements': {
            'left': {'length_cm': 25.5, 'width_cm': 9.5},
            'right': {'length_cm': 26.0, 'width_cm': 9.6},
            'arch_type': 'high',
            'shoe_size': 39,
          },
          'technical_notes': 'Uso diário',
        },
      );
    });
  });

  group('ApiCustomOrderRepository', () {
    late MockClient client;
    late ApiCustomOrderRepository repository;

    setUp(() {
      client = MockClient();
      repository = ApiCustomOrderRepository(client);
    });

    test('asks for a page of 10 requests', () async {
      when(() => client.get(any())).thenAnswer(
        (_) async => {
          'items': [summaryJson()],
          'current_page': 1,
          'has_next': false,
        },
      );

      final page = await repository.getRequests(1);

      expect(page.items.single.id, 'c1');
      verify(() => client.get('/custom-orders?page=1&limit=10')).called(1);
    });

    test('creates a request without notes', () async {
      when(
        () => client.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => detailJson());

      await repository.createRequest(
        NewCustomOrder(
          advertisementId: '603',
          measurements: measurementsFromJson(measurementsJson),
        ),
      );

      verify(
        () => client.post(
          '/custom-orders',
          data: {
            'advertisement_id': '603',
            'measurements': measurementsToJson(
              measurementsFromJson(measurementsJson),
            ),
          },
        ),
      ).called(1);
    });

    test('sends the foot photo with PUT', () async {
      const file = UploadFile(bytes: [1, 2, 3], filename: 'pe.jpg');
      when(
        () => client.upload(
          any(),
          method: any(named: 'method'),
          field: any(named: 'field'),
          file: file,
        ),
      ).thenAnswer((_) async => detailJson());

      await repository.sendPhoto('c1', file);

      verify(
        () => client.upload(
          '/custom-orders/c1/photo',
          method: 'PUT',
          field: 'file',
          file: file,
        ),
      ).called(1);
    });

    test('cancels with or without a reason', () async {
      when(
        () => client.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => detailJson());

      await repository.cancel('c1');
      await repository.cancel('c1', reason: 'Desisti');

      verify(() => client.post('/custom-orders/c1/cancel')).called(1);
      verify(
        () => client.post(
          '/custom-orders/c1/cancel',
          data: {'reason': 'Desisti'},
        ),
      ).called(1);
    });

    test('checks out with the idempotency key', () async {
      when(
        () => client.post(
          any(),
          data: any(named: 'data'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => detailJson());

      final detail = await repository.checkout(
        'c1',
        addressId: 'a1',
        shippingOptionId: '701',
        idempotencyKey: 'k1',
      );

      expect(detail.orderId, 'o1');
      verify(
        () => client.post(
          '/custom-orders/c1/checkout',
          data: {'address_id': 'a1', 'shipping_option_id': '701'},
          headers: {'Idempotency-Key': 'k1'},
        ),
      ).called(1);
    });
  });
}
