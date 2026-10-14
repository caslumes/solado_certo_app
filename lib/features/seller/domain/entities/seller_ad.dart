import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';

/// One of the seller's own ads, in any status.
class SellerAdEntity {
  final String id;
  final String title;
  final double price;
  final int stock;
  final AdStatus status;
  final String? coverImageUrl;

  /// JSON names of the fields that block publishing, in form order.
  final List<String> missingFields;

  const SellerAdEntity({
    required this.id,
    required this.title,
    required this.price,
    required this.stock,
    required this.status,
    this.coverImageUrl,
    this.missingFields = const [],
  });

  /// RF-007: not stored, shown for a published ad without stock.
  bool get isSoldOut => status == AdStatus.published && stock == 0;

  bool get isComplete => missingFields.isEmpty;
}
