import 'package:solado_certo_app/features/checkout/domain/entities/checkout.dart';
import 'package:solado_certo_app/features/checkout/domain/repositories/checkout_repository.dart';

class PreviewCheckoutUseCase {
  final CheckoutRepositoryInterface checkoutRepository;

  PreviewCheckoutUseCase(this.checkoutRepository);

  Future<CheckoutPlanEntity> execute(CheckoutSelection selection) =>
      checkoutRepository.preview(selection);
}

class CheckoutUseCase {
  final CheckoutRepositoryInterface checkoutRepository;

  CheckoutUseCase(this.checkoutRepository);

  Future<CheckoutResultEntity> execute(
    CheckoutSelection selection,
    String idempotencyKey,
  ) => checkoutRepository.checkout(selection, idempotencyKey);
}
