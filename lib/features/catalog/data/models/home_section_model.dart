import 'package:solado_certo_app/features/catalog/data/models/catalog_item_model.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/home_section.dart';

class HomeSectionModel {
  const HomeSectionModel({
    required this.code,
    required this.title,
    required this.items,
  });

  final String code;
  final String title;
  final List<CatalogItemModel> items;

  factory HomeSectionModel.fromJson(Map<String, dynamic> json) =>
      HomeSectionModel(
        code: json['code'] as String,
        title: json['title'] as String,
        items: (json['items'] as List)
            .map((e) => CatalogItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  HomeSectionEntity toEntity() => HomeSectionEntity(
    code: code,
    title: title,
    items: items.map((item) => item.toEntity()).toList(),
  );
}
