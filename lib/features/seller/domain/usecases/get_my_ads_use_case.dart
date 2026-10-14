import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/repositories/seller_repository.dart';

class GetMyAdsUseCase {
  final SellerRepositoryInterface sellerRepository;

  GetMyAdsUseCase(this.sellerRepository);

  Future<List<SellerAdEntity>> execute() => sellerRepository.getAds();
}
