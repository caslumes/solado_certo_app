import 'package:solado_certo_app/features/profile/domain/entities/pain_point.dart';

class PainPointModel {
  const PainPointModel({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  factory PainPointModel.fromJson(Map<String, dynamic> json) => PainPointModel(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
  );

  PainPointEntity toEntity() =>
      PainPointEntity(id: id, name: name, description: description);
}
