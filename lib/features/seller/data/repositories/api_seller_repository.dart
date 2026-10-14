import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/seller/data/models/seller_ad_model.dart';
import 'package:solado_certo_app/features/seller/domain/entities/ad_draft.dart';
import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';
import 'package:solado_certo_app/features/seller/domain/repositories/seller_repository.dart';

class ApiSellerRepository implements SellerRepositoryInterface {
  final ClientInterface client;

  ApiSellerRepository(this.client);

  @override
  Future<List<SellerAdEntity>> getAds() {
    return client
        .get('/seller/ads')
        .then(
          (response) => (response['items'] as List)
              .map((e) => sellerAdFromJson(e))
              .toList(),
        );
  }

  @override
  Future<SellerAdEntity> getAd(String id) {
    return client.get('/seller/ads/$id').then(_ad);
  }

  @override
  Future<SellerAdEntity> createAd(AdDraft draft) {
    return client.post('/seller/ads', data: adDraftToJson(draft)).then(_ad);
  }

  @override
  Future<SellerAdEntity> updateAd(String id, AdDraft draft) {
    return client
        .patch('/seller/ads/$id', data: adDraftToJson(draft))
        .then(_ad);
  }

  @override
  Future<SellerAdEntity> changeStatus(String id, AdStatusAction action) {
    return client.post('/seller/ads/$id/${action.name}').then(_ad);
  }

  @override
  Future<void> removeAd(String id) {
    return client.delete('/seller/ads/$id');
  }

  @override
  Future<SellerAdEntity> addImage(String adId, UploadFile photo) {
    return client
        .upload('/seller/ads/$adId/images', field: 'image', file: photo)
        .then(_ad);
  }

  @override
  Future<SellerAdEntity> removeImage(String adId, String imageId) {
    return client.delete('/seller/ads/$adId/images/$imageId').then(_ad);
  }

  @override
  Future<SellerAdEntity> reorderImages(
    String adId,
    List<String> imageIds, {
    String? coverImageId,
  }) {
    return client
        .patch(
          '/seller/ads/$adId/images/order',
          data: {
            'image_ids': imageIds,
            if (coverImageId != null) 'cover_image_id': coverImageId,
          },
        )
        .then(_ad);
  }

  static SellerAdEntity _ad(dynamic response) =>
      sellerAdFromJson(response as Map<String, dynamic>);
}
