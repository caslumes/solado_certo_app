import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/admin/data/models/admin_models.dart';
import 'package:solado_certo_app/features/admin/data/repositories/api_admin_repository.dart';
import 'package:solado_certo_app/features/admin/domain/entities/admin_entities.dart';
import 'package:solado_certo_app/features/admin/domain/enum/account_status.dart';
import 'package:solado_certo_app/features/admin/domain/enum/audit_action.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_status.dart';
import 'package:solado_certo_app/features/profile/domain/enum/user_role.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';

class MockClient extends Mock implements ClientInterface {}

Map<String, dynamic> userJson({String status = 'suspended'}) => {
  'id': 'u1',
  'name': 'Ana Souza',
  'email': 'ana@example.com',
  'phone': '+5511999990000',
  'status': status,
  'suspended_until': '2026-11-20T02:59:59Z',
  'roles': ['buyer', 'seller', 'unknown'],
  'created_at': '2026-10-01T12:00:00Z',
};

Map<String, dynamic> adJson() => {
  'id': 'a1',
  'title': 'Palmilha ortopédica',
  'status': 'removed',
  'price': '129.90',
  'stock': 3,
  'seller': {'id': 'u2', 'name': 'Loja Pé Bom'},
  'created_at': '2026-10-02T12:00:00Z',
  'updated_at': '2026-11-02T12:00:00Z',
  'removed_at': '2026-11-02T12:00:00Z',
};

Map<String, dynamic> page(List<Map<String, dynamic>> items) => {
  'items': items,
  'current_page': 1,
  'total_pages': 2,
  'total_items': 21,
  'has_next': true,
  'has_previous': false,
};

