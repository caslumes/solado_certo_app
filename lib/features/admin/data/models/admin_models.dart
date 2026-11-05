import 'package:solado_certo_app/features/admin/domain/entities/admin_entities.dart';
import 'package:solado_certo_app/features/admin/domain/enum/account_status.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_status.dart';
import 'package:solado_certo_app/features/profile/domain/enum/user_role.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';

AdminPageEntity<T> adminPageFromJson<T>(
  Map<String, dynamic> json,
  T Function(Map<String, dynamic> item) fromJson,
) => AdminPageEntity(
  items: [
    for (final item in json['items'] as List? ?? const [])
      fromJson(item as Map<String, dynamic>),
  ],
  currentPage: json['current_page'] as int,
  totalItems: json['total_items'] as int? ?? 0,
  hasNext: json['has_next'] as bool,
);

DateTime? _date(Object? value) =>
    value is String ? DateTime.parse(value) : null;

String? _name(Object? person) =>
    person is Map ? person['name'] as String? : null;

AdminUserEntity adminUserFromJson(Map<String, dynamic> json) => AdminUserEntity(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String,
  status: AccountStatus.fromApi(json['status'] as String),
  suspendedUntil: _date(json['suspended_until']),
  roles: [
    for (final role in json['roles'] as List? ?? const [])
      if (UserRole.fromApi(role as String) case final role?) role,
  ],
  createdAt: DateTime.parse(json['created_at'] as String),
);

AdminAdEntity adminAdFromJson(Map<String, dynamic> json) => AdminAdEntity(
  id: json['id'] as String,
  title: json['title'] as String,
  status: AdStatus.fromApi(json['status'] as String),
  price: double.parse(json['price'] as String),
  stock: json['stock'] as int,
  sellerName: _name(json['seller']) ?? '',
  createdAt: DateTime.parse(json['created_at'] as String),
  removedAt: _date(json['removed_at']),
);

AdminOrderEntity adminOrderFromJson(Map<String, dynamic> json) {
  final buyer = json['buyer'] as Map<String, dynamic>;
  return AdminOrderEntity(
    id: json['id'] as String,
    number: json['number'] as String,
    status: OrderStatus.fromApi(json['status'] as String),
    total: double.parse(json['total'] as String),
    buyerName: buyer['name'] as String,
    buyerEmail: buyer['email'] as String,
    sellerName: _name(json['seller']),
    createdAt: DateTime.parse(json['created_at'] as String),
    paidAt: _date(json['paid_at']),
    deliveredAt: _date(json['delivered_at']),
  );
}

AdminPaymentEntity adminPaymentFromJson(Map<String, dynamic> json) =>
    AdminPaymentEntity(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      method: PaymentMethod.fromApi(json['method'] as String),
      status: PaymentStatus.fromApi(json['status'] as String),
      amount: double.parse(json['amount'] as String),
      failureReason: json['failure_reason'] as String?,
      refundError: json['refund_error'] as String?,
      refundGivenUp: json['refund_given_up'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

AuditLogEntity auditLogFromJson(Map<String, dynamic> json) => AuditLogEntity(
  id: json['id'] as String,
  userName: _name(json['user']),
  entity: json['entity'] as String,
  entityId: json['entity_id'] as String,
  action: json['action'] as String,
  context: switch (json['context']) {
    final Map<String, dynamic> context => context,
    _ => const {},
  },
  createdAt: DateTime.parse(json['created_at'] as String),
);

IndicatorsEntity indicatorsFromJson(Map<String, dynamic> json) =>
    IndicatorsEntity(
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
      newUsers: json['new_users'] as int,
      blockedUsers: json['blocked_users'] as int,
      suspendedUsers: json['suspended_users'] as int,
      newAds: json['new_ads'] as int,
      publishedAds: json['published_ads'] as int,
      orders: json['orders'] as int,
      ordersByStatus: {
        for (final status in OrderStatus.values)
          if ((json['orders_by_status'] as Map?)?[status.apiValue]
              case final int count)
            status: count,
      },
      paidOrders: json['paid_orders'] as int,
      paidAmount: double.parse(json['paid_amount'] as String),
      paymentsByStatus: {
        for (final status in PaymentStatus.values)
          if ((json['payments_by_status'] as Map?)?[status.apiValue]
              case final Map amount)
            status: AmountEntity(
              count: amount['count'] as int,
              amount: double.parse(amount['amount'] as String),
            ),
      },
      refundsGivenUp: json['refunds_given_up'] as int,
      ticketsOpened: json['tickets_opened'] as int,
      ticketsResolved: json['tickets_resolved'] as int,
      openTickets: json['open_tickets'] as int,
    );

String _day(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String indicatorsQuery(DateTime from, DateTime to) =>
    'from=${_day(from)}&to=${_day(to)}';

String _query(Map<String, String?> params) => [
  for (final MapEntry(:key, :value) in params.entries)
    if (value != null && value.isNotEmpty)
      '$key=${Uri.encodeQueryComponent(value)}',
].join('&');

String adminUsersQuery(AdminUserFilter filter, int page, int limit) => _query({
  'q': filter.search,
  'status': filter.status?.apiValue,
  'page': '$page',
  'limit': '$limit',
});

String adminAdsQuery(AdminAdFilter filter, int page, int limit) => _query({
  'q': filter.search,
  'status': filter.status?.name,
  'page': '$page',
  'limit': '$limit',
});

String adminOrdersQuery(AdminOrderFilter filter, int page, int limit) =>
    _query({
      'q': filter.search,
      'status': filter.status?.apiValue,
      'page': '$page',
      'limit': '$limit',
    });

String adminPaymentsQuery(AdminPaymentFilter filter, int page, int limit) =>
    _query({
      'status': filter.status?.apiValue,
      'refund_given_up': filter.refundGivenUp ? 'true' : null,
      'page': '$page',
      'limit': '$limit',
    });

String auditLogsQuery(AuditLogFilter filter, int page, int limit) =>
    _query({'action': filter.area.prefix, 'page': '$page', 'limit': '$limit'});

Map<String, dynamic> userModerationToJson(UserModeration moderation) => {
  'reason': moderation.reason,
  if (moderation.until case final until?)
    'until': until.toUtc().toIso8601String(),
};
