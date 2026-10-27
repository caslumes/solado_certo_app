import 'package:solado_certo_app/features/checkout/domain/entities/checkout.dart';

abstract class CheckoutRepositoryInterface {
  Future<CheckoutPlanEntity> preview(CheckoutSelection selection);

  Future<CheckoutResultEntity> checkout(
    CheckoutSelection selection,
    String idempotencyKey,
  );
}
