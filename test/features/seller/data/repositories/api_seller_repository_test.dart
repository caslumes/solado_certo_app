import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/seller/data/repositories/api_seller_repository.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';

class MockClient extends Mock implements ClientInterface {}

void main() {
  late MockClient client;
  late ApiSellerRepository repository;

  Map<String, dynamic> adJson({String status = 'published'}) => {
    'id': '601',
    'title': 'Palmilha',
    'price': '89.90',
    'stock': 10,
    'status': status,
    'cover_image_url': null,
    'missing_fields': <String>[],
  };

  setUp(() {
    client = MockClient();
    repository = ApiSellerRepository(client);
  });

  test('getAds reads the items', () async {
    when(() => client.get('/seller/ads')).thenAnswer(
      (_) async => {
        'items': [adJson()],
      },
    );

    final ads = await repository.getAds();

    expect(ads.single.id, '601');
  });

  test('changeStatus posts to the action route', () async {
    for (final (action, status) in [
      (AdStatusAction.publish, 'published'),
      (AdStatusAction.pause, 'paused'),
      (AdStatusAction.reactivate, 'published'),
    ]) {
      when(
        () => client.post('/seller/ads/601/${action.name}'),
      ).thenAnswer((_) async => adJson(status: status));

      final ad = await repository.changeStatus('601', action);

      expect(ad.status, AdStatus.fromApi(status));
    }
  });

  test('removeAd deletes the ad', () async {
    when(() => client.delete('/seller/ads/601')).thenAnswer((_) async => null);

    await repository.removeAd('601');

    verify(() => client.delete('/seller/ads/601')).called(1);
  });
}
