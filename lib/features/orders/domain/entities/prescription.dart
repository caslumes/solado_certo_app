import 'package:solado_certo_app/features/orders/domain/enum/document_status.dart';

class PrescriptionEntity {
  final String id;
  final DocumentStatus status;
  final String? rejectionReason;
  final String url;
  final DateTime createdAt;

  const PrescriptionEntity({
    required this.id,
    required this.status,
    this.rejectionReason,
    required this.url,
    required this.createdAt,
  });
}
