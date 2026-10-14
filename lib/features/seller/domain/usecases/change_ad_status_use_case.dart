import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';
import 'package:solado_certo_app/features/seller/domain/repositories/seller_repository.dart';

class ChangeAdStatusUseCase {
  final SellerRepositoryInterface sellerRepository;

  ChangeAdStatusUseCase(this.sellerRepository);

  Future<SellerAdEntity> execute(String id, AdStatusAction action) =>
      sellerRepository.changeStatus(id, action);
}
