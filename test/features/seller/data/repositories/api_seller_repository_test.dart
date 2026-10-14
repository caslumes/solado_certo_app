import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/seller/data/repositories/api_seller_repository.dart';
import 'package:solado_certo_app/features/seller/domain/entities/ad_draft.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';

class MockClient extends Mock implements ClientInterface {}

void main() {
  late MockClient client;
  late ApiSellerRepository repository;

  const photo = UploadFile(bytes: [1, 2, 3], filename: 'foto.jpg');
  const draft = AdDraft(title: 'Palmilha', categoryId: '301');

  Map<String, dynamic> adJson({String status = 'published'}) => {
    'id': '601',
    'title': 'Palmilha',
    'price': '89.90',
    'stock': 10,
    'status': status,
    'cover_image_url': null,
    'missing_fields': <String>[],
  };

  setUpAll(() => registerFallbackValue(photo));

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

  test('getAd reads one ad', () async {
    when(() => client.get('/seller/ads/601')).thenAnswer((_) async => adJson());

    expect((await repository.getAd('601')).title, 'Palmilha');
  });

  test('createAd posts the draft and updateAd patches it', () async {
    when(
      () => client.post('/seller/ads', data: any(named: 'data')),
    ).thenAnswer((_) async => adJson(status: 'draft'));
    when(
      () => client.patch('/seller/ads/601', data: any(named: 'data')),
    ).thenAnswer((_) async => adJson(status: 'draft'));

    await repository.createAd(draft);
    await repository.updateAd('601', draft);

    final created =
        verify(
              () => client.post('/seller/ads', data: captureAny(named: 'data')),
            ).captured.single
            as Map<String, dynamic>;
    expect(created['title'], 'Palmilha');
    expect(created['category_id'], '301');
    verify(
      () => client.patch('/seller/ads/601', data: any(named: 'data')),
    ).called(1);
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

  test('addImage uploads the photo as the image field', () async {
    when(
      () => client.upload(
        any(),
        field: any(named: 'field'),
        file: any(named: 'file'),
      ),
    ).thenAnswer((_) async => adJson());

    await repository.addImage('601', photo);

    verify(
      () =>
          client.upload('/seller/ads/601/images', field: 'image', file: photo),
    ).called(1);
  });

  test('removeImage deletes the image of the ad', () async {
    when(
      () => client.delete('/seller/ads/601/images/i1'),
    ).thenAnswer((_) async => adJson());

    await repository.removeImage('601', 'i1');

    verify(() => client.delete('/seller/ads/601/images/i1')).called(1);
  });

  test('reorderImages sends the order and the cover when given', () async {
    when(
      () => client.patch(
        '/seller/ads/601/images/order',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => adJson());

    await repository.reorderImages('601', ['i2', 'i1']);
    await repository.reorderImages('601', ['i2', 'i1'], coverImageId: 'i1');

    final bodies = verify(
      () => client.patch(
        '/seller/ads/601/images/order',
        data: captureAny(named: 'data'),
      ),
    ).captured;
    expect(bodies, [
      {
        'image_ids': ['i2', 'i1'],
      },
      {
        'image_ids': ['i2', 'i1'],
        'cover_image_id': 'i1',
      },
    ]);
  });
}
