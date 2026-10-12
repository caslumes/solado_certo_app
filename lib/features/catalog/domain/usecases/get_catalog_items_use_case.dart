import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filters.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_page.dart';
import 'package:solado_certo_app/features/catalog/domain/enum/catalog_sort.dart';
import 'package:solado_certo_app/features/catalog/domain/repositories/catalog_repository.dart';

class GetCatalogItemsUseCase {
  static const pageSize = 20;

  final CatalogRepositoryInterface catalogRepository;

  GetCatalogItemsUseCase(this.catalogRepository);

  Future<CatalogPageEntity> execute({
    required CatalogFilters filters,
    required CatalogSort sort,
    required int page,
  }) {
    return catalogRepository.getItems(
      filters: filters,
      sort: sort,
      page: page,
      limit: pageSize,
    );
  }
}
