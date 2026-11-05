import 'package:solado_certo_app/features/admin/domain/entities/admin_entities.dart';
import 'package:solado_certo_app/features/admin/domain/repositories/admin_repository.dart';

class GetIndicatorsUseCase {
  final AdminRepositoryInterface repository;

  GetIndicatorsUseCase(this.repository);

  Future<IndicatorsEntity> execute(DateTime from, DateTime to) =>
      repository.getIndicators(from, to);
}

class GetAdminUsersUseCase {
  final AdminRepositoryInterface repository;

  GetAdminUsersUseCase(this.repository);

  Future<AdminPageEntity<AdminUserEntity>> execute(
    AdminUserFilter filter,
    int page,
  ) => repository.getUsers(filter, page);
}

class ModerateUserUseCase {
  final AdminRepositoryInterface repository;

  ModerateUserUseCase(this.repository);

  Future<AdminUserEntity> execute(String id, UserModeration moderation) =>
      repository.moderateUser(id, moderation);
}

class GetAdminAdsUseCase {
  final AdminRepositoryInterface repository;

  GetAdminAdsUseCase(this.repository);

  Future<AdminPageEntity<AdminAdEntity>> execute(
    AdminAdFilter filter,
    int page,
  ) => repository.getAds(filter, page);
}

class TakeDownAdUseCase {
  final AdminRepositoryInterface repository;

  TakeDownAdUseCase(this.repository);

  Future<AdminAdEntity> execute(String id, String reason) =>
      repository.removeAd(id, reason);
}

class GetAdminOrdersUseCase {
  final AdminRepositoryInterface repository;

  GetAdminOrdersUseCase(this.repository);

  Future<AdminPageEntity<AdminOrderEntity>> execute(
    AdminOrderFilter filter,
    int page,
  ) => repository.getOrders(filter, page);
}

class GetAdminPaymentsUseCase {
  final AdminRepositoryInterface repository;

  GetAdminPaymentsUseCase(this.repository);

  Future<AdminPageEntity<AdminPaymentEntity>> execute(
    AdminPaymentFilter filter,
    int page,
  ) => repository.getPayments(filter, page);
}

class GetAuditLogsUseCase {
  final AdminRepositoryInterface repository;

  GetAuditLogsUseCase(this.repository);

  Future<AdminPageEntity<AuditLogEntity>> execute(
    AuditLogFilter filter,
    int page,
  ) => repository.getAuditLogs(filter, page);
}
