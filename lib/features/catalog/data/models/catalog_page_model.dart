import 'package:solado_certo_app/features/catalog/data/models/catalog_item_model.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_page.dart';

class CatalogPageModel {
  const CatalogPageModel({
    required this.items,
    required this.currentPage,
    required this.totalItems,
    required this.hasNext,
  });

  final List<CatalogItemModel> items;
  final int currentPage;
  final int totalItems;
  final bool hasNext;

  factory CatalogPageModel.fromJson(Map<String, dynamic> json) =>
      CatalogPageModel(
        items: (json['items'] as List? ?? const [])
            .map((e) => CatalogItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentPage: json['current_page'] as int,
        totalItems: json['total_items'] as int,
        hasNext: json['has_next'] as bool,
      );

  CatalogPageEntity toEntity() => CatalogPageEntity(
    items: items.map((item) => item.toEntity()).toList(),
    currentPage: currentPage,
    totalItems: totalItems,
    hasNext: hasNext,
  );
}
