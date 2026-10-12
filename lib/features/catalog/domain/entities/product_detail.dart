import 'package:solado_certo_app/features/catalog/domain/entities/condition.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/product_image.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/purpose.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/seller.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/shipping_option.dart';

class ProductDetailEntity {
  final String id;
  final String title;
  final String description;
  final double price;
  final int stock;
  final bool prescriptionRequired;
  final bool customMadeAllowed;
  final List<ProductImageEntity> images;
  final String? side;
  final String? size;
  final String? material;
  final String? rigidity;
  final String? usageIndication;
  final String? safetyAlerts;
  final String? contraindications;
  final String? shippingNotes;
  final double? averageRating;
  final int reviewCount;
  final List<PurposeEntity> purposes;
  final List<ConditionEntity> conditions;
  final SellerEntity? seller;
  final List<ShippingOptionEntity> shippingOptions;

  /// False when a prescription or condition-linked item lacks safety alerts
  /// or contraindications, so the app warns that the information is
  /// incomplete (UC-005 alternative flow).
  final bool safetyInfoComplete;

  const ProductDetailEntity({
    required this.id,
    required this.title,
    this.description = '',
    required this.price,
    required this.stock,
    this.prescriptionRequired = false,
    this.customMadeAllowed = false,
    this.images = const [],
    this.side,
    this.size,
    this.material,
    this.rigidity,
    this.usageIndication,
    this.safetyAlerts,
    this.contraindications,
    this.shippingNotes,
    this.averageRating,
    this.reviewCount = 0,
    this.purposes = const [],
    this.conditions = const [],
    this.seller,
    this.shippingOptions = const [],
    this.safetyInfoComplete = true,
  });

  bool get isAvailable => stock > 0;
}
