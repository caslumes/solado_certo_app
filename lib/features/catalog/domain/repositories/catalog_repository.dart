import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filters.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_page.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/category.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/condition.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/product_detail.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/purpose.dart';
import 'package:solado_certo_app/features/catalog/domain/enum/catalog_sort.dart';

abstract class CatalogRepositoryInterface {
  Future<CatalogPageEntity> getItems({
    required CatalogFilters filters,
    required CatalogSort sort,
    required int page,
    required int limit,
  });
  Future<ProductDetailEntity> getItem(String id);
  Future<List<CategoryEntity>> getCategories();
  Future<List<PurposeEntity>> getPurposes();
  Future<List<ConditionEntity>> getConditions();
}
