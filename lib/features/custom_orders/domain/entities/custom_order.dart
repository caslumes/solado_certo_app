import 'package:solado_certo_app/features/custom_orders/domain/entities/measurements.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_action.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_status.dart';

class CustomOrderEntity {
  final String id;
  final CustomOrderStatus status;
  final String advertisementId;
  final String advertisementTitle;
  final String? coverUrl;
  final String buyerName;
  final String sellerName;
  final double? quotedPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomOrderEntity({
    required this.id,
    required this.status,
    required this.advertisementId,
    required this.advertisementTitle,
    this.coverUrl,
    required this.buyerName,
    required this.sellerName,
    this.quotedPrice,
    required this.createdAt,
    required this.updatedAt,
  });
}

enum CustomOrderActor { buyer, seller, system }

class CustomOrderChangeEntity {
  final CustomOrderStatus? from;
  final CustomOrderStatus to;
  final CustomOrderActor changedBy;
  final String? reason;
  final DateTime createdAt;

  const CustomOrderChangeEntity({
    this.from,
    required this.to,
    required this.changedBy,
    this.reason,
    required this.createdAt,
  });
}

class FittingReportEntity {
  final String id;
  final String url;
  final DateTime createdAt;

  const FittingReportEntity({
    required this.id,
    required this.url,
    required this.createdAt,
  });
}

class CustomOrderDetailEntity {
  final CustomOrderEntity request;
  final String? orderId;
  final Measurements measurements;
  final String? technicalNotes;
  final String? rejectionReason;
  final String? adaptationInstructions;
  final String? footPhotoUrl;
  final FittingReportEntity? fittingReport;
  final List<CustomOrderChangeEntity> history;
  final Set<CustomOrderAction> actions;

  const CustomOrderDetailEntity({
    required this.request,
    this.orderId,
    required this.measurements,
    this.technicalNotes,
    this.rejectionReason,
    this.adaptationInstructions,
    this.footPhotoUrl,
    this.fittingReport,
    this.history = const [],
    this.actions = const {},
  });

  bool can(CustomOrderAction action) => actions.contains(action);
}

class CustomOrdersPageEntity {
  final List<CustomOrderEntity> items;
  final int currentPage;
  final bool hasNext;

  const CustomOrdersPageEntity({
    required this.items,
    required this.currentPage,
    required this.hasNext,
  });
}

class NewCustomOrder {
  static const maxNotesLength = 2000;

  final String advertisementId;
  final Measurements measurements;
  final String? technicalNotes;

  const NewCustomOrder({
    required this.advertisementId,
    required this.measurements,
    this.technicalNotes,
  });
}

class CustomOrderComplement {
  static const maxMessageLength = 1000;

  final String message;
  final Measurements? measurements;
  final String? technicalNotes;

  const CustomOrderComplement({
    required this.message,
    this.measurements,
    this.technicalNotes,
  });
}
