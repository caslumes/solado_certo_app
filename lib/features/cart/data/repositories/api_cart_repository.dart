import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/cart/data/models/cart_model.dart';
import 'package:solado_certo_app/features/cart/domain/entities/cart.dart';
import 'package:solado_certo_app/features/cart/domain/repositories/cart_repository.dart';

class ApiCartRepository implements CartRepositoryInterface {
  final ClientInterface client;

  ApiCartRepository(this.client);

  @override
  Future<CartEntity> getCart() => client.get('/cart').then(_cart);

  @override
  Future<CartEntity> addItem(String advertisementId, int quantity) {
    return client
        .post(
          '/cart/items',
          data: {'advertisement_id': advertisementId, 'quantity': quantity},
        )
        .then(_cart);
  }

  @override
  Future<CartEntity> changeQuantity(String advertisementId, int quantity) {
    return client
        .patch('/cart/items/$advertisementId', data: {'quantity': quantity})
        .then(_cart);
  }

  @override
  Future<CartEntity> removeItem(String advertisementId) {
    return client.delete('/cart/items/$advertisementId').then(_cart);
  }

  static CartEntity _cart(dynamic response) =>
      cartFromJson(response as Map<String, dynamic>);
}
