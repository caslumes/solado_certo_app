import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/catalog/data/models/catalog_page_model.dart';
import 'package:solado_certo_app/features/catalog/data/models/category_model.dart';
import 'package:solado_certo_app/features/catalog/data/models/condition_model.dart';
import 'package:solado_certo_app/features/catalog/data/models/product_detail_model.dart';
import 'package:solado_certo_app/features/catalog/data/models/purpose_model.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filters.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_page.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/category.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/condition.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/product_detail.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/purpose.dart';
import 'package:solado_certo_app/features/catalog/domain/enum/catalog_sort.dart';
import 'package:solado_certo_app/features/catalog/domain/repositories/catalog_repository.dart';

class ApiCatalogRepository implements CatalogRepositoryInterface {
  final ClientInterface client;

  ApiCatalogRepository(this.client);

  @override
  Future<CatalogPageEntity> getItems({
    required CatalogFilters filters,
    required CatalogSort sort,
    required int page,
    required int limit,
  }) {
    final url = Uri(
      path: '/catalog',
      queryParameters: catalogQueryParameters(
        filters: filters,
        sort: sort,
        page: page,
        limit: limit,
      ),
    ).toString();
    return client
        .get(url)
        .then((response) => CatalogPageModel.fromJson(response).toEntity());
  }

  @override
  Future<ProductDetailEntity> getItem(String id) {
    return client
        .get('/catalog/items/${Uri.encodeComponent(id)}')
        .then((response) => ProductDetailModel.fromJson(response).toEntity());
  }

  @override
  Future<List<CategoryEntity>> getCategories() {
    return client
        .get('/catalog/categories')
        .then(
          (response) => (response['categories'] as List)
              .map((e) => CategoryModel.fromJson(e).toEntity())
              .toList(),
        );
  }

  @override
  Future<List<PurposeEntity>> getPurposes() {
    return client
        .get('/catalog/purposes')
        .then(
          (response) => (response['purposes'] as List)
              .map((e) => PurposeModel.fromJson(e).toEntity())
              .toList(),
        );
  }

  @override
  Future<List<ConditionEntity>> getConditions() {
    return client
        .get('/catalog/conditions')
        .then(
          (response) => (response['conditions'] as List)
              .map((e) => ConditionModel.fromJson(e).toEntity())
              .toList(),
        );
  }
}

Map<String, dynamic> catalogQueryParameters({
  required CatalogFilters filters,
  required CatalogSort sort,
  required int page,
  required int limit,
}) {
  final query = filters.query.trim();
  return {
    'page': '$page',
    'limit': '$limit',
    'sort': sort.apiValue,
    if (query.isNotEmpty) 'q': query,
    if (filters.categoryId != null) 'category': filters.categoryId!,
    if (filters.priceMin != null) 'price_min': '${filters.priceMin}',
    if (filters.priceMax != null) 'price_max': '${filters.priceMax}',
    if (filters.ratingMin != null) 'rating_min': '${filters.ratingMin}',
    if (filters.state != null) 'state': filters.state!,
    if (filters.purposes.isNotEmpty) 'purpose': filters.purposes.toList(),
    if (filters.conditions.isNotEmpty) 'condition': filters.conditions.toList(),
  };
}
