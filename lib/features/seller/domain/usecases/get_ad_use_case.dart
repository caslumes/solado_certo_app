import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/repositories/seller_repository.dart';

class GetAdUseCase {
  final SellerRepositoryInterface sellerRepository;

  GetAdUseCase(this.sellerRepository);

  Future<SellerAdEntity> execute(String id) => sellerRepository.getAd(id);
}
