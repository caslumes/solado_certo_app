import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/seller/domain/entities/ad_draft.dart';
import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';

abstract class SellerRepositoryInterface {
  Future<List<SellerAdEntity>> getAds();
  Future<SellerAdEntity> getAd(String id);

  /// Creates the ad as a draft.
  Future<SellerAdEntity> createAd(AdDraft draft);
  Future<SellerAdEntity> updateAd(String id, AdDraft draft);
  Future<SellerAdEntity> changeStatus(String id, AdStatusAction action);
  Future<void> removeAd(String id);

  Future<SellerAdEntity> addImage(String adId, UploadFile photo);
  Future<SellerAdEntity> removeImage(String adId, String imageId);

  /// [imageIds] must list every image of the ad once.
  Future<SellerAdEntity> reorderImages(
    String adId,
    List<String> imageIds, {
    String? coverImageId,
  });
}
