import 'package:solado_certo_app/features/catalog/domain/entities/catalog_item.dart';

class HomeSectionEntity {
  final String code;
  final String title;
  final List<CatalogItemEntity> items;

  const HomeSectionEntity({
    required this.code,
    required this.title,
    required this.items,
  });
}
