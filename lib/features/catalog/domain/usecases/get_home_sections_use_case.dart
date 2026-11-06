import 'package:solado_certo_app/features/catalog/domain/entities/home_section.dart';
import 'package:solado_certo_app/features/catalog/domain/repositories/catalog_repository.dart';

class GetHomeSectionsUseCase {
  final CatalogRepositoryInterface catalogRepository;

  GetHomeSectionsUseCase(this.catalogRepository);

  Future<List<HomeSectionEntity>> execute() =>
      catalogRepository.getHomeSections();
}
