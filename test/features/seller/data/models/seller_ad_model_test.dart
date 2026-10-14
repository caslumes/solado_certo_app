import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/features/seller/data/models/seller_ad_model.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';

import '../../../../support/builders.dart';

void main() {
  test('maps the list fields of a seller ad', () {
    final ad = SellerAdModel.fromJson({
      'id': '602',
      'title': 'Tênis diabético',
      'price': '259.90',
      'stock': 0,
      'status': 'published',
      'cover_image_url': '/files/public/ads/a.png',
      'missing_fields': ['contraindications'],
      'description': 'Ignored by the list',
    }).toEntity();

    expect(ad.id, '602');
    expect(ad.price, 259.9);
    expect(ad.status, AdStatus.published);
    expect(ad.coverImageUrl, '/files/public/ads/a.png');
    expect(ad.missingFields, ['contraindications']);
    expect(ad.isSoldOut, isTrue);
    expect(ad.isComplete, isFalse);
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
