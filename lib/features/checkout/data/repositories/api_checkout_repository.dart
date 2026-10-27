import 'package:dio/dio.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/cart/data/models/cart_model.dart';
import 'package:solado_certo_app/features/checkout/data/models/checkout_model.dart';
import 'package:solado_certo_app/features/checkout/domain/entities/checkout.dart';
import 'package:solado_certo_app/features/checkout/domain/repositories/checkout_repository.dart';

class ApiCheckoutRepository implements CheckoutRepositoryInterface {
  final ClientInterface client;

  ApiCheckoutRepository(this.client);

  @override
  Future<CheckoutPlanEntity> preview(CheckoutSelection selection) async {
    final response = await _withConflicts(
      () => client.post(
        '/checkout/preview',
        data: checkoutSelectionToJson(selection),
      ),
    );
    return checkoutPlanFromJson(response as Map<String, dynamic>);
  }

  @override
  Future<CheckoutResultEntity> checkout(
    CheckoutSelection selection,
    String idempotencyKey,
  ) async {
    final response = await _withConflicts(
      () => client.post(
        '/checkout',
        data: checkoutSelectionToJson(selection),
        headers: {'Idempotency-Key': idempotencyKey},
      ),
    );
    return checkoutResultFromJson(response as Map<String, dynamic>);
  }

  static Future<dynamic> _withConflicts(
    Future<dynamic> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (e) {
      final body = e.response?.data;
      if (e.response?.statusCode == 409 &&
          body is Map &&
          body['cart'] is Map<String, dynamic>) {
        throw CheckoutConflict(
          failure: Failure.from(e),
          cart: cartFromJson(body['cart'] as Map<String, dynamic>),
        );
      }
      rethrow;
    }
  }
}
