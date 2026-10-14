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

  final String? categoryId;
  final String description;
  final bool prescriptionRequired;
  final bool customMadeAllowed;
  final String? side;
  final String? size;
  final String? material;
  final String? rigidity;
  final String? usageIndication;
  final String? safetyAlerts;
  final String? contraindications;
  final String? shippingNotes;
  final List<String> purposes;
  final List<String> conditionIds;
  final List<SellerShippingOption> shippingOptions;

  /// In display order; the cover is flagged.
  final List<SellerAdImage> images;

  const SellerAdEntity({
    required this.id,
    required this.title,
    required this.price,
    required this.stock,
    required this.status,
    this.coverImageUrl,
    this.missingFields = const [],
    this.categoryId,
    this.description = '',
    this.prescriptionRequired = false,
    this.customMadeAllowed = false,
    this.side,
    this.size,
    this.material,
    this.rigidity,
    this.usageIndication,
    this.safetyAlerts,
    this.contraindications,
    this.shippingNotes,
    this.purposes = const [],
    this.conditionIds = const [],
    this.shippingOptions = const [],
    this.images = const [],
  });

  /// RF-007: not stored, shown for a published ad without stock.
  bool get isSoldOut => status == AdStatus.published && stock == 0;

  bool get isComplete => missingFields.isEmpty;
}

class SellerShippingOption {
  final String id;
  final String name;
  final String? carrier;
  final double price;
  final int deliveryDays;

  const SellerShippingOption({
    required this.id,
    required this.name,
    this.carrier,
    required this.price,
    required this.deliveryDays,
  });
}

class SellerAdImage {
  final String id;
  final String url;
  final String altText;
  final bool isCover;

  const SellerAdImage({
    required this.id,
    required this.url,
    this.altText = '',
    this.isCover = false,
  });
}
