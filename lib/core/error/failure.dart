import 'package:dio/dio.dart';

sealed class Failure {
  const Failure();

  factory Failure.from(Object error) {
    if (error is Failure) return error;
    if (error is! DioException) return UnexpectedFailure(error);

    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure();
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) return UnauthorizedFailure();
        if (statusCode == 400) return InvalidInputFailure();
        if (statusCode == 403) return ForbiddenFailure();
        if (statusCode == 404) return _notFound(error.response?.data);
        if (statusCode == 409) return _conflict(error.response?.data);
        if (statusCode == 413) return FileTooLargeFailure();
        if (statusCode == 415) return UnsupportedFileTypeFailure();
        if (statusCode == 422) return _unprocessable(error.response?.data);
        if (statusCode == 503 &&
            _errorCode(error.response?.data) == 'payment gateway unavailable') {
          return GatewayUnavailableFailure();
        }
        return ServerFailure(statusCode);
      default:
        return UnexpectedFailure(error);
    }
  }

  String get message;
}

Object? _errorCode(Object? body) => body is Map ? body['error'] : null;

Failure _notFound(Object? body) => switch (_errorCode(body)) {
  'address not found' => AddressNotFoundFailure(),
  _ => NotFoundFailure(),
};

/// Some 409s carry an `error` code that says which conflict happened.
Failure _conflict(Object? body) => switch (_errorCode(body)) {
  'out of stock' => OutOfStockFailure.fromBody(body),
  'cannot buy your own advertisement' => OwnAdvertisementFailure(),
  'prices changed' => PricesChangedFailure(),
  'cart changed' => CartChangedFailure(),
  'order payment window expired' => PaymentExpiredFailure(),
  'another payment of this order is in progress' => PaymentInProgressFailure(),
  'tax id already registered' => TaxIdInUseFailure(),
  'tracking code already registered' => TrackingCodeInUseFailure(),
  // Payments add why the transition was refused after a colon.
  final String code when code.startsWith('invalid status transition') =>
    OrderStatusChangedFailure(),
  _ => ConflictFailure(),
};

Failure _unprocessable(Object? body) => switch (_errorCode(body)) {
  'shipping option required' => ShippingRequiredFailure.fromBody(body),
  'cart is empty' => EmptyCartFailure(),
  'tax id required' => TaxIdRequiredFailure(),
  // The backend adds which format was expected after a colon.
  final String code when code.startsWith('invalid tracking code') =>
    InvalidTrackingCodeFailure(),
  _ => MissingFieldsFailure.fromBody(body),
};

final class NetworkFailure extends Failure {
  @override
  String get message =>
      'Não foi possível conectar ao servidor. Verifique sua conexão.';
}

final class UnauthorizedFailure extends Failure {
  @override
  String get message => 'Sua sessão expirou. Entre novamente.';
}

final class InvalidCredentialsFailure extends Failure {
  @override
  String get message => 'E-mail ou senha inválidos.';
}

final class InvalidInputFailure extends Failure {
  @override
  String get message => 'Verifique os dados informados.';
}

final class ForbiddenFailure extends Failure {
  @override
  String get message => 'Você não tem permissão para fazer isso.';
}

/// The backend refused to publish because required fields are empty.
/// [fields] holds their JSON names, in form order.
final class MissingFieldsFailure extends Failure {
  const MissingFieldsFailure(this.fields);

  factory MissingFieldsFailure.fromBody(Object? body) {
    final fields = body is Map ? body['fields'] : null;
    return MissingFieldsFailure([
      if (fields is List)
        for (final field in fields)
          if (field is String) field,
    ]);
  }

  final List<String> fields;

  @override
  String get message => 'Preencha os campos obrigatórios antes de publicar.';
}

final class NotFoundFailure extends Failure {
  @override
  String get message => 'O conteúdo procurado não foi encontrado.';
}

final class ConflictFailure extends Failure {
  @override
  String get message => 'Esses dados já estão em uso.';
}

final class AccountAlreadyExistsFailure extends Failure {
  @override
  String get message =>
      'E-mail ou telefone já cadastrado. Faça login ou recupere sua senha.';
}

final class PhoneAlreadyInUseFailure extends Failure {
  @override
  String get message => 'Este telefone já está cadastrado em outra conta.';
}

final class FileTooLargeFailure extends Failure {
  @override
  String get message => 'O arquivo deve ter no máximo 5 MB.';
}

final class UnsupportedFileTypeFailure extends Failure {
  @override
  String get message => 'Envie uma imagem JPEG, PNG ou WebP.';
}

/// A 409 or 404 on an ad action: it changed or was removed elsewhere.
final class AdOutdatedFailure extends Failure {
  @override
  String get message =>
      'Este anúncio foi alterado em outro lugar. Confira e tente de novo.';
}

