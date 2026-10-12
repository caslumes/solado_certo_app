import 'package:solado_certo_app/features/catalog/domain/entities/seller.dart';

class SellerModel {
  const SellerModel({
    required this.id,
    required this.name,
    this.state,
    this.averageRating,
    required this.memberSince,
  });

  final String id;
  final String name;
  final String? state;
  final double? averageRating;
  final DateTime memberSince;

  factory SellerModel.fromJson(Map<String, dynamic> json) => SellerModel(
    id: json['id'] as String,
    name: json['name'] as String,
    state: json['state'] as String?,
    averageRating: (json['average_rating'] as num?)?.toDouble(),
    memberSince: DateTime.parse(json['member_since'] as String),
  );

  SellerEntity toEntity() => SellerEntity(
    id: id,
    name: name,
    state: state,
    averageRating: averageRating,
    memberSince: memberSince,
  );
}
