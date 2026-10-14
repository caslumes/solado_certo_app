import 'package:solado_certo_app/features/catalog/domain/entities/category.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.children,
    this.requiredAttributes = const [],
  });

  final String id;
  final String name;
  final List<CategoryModel> children;
  final List<String> requiredAttributes;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'] as String,
    name: json['name'] as String,
    children: (json['children'] as List? ?? const [])
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    requiredAttributes: [
      for (final name in json['required_attributes'] as List? ?? const [])
        name as String,
    ],
  );

  CategoryEntity toEntity() => CategoryEntity(
    id: id,
    name: name,
    children: children.map((child) => child.toEntity()).toList(),
    requiredAttributes: requiredAttributes,
  );
}
