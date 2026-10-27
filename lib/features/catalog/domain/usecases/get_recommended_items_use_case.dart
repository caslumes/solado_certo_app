import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filters.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_item.dart';
import 'package:solado_certo_app/features/catalog/domain/enum/catalog_sort.dart';
import 'package:solado_certo_app/features/catalog/domain/repositories/catalog_repository.dart';

class GetRecommendedItemsUseCase {
  static const limit = 10;

  final CatalogRepositoryInterface catalogRepository;

  GetRecommendedItemsUseCase(this.catalogRepository);

  Future<List<CatalogItemEntity>> execute() async {
    final page = await catalogRepository.getItems(
      filters: const CatalogFilters(forMe: true),
      sort: CatalogSort.relevance,
      page: 1,
      limit: limit,
    );
    return page.items;
  }
}
