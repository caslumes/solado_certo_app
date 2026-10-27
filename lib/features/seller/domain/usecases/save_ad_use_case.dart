import 'package:solado_certo_app/features/seller/domain/entities/ad_draft.dart';
import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/repositories/seller_repository.dart';

class SaveAdUseCase {
  final SellerRepositoryInterface sellerRepository;

  SaveAdUseCase(this.sellerRepository);

  Future<SellerAdEntity> execute(String? id, AdDraft draft) => id == null
      ? sellerRepository.createAd(draft)
      : sellerRepository.updateAd(id, draft);
}