void main() {
  group('models', () {
    test('parses a user and ignores unknown roles', () {
      final user = adminUserFromJson(userJson());

      expect(user.status, AccountStatus.suspended);
      expect(user.suspendedUntil, DateTime.utc(2026, 11, 20, 2, 59, 59));
      expect(user.roles, [UserRole.buyer, UserRole.seller]);
      expect(user.isAdmin, isFalse);
    });

    test('parses an ad, an order, a payment and an audit row', () {
      final ad = adminAdFromJson(adJson());
      expect(ad.status, AdStatus.removed);
      expect(ad.price, 129.90);
      expect(ad.sellerName, 'Loja Pé Bom');

      final order = adminOrderFromJson({
        'id': 'o1',
        'number': 'SC-1',
        'status': 'paid',
        'total': '150.00',
        'buyer': {'id': 'u1', 'name': 'Ana', 'email': 'ana@example.com'},
        'seller': null,
        'created_at': '2026-11-01T12:00:00Z',
        'paid_at': '2026-11-01T12:05:00Z',
        'delivered_at': null,
      });
      expect(order.status, OrderStatus.paid);
      expect(order.sellerName, isNull);
      expect(order.paidAt, isNotNull);

      final payment = adminPaymentFromJson({
        'id': 'p1',
        'order_id': 'o1',
        'order_number': 'SC-1',
        'gateway': 'asaas',
        'method': 'credit_card',
        'status': 'captured',
        'amount': '150.00',
        'failure_reason': null,
        'refund_error': 'refused',
        'refund_given_up': true,
        'created_at': '2026-11-01T12:00:00Z',
        'captured_at': null,
        'refunded_at': null,
      });
      expect(payment.method, PaymentMethod.creditCard);
      expect(payment.status, PaymentStatus.captured);
      expect(payment.refundGivenUp, isTrue);

      final log = auditLogFromJson({
        'id': 'l1',
        'user': null,
        'entity': 'user',
        'entity_id': 'u1',
        'action': 'admin.user_blocked',
        'context': {'reason': 'Fraude'},
        'created_at': '2026-11-01T12:00:00Z',
      });
      expect(log.userName, isNull);
      expect(log.actionLabel, 'Conta bloqueada');
      expect(log.context, {'reason': 'Fraude'});
      expect(
        auditLogFromJson({
          'id': 'l2',
          'entity': 'x',
          'entity_id': 'y',
          'action': 'other.thing',
          'context': null,
          'created_at': '2026-11-01T12:00:00Z',
        }).actionLabel,
        'other.thing',
      );
    });

    test('parses indicators in the order of the statuses', () {
      final indicators = indicatorsFromJson({
        'from': '2026-10-06',
        'to': '2026-11-04',
        'new_users': 4,
        'blocked_users': 1,
        'suspended_users': 0,
        'new_ads': 2,
        'published_ads': 9,
        'orders': 5,
        'orders_by_status': {'delivered': 2, 'paid': 3},
        'paid_orders': 5,
        'paid_amount': '640.50',
        'payments_by_status': {
          'refunded': {'count': 1, 'amount': '50.00'},
          'captured': {'count': 5, 'amount': '640.50'},
        },
        'refunds_given_up': 1,
        'tickets_opened': 3,
        'tickets_resolved': 2,
        'open_tickets': 1,
      });

      expect(indicators.ordersByStatus.keys, [
        OrderStatus.paid,
        OrderStatus.delivered,
      ]);
      expect(indicators.paymentsByStatus.keys, [
        PaymentStatus.captured,
        PaymentStatus.refunded,
      ]);
      expect(
        indicators.paymentsByStatus[PaymentStatus.captured]!.amount,
        640.5,
      );
      expect(indicators.paidAmount, 640.5);
      expect(indicators.to, DateTime(2026, 11, 4));
    });
  });

  group('ApiAdminRepository', () {
    late MockClient client;
    late ApiAdminRepository repository;

    setUp(() {
      client = MockClient();
      repository = ApiAdminRepository(client);
    });

    test('lists users with the search and status', () async {
      when(() => client.get(any())).thenAnswer((_) async => page([userJson()]));

      final result = await repository.getUsers(
        const AdminUserFilter(
          search: 'ana souza',
          status: AccountStatus.suspended,
        ),
        2,
      );

      verify(
        () => client.get(
          '/admin/users?q=ana+souza&status=suspended&page=2&limit=20',
        ),
      ).called(1);
      expect(result.items.single.name, 'Ana Souza');
      expect(result.totalItems, 21);
      expect(result.hasNext, isTrue);
    });

    test('leaves out empty filters', () async {
      when(() => client.get(any())).thenAnswer((_) async => page([]));

      await repository.getUsers(const AdminUserFilter(), 1);
      await repository.getAds(const AdminAdFilter(status: AdStatus.paused), 1);
      await repository.getOrders(
        const AdminOrderFilter(status: OrderStatus.awaitingPayment),
        1,
      );
      await repository.getPayments(
        const AdminPaymentFilter(refundGivenUp: true),
        1,
      );
      await repository.getAuditLogs(
        const AuditLogFilter(area: AuditArea.moderation),
        1,
      );
      await repository.getAuditLogs(const AuditLogFilter(), 1);

      verifyInOrder([
        () => client.get('/admin/users?page=1&limit=20'),
        () => client.get('/admin/ads?status=paused&page=1&limit=20'),
        () =>
            client.get('/admin/orders?status=awaiting_payment&page=1&limit=20'),
        () =>
            client.get('/admin/payments?refund_given_up=true&page=1&limit=20'),
        () => client.get('/admin/audit-logs?action=admin.&page=1&limit=20'),
        () => client.get('/admin/audit-logs?page=1&limit=20'),
      ]);
    });

    test('sends the moderation with the reason and the end date', () async {
      when(
        () => client.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => userJson());

      await repository.moderateUser(
        'u1',
        UserModeration(
          action: UserModerationAction.suspend,
          reason: 'Golpe no chat',
          until: DateTime.utc(2026, 11, 20, 2, 59, 59),
        ),
      );
      await repository.moderateUser(
        'u1',
        const UserModeration(
          action: UserModerationAction.block,
          reason: 'Fraude',
        ),
      );

      verifyInOrder([
        () => client.post(
          '/admin/users/u1/suspend',
          data: {
            'reason': 'Golpe no chat',
            'until': '2026-11-20T02:59:59.000Z',
          },
        ),
        () => client.post('/admin/users/u1/block', data: {'reason': 'Fraude'}),
      ]);
    });

    test('removes an ad with the reason', () async {
      when(
        () => client.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => adJson());

      final ad = await repository.removeAd('a1', 'Produto proibido');

      verify(
        () => client.post(
          '/admin/ads/a1/remove',
          data: {'reason': 'Produto proibido'},
        ),
      ).called(1);
      expect(ad.status, AdStatus.removed);
    });

    test('asks the indicators for whole days', () async {
      when(() => client.get(any())).thenAnswer(
        (_) async => {
          'from': '2026-10-06',
          'to': '2026-11-04',
          'new_users': 0,
          'blocked_users': 0,
          'suspended_users': 0,
          'new_ads': 0,
          'published_ads': 0,
          'orders': 0,
          'orders_by_status': {},
          'paid_orders': 0,
          'paid_amount': '0.00',
          'payments_by_status': {},
          'refunds_given_up': 0,
          'tickets_opened': 0,
          'tickets_resolved': 0,
          'open_tickets': 0,
        },
      );

      await repository.getIndicators(
        DateTime(2026, 10, 6),
        DateTime(2026, 11, 4),
      );

      verify(
        () => client.get('/admin/indicators?from=2026-10-06&to=2026-11-04'),
      ).called(1);
    });
  });
}
