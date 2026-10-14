import 'package:solado_certo_app/features/seller/domain/repositories/seller_repository.dart';

class RemoveAdUseCase {
  final SellerRepositoryInterface sellerRepository;

  RemoveAdUseCase(this.sellerRepository);

  Future<void> execute(String id) => sellerRepository.removeAd(id);
}
