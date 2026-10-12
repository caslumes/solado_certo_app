import 'package:solado_certo_app/features/catalog/domain/entities/purpose.dart';

class PurposeModel {
  const PurposeModel({required this.code, required this.name});

  final String code;
  final String name;

  factory PurposeModel.fromJson(Map<String, dynamic> json) =>
      PurposeModel(code: json['code'] as String, name: json['name'] as String);

  PurposeEntity toEntity() => PurposeEntity(code: code, name: name);
}
