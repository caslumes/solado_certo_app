import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filter_options.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/category.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/condition.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/purpose.dart';
import 'package:solado_certo_app/features/catalog/domain/repositories/catalog_repository.dart';

class GetCatalogFilterOptionsUseCase {
  final CatalogRepositoryInterface catalogRepository;

  GetCatalogFilterOptionsUseCase(this.catalogRepository);

  Future<CatalogFilterOptions> execute() async {
    final results = await Future.wait([
      catalogRepository.getCategories(),
      catalogRepository.getPurposes(),
      catalogRepository.getConditions(),
    ]);
    return CatalogFilterOptions(
      categories: results[0] as List<CategoryEntity>,
      purposes: results[1] as List<PurposeEntity>,
      conditions: results[2] as List<ConditionEntity>,
    );
  }
}
