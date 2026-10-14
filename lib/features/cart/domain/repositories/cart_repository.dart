import 'package:solado_certo_app/features/cart/domain/entities/cart.dart';

abstract class CartRepositoryInterface {
  Future<CartEntity> getCart();

  /// Adds [quantity] to what is already in the cart.
  Future<CartEntity> addItem(String advertisementId, int quantity);

  /// Sets the item's quantity; 0 removes it.
  Future<CartEntity> changeQuantity(String advertisementId, int quantity);
  Future<CartEntity> removeItem(String advertisementId);
}
