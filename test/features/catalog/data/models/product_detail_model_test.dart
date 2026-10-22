import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/features/catalog/data/models/product_detail_model.dart';

/// A `GET /catalog/items/:id` response for the dev seed's 603, with a
/// second image placed before the cover.
final _detailJson = {
  'id': '00000000-0000-0000-0000-000000000603',
  'seller_id': '00000000-0000-0000-0000-000000000002',
  'category_id': '00000000-0000-0000-0000-000000000303',
  'title': 'Órtese corretora para joanete',
  'description': 'Órtese noturna para alinhamento do hálux.',
  'price': '129.50',
  'stock': 15,
  'status': 'published',
  'prescription_required': true,
  'custom_made_allowed': false,
  'images': [
    {
      'url': 'https://example.com/603-side.png',
      'alt_text': 'Vista lateral',
      'order': 0,
      'is_cover': false,
    },
    {
      'url': 'https://example.com/603.png',
      'alt_text': '',
      'order': 1,
      'is_cover': true,
    },
  ],
  'side': 'left',
  'size': 'M',
  'material': 'Polipropileno',
  'rigidity': 'rigid',
  'usage_indication': 'Uso noturno',
  'safety_alerts': 'Uso apenas com orientação profissional.',
  'contraindications': 'Pós-operatório recente.',
  'shipping_notes': null,
  'cover_image_url': 'https://example.com/603.png',
  'average_rating': 4.5,
  'review_count': 2,
  'seller_state': 'SP',
  'purposes': [
    {'id': '403', 'code': 'correction', 'name': 'Correção'},
  ],
  'conditions': [
    {'id': '504', 'name': 'Hálux valgo (joanete)'},
  ],
  'seller': {
    'id': '00000000-0000-0000-0000-000000000002',
    'name': 'Loja Pé Bem',
    'state': 'SP',
    'average_rating': 4.5,
    'review_count': 12,
    'member_since': '2026-10-01T12:00:00Z',
  },
  'shipping_options': [
    {
      'id': '701',
      'name': 'PAC',
      'carrier': 'Correios',
      'price': '19.90',
      'delivery_days': 7,
    },
  ],
  'safety_info_complete': true,
};

void main() {
  test('maps every field of the detail', () {
    final product = ProductDetailModel.fromJson(_detailJson).toEntity();

    expect(product.id, '00000000-0000-0000-0000-000000000603');
    expect(product.price, 129.5);
    expect(product.isAvailable, isTrue);
    expect(product.prescriptionRequired, isTrue);
    expect(product.side, 'left');
    expect(product.rigidity, 'rigid');
    expect(product.usageIndication, 'Uso noturno');
    expect(product.contraindications, 'Pós-operatório recente.');
    expect(product.shippingNotes, isNull);
    expect(product.averageRating, 4.5);
    expect(product.purposes.single.code, 'correction');
    expect(product.conditions.single.name, 'Hálux valgo (joanete)');
    expect(product.seller?.name, 'Loja Pé Bem');
    expect(product.seller?.averageRating, 4.5);
    expect(product.seller?.reviewCount, 12);
    expect(product.seller?.memberSince, DateTime.utc(2026, 10, 1, 12));
    expect(product.shippingOptions.single.price, 19.9);
    expect(product.shippingOptions.single.deliveryDays, 7);
    expect(product.safetyInfoComplete, isTrue);
  });

  test('lists the cover image first', () {
    final product = ProductDetailModel.fromJson(_detailJson).toEntity();

    expect(product.images.map((image) => image.url), [
      'https://example.com/603.png',
      'https://example.com/603-side.png',
    ]);
    expect(product.images.last.altText, 'Vista lateral');
  });

  test('reads missing lists and seller as empty', () {
    final product = ProductDetailModel.fromJson({
      'id': '604',
      'title': 'Palmilha sob medida para pé plano',
      'price': '420.00',
      'stock': 0,
      'images': null,
      'purposes': null,
      'conditions': null,
      'seller': null,
      'shipping_options': null,
      'safety_info_complete': false,
    }).toEntity();

    expect(product.description, '');
    expect(product.images, isEmpty);
    expect(product.purposes, isEmpty);
    expect(product.conditions, isEmpty);
    expect(product.seller, isNull);
    expect(product.shippingOptions, isEmpty);
    expect(product.isAvailable, isFalse);
    expect(product.safetyInfoComplete, isFalse);
  });
}
