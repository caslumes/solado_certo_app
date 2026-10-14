import 'package:solado_certo_app/features/checkout/domain/entities/checkout.dart';

abstract class CheckoutRepositoryInterface {
  /// The orders [selection] would create; nothing is saved.
  Future<CheckoutPlanEntity> preview(CheckoutSelection selection);

  /// Creates the orders. Repeating [idempotencyKey] returns the same orders.
  Future<CheckoutResultEntity> checkout(
    CheckoutSelection selection,
    String idempotencyKey,
  );
}
