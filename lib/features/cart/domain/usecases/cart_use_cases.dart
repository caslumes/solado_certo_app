import 'package:solado_certo_app/features/cart/domain/entities/cart.dart';
import 'package:solado_certo_app/features/cart/domain/repositories/cart_repository.dart';

class GetCartUseCase {
  final CartRepositoryInterface cartRepository;

  GetCartUseCase(this.cartRepository);

  Future<CartEntity> execute() => cartRepository.getCart();
}

class AddToCartUseCase {
  final CartRepositoryInterface cartRepository;

  AddToCartUseCase(this.cartRepository);

  Future<CartEntity> execute(String advertisementId, int quantity) =>
      cartRepository.addItem(advertisementId, quantity);
}

class ChangeCartItemQuantityUseCase {
  final CartRepositoryInterface cartRepository;

  ChangeCartItemQuantityUseCase(this.cartRepository);

  Future<CartEntity> execute(String advertisementId, int quantity) =>
      cartRepository.changeQuantity(advertisementId, quantity);
}

class RemoveCartItemUseCase {
  final CartRepositoryInterface cartRepository;

  RemoveCartItemUseCase(this.cartRepository);

  Future<CartEntity> execute(String advertisementId) =>
      cartRepository.removeItem(advertisementId);
}
