import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/catalog/data/repositories/api_catalog_repository.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filters.dart';
import 'package:solado_certo_app/features/catalog/domain/enum/catalog_sort.dart';

class MockClient extends Mock implements ClientInterface {}

void main() {
  late MockClient client;
  late ApiCatalogRepository repository;

  setUp(() {
    client = MockClient();
    repository = ApiCatalogRepository(client);
    when(() => client.get(any())).thenAnswer(
      (_) async => {
        'items': [],
        'current_page': 1,
        'total_items': 0,
        'has_next': false,
      },
    );
  });

  Future<Uri> requestedUri(CatalogFilters filters, CatalogSort sort) async {
    await repository.getItems(filters: filters, sort: sort, page: 2, limit: 20);
    return Uri.parse(verify(() => client.get(captureAny())).captured.single);
  }

  test('sends only the paging and sort without filters', () async {
    final uri = await requestedUri(
      const CatalogFilters(query: '  '),
      CatalogSort.relevance,
    );

    expect(uri.path, '/catalog');
    expect(uri.queryParameters, {
      'page': '2',
      'limit': '20',
      'sort': 'relevance',
    });
  });

  test('sends every filter, repeating purpose and condition', () async {
    final uri = await requestedUri(
      const CatalogFilters(
        query: ' pé plano ',
        categoryId: '301',
        priceMin: 50,
        priceMax: 129.9,
        ratingMin: 4,
        state: 'SP',
        purposes: {'prevention', 'correction'},
        conditions: {'501', '505'},
      ),
      CatalogSort.priceAsc,
    );

    expect(uri.queryParameters['q'], 'pé plano');
    expect(uri.queryParameters['sort'], 'price_asc');
    expect(uri.queryParameters['category'], '301');
    expect(uri.queryParameters['price_min'], '50.0');
    expect(uri.queryParameters['price_max'], '129.9');
    expect(uri.queryParameters['rating_min'], '4');
    expect(uri.queryParameters['state'], 'SP');
    expect(uri.queryParametersAll['purpose'], ['prevention', 'correction']);
    expect(uri.queryParametersAll['condition'], ['501', '505']);
  });

  test('asks for the items matching the profile', () async {
    final uri = await requestedUri(
      const CatalogFilters(forMe: true),
      CatalogSort.relevance,
    );

    expect(uri.queryParameters['for_me'], 'true');
  });

  test('reads the wrapped purposes list', () async {
    when(() => client.get('/catalog/purposes')).thenAnswer(
      (_) async => {
        'purposes': [
          {'id': '401', 'code': 'prevention', 'name': 'Prevenção'},
        ],
      },
    );

    final purposes = await repository.getPurposes();

    expect(purposes.single.code, 'prevention');
    expect(purposes.single.name, 'Prevenção');
  });

  test('gets one item by id', () async {
    when(() => client.get('/catalog/items/603')).thenAnswer(
      (_) async => {
        'id': '603',
        'title': 'Órtese corretora para joanete',
        'price': '129.50',
        'stock': 15,
      },
    );

    final product = await repository.getItem('603');

    expect(product.id, '603');
    expect(product.price, 129.5);
  });
}
