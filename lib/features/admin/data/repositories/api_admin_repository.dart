import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/admin/data/models/admin_models.dart';
import 'package:solado_certo_app/features/admin/domain/entities/admin_entities.dart';
import 'package:solado_certo_app/features/admin/domain/repositories/admin_repository.dart';

class ApiAdminRepository implements AdminRepositoryInterface {
  static const pageSize = 20;

  final ClientInterface client;

  ApiAdminRepository(this.client);

  Future<AdminPageEntity<T>> _page<T>(
    String url,
    T Function(Map<String, dynamic> item) fromJson,
  ) async {
    final response = await client.get(url);
    return adminPageFromJson(response as Map<String, dynamic>, fromJson);
  }

  @override
  Future<IndicatorsEntity> getIndicators(DateTime from, DateTime to) async {
    final response = await client.get(
      '/admin/indicators?${indicatorsQuery(from, to)}',
    );
    return indicatorsFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AdminPageEntity<AdminUserEntity>> getUsers(
    AdminUserFilter filter,
    int page,
  ) => _page(
    '/admin/users?${adminUsersQuery(filter, page, pageSize)}',
    adminUserFromJson,
  );

  @override
  Future<AdminUserEntity> moderateUser(
    String id,
    UserModeration moderation,
  ) async {
    final response = await client.post(
      '/admin/users/$id/${moderation.action.apiValue}',
      data: userModerationToJson(moderation),
    );
    return adminUserFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AdminPageEntity<AdminAdEntity>> getAds(
    AdminAdFilter filter,
    int page,
  ) => _page(
    '/admin/ads?${adminAdsQuery(filter, page, pageSize)}',
    adminAdFromJson,
  );

  @override
  Future<AdminAdEntity> removeAd(String id, String reason) async {
    final response = await client.post(
      '/admin/ads/$id/remove',
      data: {'reason': reason},
    );
    return adminAdFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AdminPageEntity<AdminOrderEntity>> getOrders(
    AdminOrderFilter filter,
    int page,
  ) => _page(
    '/admin/orders?${adminOrdersQuery(filter, page, pageSize)}',
    adminOrderFromJson,
  );

  @override
  Future<AdminPageEntity<AdminPaymentEntity>> getPayments(
    AdminPaymentFilter filter,
    int page,
  ) => _page(
    '/admin/payments?${adminPaymentsQuery(filter, page, pageSize)}',
    adminPaymentFromJson,
  );

  @override
  Future<AdminPageEntity<AuditLogEntity>> getAuditLogs(
    AuditLogFilter filter,
    int page,
  ) => _page(
    '/admin/audit-logs?${auditLogsQuery(filter, page, pageSize)}',
    auditLogFromJson,
  );
}
