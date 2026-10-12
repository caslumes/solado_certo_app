import 'package:solado_certo_app/features/catalog/domain/entities/product_image.dart';

class ProductImageModel {
  const ProductImageModel({
    required this.url,
    required this.altText,
    required this.order,
    required this.isCover,
  });

  final String url;
  final String altText;
  final int order;
  final bool isCover;

  factory ProductImageModel.fromJson(Map<String, dynamic> json) =>
      ProductImageModel(
        url: json['url'] as String,
        altText: json['alt_text'] as String? ?? '',
        order: json['order'] as int? ?? 0,
        isCover: json['is_cover'] as bool? ?? false,
      );

  ProductImageEntity toEntity() =>
      ProductImageEntity(url: url, altText: altText);
}
