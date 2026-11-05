import 'package:solado_certo_app/features/admin/domain/enum/account_status.dart';
import 'package:solado_certo_app/features/admin/domain/enum/audit_action.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_status.dart';
import 'package:solado_certo_app/features/profile/domain/enum/user_role.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';

class AdminPageEntity<T> {
  final List<T> items;
  final int currentPage;
  final int totalItems;
  final bool hasNext;

  const AdminPageEntity({
    required this.items,
    required this.currentPage,
    required this.totalItems,
    required this.hasNext,
  });
}

class AdminUserEntity {
  final String id;
  final String name;
  final String email;
  final String phone;
  final AccountStatus status;
  final DateTime? suspendedUntil;
  final List<UserRole> roles;
  final DateTime createdAt;

  const AdminUserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    this.suspendedUntil,
    required this.roles,
    required this.createdAt,
  });

  bool get isAdmin => roles.contains(UserRole.admin);
}

class AdminAdEntity {
  final String id;
  final String title;
  final AdStatus status;
  final double price;
  final int stock;
  final String sellerName;
  final DateTime createdAt;
  final DateTime? removedAt;

  const AdminAdEntity({
    required this.id,
    required this.title,
    required this.status,
    required this.price,
    required this.stock,
    required this.sellerName,
    required this.createdAt,
    this.removedAt,
  });
}

class AdminOrderEntity {
  final String id;
  final String number;
  final OrderStatus status;
  final double total;
  final String buyerName;
  final String buyerEmail;
  final String? sellerName;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? deliveredAt;

  const AdminOrderEntity({
    required this.id,
    required this.number,
    required this.status,
    required this.total,
    required this.buyerName,
    required this.buyerEmail,
    this.sellerName,
    required this.createdAt,
    this.paidAt,
    this.deliveredAt,
  });
}

class AdminPaymentEntity {
  final String id;
  final String orderNumber;
  final PaymentMethod method;
  final PaymentStatus status;
  final double amount;
  final String? failureReason;
  final String? refundError;
  final bool refundGivenUp;
  final DateTime createdAt;

  const AdminPaymentEntity({
    required this.id,
    required this.orderNumber,
    required this.method,
    required this.status,
    required this.amount,
    this.failureReason,
    this.refundError,
    required this.refundGivenUp,
    required this.createdAt,
  });
}

class AuditLogEntity {
  final String id;
  final String? userName;
  final String entity;
  final String entityId;
  final String action;
  final Map<String, dynamic> context;
  final DateTime createdAt;

  const AuditLogEntity({
    required this.id,
    this.userName,
    required this.entity,
    required this.entityId,
    required this.action,
    required this.context,
    required this.createdAt,
  });

  String get actionLabel => auditActionLabel(action);
}

class AmountEntity {
  final int count;
  final double amount;

  const AmountEntity({required this.count, required this.amount});
}

class IndicatorsEntity {
  final DateTime from;
  final DateTime to;
  final int newUsers;
  final int blockedUsers;
  final int suspendedUsers;
  final int newAds;
  final int publishedAds;
  final int orders;
  final Map<OrderStatus, int> ordersByStatus;
  final int paidOrders;
  final double paidAmount;
  final Map<PaymentStatus, AmountEntity> paymentsByStatus;
  final int refundsGivenUp;
  final int ticketsOpened;
  final int ticketsResolved;
  final int openTickets;

  const IndicatorsEntity({
    required this.from,
    required this.to,
    required this.newUsers,
    required this.blockedUsers,
    required this.suspendedUsers,
    required this.newAds,
    required this.publishedAds,
    required this.orders,
    required this.ordersByStatus,
    required this.paidOrders,
    required this.paidAmount,
    required this.paymentsByStatus,
    required this.refundsGivenUp,
    required this.ticketsOpened,
    required this.ticketsResolved,
    required this.openTickets,
  });
}

class AdminUserFilter {
  final String search;
  final AccountStatus? status;

  const AdminUserFilter({this.search = '', this.status});
}

class AdminAdFilter {
  final String search;
  final AdStatus? status;

  const AdminAdFilter({this.search = '', this.status});
}

class AdminOrderFilter {
  final String search;
  final OrderStatus? status;

  const AdminOrderFilter({this.search = '', this.status});
}

class AdminPaymentFilter {
  final PaymentStatus? status;
  final bool refundGivenUp;

  const AdminPaymentFilter({this.status, this.refundGivenUp = false});
}

class AuditLogFilter {
  final AuditArea area;

  const AuditLogFilter({this.area = AuditArea.all});
}

class UserModeration {
  final UserModerationAction action;
  final String reason;
  final DateTime? until;

  const UserModeration({
    required this.action,
    required this.reason,
    this.until,
  });
}
