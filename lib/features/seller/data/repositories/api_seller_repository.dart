import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/seller/data/models/seller_ad_model.dart';
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
              .map((e) => SellerAdModel.fromJson(e).toEntity())
              .toList(),
        );
  }

  @override
  Future<SellerAdEntity> changeStatus(String id, AdStatusAction action) {
    return client
        .post('/seller/ads/$id/${action.name}')
        .then((response) => SellerAdModel.fromJson(response).toEntity());
  }

  @override
  Future<void> removeAd(String id) {
    return client.delete('/seller/ads/$id');
  }
}
