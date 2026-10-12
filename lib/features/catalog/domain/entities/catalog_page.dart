import 'package:solado_certo_app/features/catalog/domain/entities/catalog_item.dart';

class CatalogPageEntity {
  final List<CatalogItemEntity> items;
  final int currentPage;
  final int totalItems;
  final bool hasNext;

  const CatalogPageEntity({
    required this.items,
    required this.currentPage,
    required this.totalItems,
    required this.hasNext,
  });
}
