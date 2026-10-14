import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';

abstract class SellerRepositoryInterface {
  Future<List<SellerAdEntity>> getAds();
  Future<SellerAdEntity> changeStatus(String id, AdStatusAction action);
  Future<void> removeAd(String id);
}
