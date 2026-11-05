import 'package:solado_certo_app/features/admin/domain/entities/admin_entities.dart';

abstract class AdminRepositoryInterface {
  Future<IndicatorsEntity> getIndicators(DateTime from, DateTime to);
  Future<AdminPageEntity<AdminUserEntity>> getUsers(
    AdminUserFilter filter,
    int page,
  );
  Future<AdminUserEntity> moderateUser(String id, UserModeration moderation);
  Future<AdminPageEntity<AdminAdEntity>> getAds(AdminAdFilter filter, int page);
  Future<AdminAdEntity> removeAd(String id, String reason);
  Future<AdminPageEntity<AdminOrderEntity>> getOrders(
    AdminOrderFilter filter,
    int page,
  );
  Future<AdminPageEntity<AdminPaymentEntity>> getPayments(
    AdminPaymentFilter filter,
    int page,
  );
  Future<AdminPageEntity<AuditLogEntity>> getAuditLogs(
    AuditLogFilter filter,
    int page,
  );
}