/// A 409 when adding a photo: the ad already has the maximum.
final class TooManyPhotosFailure extends Failure {
  @override
  String get message => 'Um anúncio pode ter no máximo 6 fotos.';
}

/// A 409 when the buyer asks for more units than the ads have.
final class OutOfStockFailure extends Failure {
  const OutOfStockFailure(this.items);

  factory OutOfStockFailure.fromBody(Object? body) {
    final items = body is Map ? body['items'] : null;
    return OutOfStockFailure([
      if (items is List)
        for (final item in items)
          if (item is Map)
            StockShortage(
              advertisementId: item['advertisement_id'] as String,
              requested: item['requested'] as int,
              available: item['available'] as int,
            ),
    ]);
  }

  final List<StockShortage> items;

  @override
  String get message {
    if (items.length == 1) {
      final available = items.single.available;
      return switch (available) {
        0 => 'Este produto está esgotado.',
        1 => 'Só há 1 unidade disponível.',
        _ => 'Só há $available unidades disponíveis.',
      };
    }
    return 'Alguns produtos não têm estoque suficiente.';
  }
}

class StockShortage {
  final String advertisementId;
  final int requested;
  final int available;

  const StockShortage({
    required this.advertisementId,
    required this.requested,
    required this.available,
  });
}

/// A 404 on a cart item: the ad was removed or the item left the cart.
final class ProductUnavailableFailure extends Failure {
  @override
  String get message => 'Este produto não está mais disponível.';
}

final class OwnAdvertisementFailure extends Failure {
  @override
  String get message => 'Você não pode comprar um anúncio seu.';
}

/// A 409 at checkout: prices changed since the items were added. The cart
/// now has the current prices, and confirming again goes through.
final class PricesChangedFailure extends Failure {
  @override
  String get message => 'Alguns preços mudaram. Confira o carrinho.';
}

/// A 409 at checkout: the cart was changed elsewhere during checkout.
final class CartChangedFailure extends Failure {
  @override
  String get message => 'Seu carrinho mudou. Confira os itens.';
}

/// A 409 on an order action: its status changed and the action no longer
/// applies, e.g. cancelling an order that was already paid.
final class OrderStatusChangedFailure extends Failure {
  @override
  String get message =>
      'A situação deste pedido mudou. Confira e tente de novo.';
}

/// A 422 at checkout: these items have no valid shipping option chosen.
final class ShippingRequiredFailure extends Failure {
  const ShippingRequiredFailure(this.advertisementIds);

  factory ShippingRequiredFailure.fromBody(Object? body) {
    final ids = body is Map ? body['advertisement_ids'] : null;
    return ShippingRequiredFailure([
      if (ids is List)
        for (final id in ids)
          if (id is String) id,
    ]);
  }

  final List<String> advertisementIds;

  @override
  String get message => 'Escolha o frete de todos os itens.';
}

final class EmptyCartFailure extends Failure {
  @override
  String get message => 'Seu carrinho está vazio.';
}

/// A 404 at checkout: the chosen address was deleted.
final class AddressNotFoundFailure extends Failure {
  @override
  String get message => 'Este endereço não está mais disponível.';
}

/// A 409 on a payment: the order's payment window ended and it was or will
/// be cancelled.
final class PaymentExpiredFailure extends Failure {
  @override
  String get message => 'O prazo para pagar este pedido terminou.';
}

/// A 409 on a payment: another attempt for this order is being created.
final class PaymentInProgressFailure extends Failure {
  @override
  String get message => 'Já há um pagamento deste pedido em andamento.';
}

final class TaxIdInUseFailure extends Failure {
  @override
  String get message => 'Este CPF já está cadastrado em outra conta.';
}

/// A 422 on a payment: the gateway needs the buyer's CPF.
final class TaxIdRequiredFailure extends Failure {
  @override
  String get message => 'Informe seu CPF para pagar.';
}

/// A 422 on shipping: the code doesn't have the carrier's format (UC-009).
final class InvalidTrackingCodeFailure extends Failure {
  @override
  String get message => 'Código de rastreio inválido para esta transportadora.';
}

/// A 409 on shipping: another shipment already has this code.
final class TrackingCodeInUseFailure extends Failure {
  @override
  String get message => 'Este código de rastreio já foi usado em outro envio.';
}

/// A 503 on a payment: the gateway didn't answer (RNF-023).
final class GatewayUnavailableFailure extends Failure {
  @override
  String get message =>
      'O serviço de pagamento está indisponível no momento. Tente novamente.';
}

final class ServerFailure extends Failure {
  ServerFailure(this.statusCode);

  final int? statusCode;

  @override
  String get message => 'Erro no servidor. Tente novamente mais tarde.';
}

final class UnexpectedFailure extends Failure {
  UnexpectedFailure(this.error);

  final Object error;

  @override
  String get message => 'Ocorreu um erro inesperado. Tente novamente.';
}
