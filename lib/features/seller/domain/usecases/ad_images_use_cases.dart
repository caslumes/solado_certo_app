import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/repositories/seller_repository.dart';

class AddAdImageUseCase {
  final SellerRepositoryInterface sellerRepository;

  AddAdImageUseCase(this.sellerRepository);

  Future<SellerAdEntity> execute(String adId, UploadFile photo) =>
      sellerRepository.addImage(adId, photo);
}

class RemoveAdImageUseCase {
  final SellerRepositoryInterface sellerRepository;

  RemoveAdImageUseCase(this.sellerRepository);

  Future<SellerAdEntity> execute(String adId, String imageId) =>
      sellerRepository.removeImage(adId, imageId);
}

class ReorderAdImagesUseCase {
  final SellerRepositoryInterface sellerRepository;

  ReorderAdImagesUseCase(this.sellerRepository);

  Future<SellerAdEntity> execute(
    String adId,
    List<String> imageIds, {
    String? coverImageId,
  }) => sellerRepository.reorderImages(
    adId,
    imageIds,
    coverImageId: coverImageId,
  );
}
