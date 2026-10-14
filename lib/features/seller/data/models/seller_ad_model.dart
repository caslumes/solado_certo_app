import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';

class SellerAdModel {
  const SellerAdModel({
    required this.id,
    required this.title,
    required this.price,
    required this.stock,
    required this.status,
    this.coverImageUrl,
    required this.missingFields,
  });

  final String id;
  final String title;
  final double price;
  final int stock;
  final AdStatus status;
  final String? coverImageUrl;
  final List<String> missingFields;

  factory SellerAdModel.fromJson(Map<String, dynamic> json) => SellerAdModel(
    id: json['id'] as String,
    title: json['title'] as String,
    price: double.parse(json['price'] as String),
    stock: json['stock'] as int,
    status: AdStatus.fromApi(json['status'] as String),
    coverImageUrl: json['cover_image_url'] as String?,
    missingFields: [
      for (final field in json['missing_fields'] as List? ?? const [])
        field as String,
    ],
  );

  SellerAdEntity toEntity() => SellerAdEntity(
    id: id,
    title: title,
    price: price,
    stock: stock,
    status: status,
    coverImageUrl: coverImageUrl,
    missingFields: missingFields,
  );
}
