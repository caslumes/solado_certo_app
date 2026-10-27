import 'package:solado_certo_app/features/cart/domain/entities/cart.dart';

abstract class CartRepositoryInterface {
  Future<CartEntity> getCart();

  Future<CartEntity> addItem(String advertisementId, int quantity);

  Future<CartEntity> changeQuantity(String advertisementId, int quantity);
  Future<CartEntity> removeItem(String advertisementId);
}
