import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/features/catalog/data/models/catalog_page_model.dart';
import 'package:solado_certo_app/features/catalog/data/models/category_model.dart';

final _pageJson = {
  'items': [
    {
      'id': '00000000-0000-0000-0000-000000000603',
      'title': 'Órtese corretora para joanete',
      'price': '129.50',
      'stock': 15,
      'prescription_required': true,
      'cover_image_url': 'https://example.com/603.png',
      'average_rating': 4.5,
      'review_count': 2,
      'seller_state': 'SP',
    },
    {
      'id': '00000000-0000-0000-0000-000000000604',
      'title': 'Palmilha sob medida para pé plano',
      'price': '420.00',
      'stock': 0,
      'prescription_required': false,
      'cover_image_url': null,
      'average_rating': null,
      'review_count': 0,
      'seller_state': null,
    },
  ],
  'current_page': 1,
  'total_pages': 2,
  'total_items': 4,
  'has_next': true,
  'has_previous': false,
};

void main() {
  group('CatalogPageModel', () {
    test('maps the page and its items', () {
      final page = CatalogPageModel.fromJson(_pageJson).toEntity();

      expect(page.currentPage, 1);
      expect(page.totalItems, 4);
      expect(page.hasNext, isTrue);
      expect(page.items, hasLength(2));

      final rated = page.items.first;
      expect(rated.id, '00000000-0000-0000-0000-000000000603');
      expect(rated.title, 'Órtese corretora para joanete');
      expect(rated.price, 129.5);
      expect(rated.coverImageUrl, 'https://example.com/603.png');
      expect(rated.averageRating, 4.5);
      expect(rated.reviewCount, 2);
      expect(rated.sellerState, 'SP');
      expect(rated.prescriptionRequired, isTrue);
      expect(rated.isAvailable, isTrue);
    });

    test('accepts the nullable fields as null', () {
      final unrated = CatalogPageModel.fromJson(
        _pageJson,
      ).toEntity().items.last;

      expect(unrated.price, 420);
      expect(unrated.coverImageUrl, isNull);
      expect(unrated.averageRating, isNull);
      expect(unrated.sellerState, isNull);
      expect(unrated.isAvailable, isFalse);
    });

    test('reads an empty page', () {
      final page = CatalogPageModel.fromJson({
        'items': [],
        'current_page': 1,
        'total_items': 0,
        'has_next': false,
      }).toEntity();

      expect(page.items, isEmpty);
    });
  });

  test('CategoryModel keeps the subcategories', () {
    final category = CategoryModel.fromJson({
      'id': '301',
      'name': 'Palmilhas',
      'children': [
        {'id': '305', 'parent_category_id': '301', 'name': 'Sob medida'},
      ],
    }).toEntity();
    final leaf = CategoryModel.fromJson({
      'id': '302',
      'name': 'Calçados ortopédicos',
    }).toEntity();

    expect(category.children.single.name, 'Sob medida');
    expect(leaf.children, isEmpty);
  });

  test('CategoryModel reads the required attributes (RF-031)', () {
    final category = CategoryModel.fromJson({
      'id': '303',
      'name': 'Meias terapêuticas',
      'required_attributes': ['size', 'material'],
    }).toEntity();
    final old = CategoryModel.fromJson({
      'id': '302',
      'name': 'Calçados ortopédicos',
    }).toEntity();

    expect(category.requiredAttributes, ['size', 'material']);
    expect(old.requiredAttributes, isEmpty);
  });
}
