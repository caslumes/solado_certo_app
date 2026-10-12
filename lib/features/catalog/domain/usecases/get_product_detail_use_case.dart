import 'package:solado_certo_app/features/catalog/domain/entities/product_detail.dart';
import 'package:solado_certo_app/features/catalog/domain/repositories/catalog_repository.dart';

class GetProductDetailUseCase {
  final CatalogRepositoryInterface catalogRepository;

  GetProductDetailUseCase(this.catalogRepository);

  Future<ProductDetailEntity> execute(String id) =>
      catalogRepository.getItem(id);
}
