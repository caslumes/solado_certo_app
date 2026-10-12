import 'package:solado_certo_app/features/catalog/data/models/condition_model.dart';
import 'package:solado_certo_app/features/catalog/data/models/product_image_model.dart';
import 'package:solado_certo_app/features/catalog/data/models/purpose_model.dart';
import 'package:solado_certo_app/features/catalog/data/models/seller_model.dart';
import 'package:solado_certo_app/features/catalog/data/models/shipping_option_model.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/product_detail.dart';

/// A `GET /catalog/items/:id` response.
class ProductDetailModel {
  const ProductDetailModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.stock,
    required this.prescriptionRequired,
    required this.customMadeAllowed,
    required this.images,
    this.side,
    this.size,
    this.material,
    this.rigidity,
    this.usageIndication,
    this.safetyAlerts,
    this.contraindications,
    this.shippingNotes,
    this.averageRating,
    required this.reviewCount,
    required this.purposes,
    required this.conditions,
    this.seller,
    required this.shippingOptions,
    required this.safetyInfoComplete,
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final int stock;
  final bool prescriptionRequired;
  final bool customMadeAllowed;
  final List<ProductImageModel> images;
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
  final List<PurposeModel> purposes;
  final List<ConditionModel> conditions;
  final SellerModel? seller;
  final List<ShippingOptionModel> shippingOptions;
  final bool safetyInfoComplete;

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) =>
      ProductDetailModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        price: double.parse(json['price'] as String),
        stock: json['stock'] as int,
        prescriptionRequired: json['prescription_required'] as bool? ?? false,
        customMadeAllowed: json['custom_made_allowed'] as bool? ?? false,
        images: _list(json['images'], ProductImageModel.fromJson),
        side: json['side'] as String?,
        size: json['size'] as String?,
        material: json['material'] as String?,
        rigidity: json['rigidity'] as String?,
        usageIndication: json['usage_indication'] as String?,
        safetyAlerts: json['safety_alerts'] as String?,
        contraindications: json['contraindications'] as String?,
        shippingNotes: json['shipping_notes'] as String?,
        averageRating: (json['average_rating'] as num?)?.toDouble(),
        reviewCount: json['review_count'] as int? ?? 0,
        purposes: _list(json['purposes'], PurposeModel.fromJson),
        conditions: _list(json['conditions'], ConditionModel.fromJson),
        seller: json['seller'] == null
            ? null
            : SellerModel.fromJson(json['seller'] as Map<String, dynamic>),
        shippingOptions: _list(
          json['shipping_options'],
          ShippingOptionModel.fromJson,
        ),
        safetyInfoComplete: json['safety_info_complete'] as bool? ?? true,
      );

  /// Lists the images cover first, then by their order.
  ProductDetailEntity toEntity() {
    final sortedImages = [...images]
      ..sort((a, b) {
        if (a.isCover != b.isCover) return a.isCover ? -1 : 1;
        return a.order.compareTo(b.order);
      });
    return ProductDetailEntity(
      id: id,
      title: title,
      description: description,
      price: price,
      stock: stock,
      prescriptionRequired: prescriptionRequired,
      customMadeAllowed: customMadeAllowed,
      images: sortedImages.map((image) => image.toEntity()).toList(),
      side: side,
      size: size,
      material: material,
      rigidity: rigidity,
      usageIndication: usageIndication,
      safetyAlerts: safetyAlerts,
      contraindications: contraindications,
      shippingNotes: shippingNotes,
      averageRating: averageRating,
      reviewCount: reviewCount,
      purposes: purposes.map((purpose) => purpose.toEntity()).toList(),
      conditions: conditions.map((condition) => condition.toEntity()).toList(),
      seller: seller?.toEntity(),
      shippingOptions: shippingOptions
          .map((option) => option.toEntity())
          .toList(),
      safetyInfoComplete: safetyInfoComplete,
    );
  }
}

/// Maps a JSON array with [fromJson], reading a missing or null array as
/// empty.
List<T> _list<T>(Object? json, T Function(Map<String, dynamic>) fromJson) =>
    (json as List? ?? const [])
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
