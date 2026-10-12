import 'package:solado_certo_app/features/catalog/domain/entities/catalog_item.dart';

class CatalogItemModel {
  const CatalogItemModel({
    required this.id,
    required this.title,
    required this.price,
    required this.stock,
    this.coverImageUrl,
    this.averageRating,
    required this.reviewCount,
    this.sellerState,
    required this.prescriptionRequired,
  });

  final String id;
  final String title;
  final double price;
  final int stock;
  final String? coverImageUrl;
  final double? averageRating;
  final int reviewCount;
  final String? sellerState;
  final bool prescriptionRequired;

  factory CatalogItemModel.fromJson(Map<String, dynamic> json) =>
      CatalogItemModel(
        id: json['id'] as String,
        title: json['title'] as String,
        price: double.parse(json['price'] as String),
        stock: json['stock'] as int,
        coverImageUrl: json['cover_image_url'] as String?,
        averageRating: (json['average_rating'] as num?)?.toDouble(),
        reviewCount: json['review_count'] as int? ?? 0,
        sellerState: json['seller_state'] as String?,
        prescriptionRequired: json['prescription_required'] as bool? ?? false,
      );

  CatalogItemEntity toEntity() => CatalogItemEntity(
    id: id,
    title: title,
    price: price,
    stock: stock,
    coverImageUrl: coverImageUrl,
    averageRating: averageRating,
    reviewCount: reviewCount,
    sellerState: sellerState,
    prescriptionRequired: prescriptionRequired,
  );
}
