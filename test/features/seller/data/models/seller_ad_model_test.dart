import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/features/seller/data/models/seller_ad_model.dart';
import 'package:solado_certo_app/features/seller/domain/entities/ad_draft.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';

import '../../../../support/builders.dart';

void main() {
  test('maps the list fields of a seller ad', () {
    final ad = sellerAdFromJson({
      'id': '602',
      'title': 'Tênis diabético',
      'price': '259.90',
      'stock': 0,
      'status': 'published',
      'cover_image_url': '/files/public/ads/a.png',
      'missing_fields': ['contraindications'],
    });

    expect(ad.id, '602');
    expect(ad.price, 259.9);
    expect(ad.status, AdStatus.published);
    expect(ad.coverImageUrl, '/files/public/ads/a.png');
    expect(ad.missingFields, ['contraindications']);
    expect(ad.isSoldOut, isTrue);
    expect(ad.isComplete, isFalse);
  });

  test('maps the form fields, shipping options and images', () {
    final ad = sellerAdFromJson({
      'id': '603',
      'category_id': '301',
      'title': 'Órtese',
      'description': 'Noturna',
      'price': '129.50',
      'stock': 15,
      'status': 'draft',
      'prescription_required': true,
      'custom_made_allowed': false,
      'side': 'left',
      'size': null,
      'material': 'Polipropileno',
      'rigidity': 'rigid',
      'usage_indication': 'Uso noturno',
      'safety_alerts': 'Com orientação',
      'contraindications': null,
      'shipping_notes': null,
      'purposes': ['correction'],
      'condition_ids': ['504'],
      'shipping_options': [
        {
          'id': '701',
          'name': 'PAC',
          'carrier': 'Correios',
          'price': '19.90',
          'delivery_days': 7,
        },
      ],
      'images': [
        {
          'id': 'i1',
          'url': '/files/public/ads/a.png',
          'alt_text': 'Frente',
          'position': 1,
          'is_cover': true,
        },
      ],
      'cover_image_url': '/files/public/ads/a.png',
      'missing_fields': <String>[],
    });

    expect(ad.categoryId, '301');
    expect(ad.description, 'Noturna');
    expect(ad.prescriptionRequired, isTrue);
    expect(ad.side, 'left');
    expect(ad.size, isNull);
    expect(ad.purposes, ['correction']);
    expect(ad.conditionIds, ['504']);
    expect(ad.shippingOptions.single.price, 19.9);
    expect(ad.shippingOptions.single.deliveryDays, 7);
    expect(ad.images.single.isCover, isTrue);
    expect(ad.images.single.altText, 'Frente');
  });

  test('adDraftToJson sends every field so cleared ones are cleared', () {
    final json = adDraftToJson(
      const AdDraft(
        title: 'Palmilha',
        categoryId: '301',
        stock: 3,
        side: 'both',
        purposes: ['prevention'],
        shippingOptions: [
          ShippingOptionDraft(
            id: '701',
            name: 'PAC',
            price: '19.90',
            deliveryDays: 7,
          ),
          ShippingOptionDraft(name: 'Retirada', price: '0', deliveryDays: 0),
        ],
      ),
    );

    expect(json['title'], 'Palmilha');
    expect(json['category_id'], '301');
    expect(json['price'], '0', reason: 'an empty price is reported missing');
    expect(json['description'], '');
    expect(json['side'], 'both');
    expect(json['rigidity'], '');
    expect(json['condition_ids'], isEmpty);
    expect(json['shipping_options'], [
      {
        'id': '701',
        'name': 'PAC',
        'carrier': '',
        'price': '19.90',
        'delivery_days': 7,
      },
      {'name': 'Retirada', 'carrier': '', 'price': '0', 'delivery_days': 0},
    ]);
  });

  test('adDraftToJson leaves out a category not chosen yet', () {
    expect(adDraftToJson(const AdDraft()).containsKey('category_id'), isFalse);
  });

  test('only a published ad without stock is sold out', () {
    expect(buildSellerAd(stock: 0).isSoldOut, isTrue);
    expect(buildSellerAd(stock: 0, status: AdStatus.paused).isSoldOut, isFalse);
    expect(buildSellerAd(stock: 0, status: AdStatus.draft).isSoldOut, isFalse);
    expect(buildSellerAd(stock: 1).isSoldOut, isFalse);
  });

  test('each status action starts from one status', () {
    expect(AdStatusAction.availableFor(AdStatus.draft), AdStatusAction.publish);
    expect(
      AdStatusAction.availableFor(AdStatus.published),
      AdStatusAction.pause,
    );
    expect(
      AdStatusAction.availableFor(AdStatus.paused),
      AdStatusAction.reactivate,
    );
    expect(AdStatusAction.availableFor(AdStatus.removed), isNull);
  });
}
