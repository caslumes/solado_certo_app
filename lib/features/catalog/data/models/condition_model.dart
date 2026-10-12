import 'package:solado_certo_app/features/catalog/domain/entities/condition.dart';

class ConditionModel {
  const ConditionModel({required this.id, required this.name});

  final String id;
  final String name;

  factory ConditionModel.fromJson(Map<String, dynamic> json) =>
      ConditionModel(id: json['id'] as String, name: json['name'] as String);

  ConditionEntity toEntity() => ConditionEntity(id: id, name: name);
}
