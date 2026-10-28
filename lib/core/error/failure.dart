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
        if (statusCode == 403) return _forbidden(error.response?.data);
        if (statusCode == 404) return _notFound(error.response?.data);
        if (statusCode == 409) return _conflict(error.response?.data);
        if (statusCode == 413) return FileTooLargeFailure();
        if (statusCode == 415) return _unsupported(error.response?.data);
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

Failure _forbidden(Object? body) => switch (_errorCode(body)) {
  final String code when code.startsWith('sending a prescription requires') =>
    PrescriptionConsentRequiredFailure(),
  final String code when code.startsWith('a custom order request requires') =>
    CustomOrderConsentRequiredFailure(),
  _ => ForbiddenFailure(),
};

Failure _unsupported(Object? body) => switch (_errorCode(body)) {
  final String code when code.startsWith('the prescription must be') =>
    PrescriptionFileTypeFailure(),
  final String code when code.startsWith('the photo must be') =>
    FootPhotoFileTypeFailure(),
  final String code when code.startsWith('the report must be') =>
    FittingReportFileTypeFailure(),
  _ => UnsupportedFileTypeFailure(),
};

Failure _notFound(Object? body) => switch (_errorCode(body)) {
  'address not found' => AddressNotFoundFailure(),
  _ => NotFoundFailure(),
};

Failure _conflict(Object? body) => switch (_errorCode(body)) {
  'out of stock' => OutOfStockFailure.fromBody(body),
  'cannot buy your own advertisement' => OwnAdvertisementFailure(),
  'prices changed' => PricesChangedFailure(),
  'cart changed' => CartChangedFailure(),
  'order payment window expired' => PaymentExpiredFailure(),
  'another payment of this order is in progress' => PaymentInProgressFailure(),
  'tax id already registered' => TaxIdInUseFailure(),
  'tracking code already registered' => TrackingCodeInUseFailure(),
  'item already reviewed' => AlreadyReviewedFailure(),
  'only a delivered order can be reviewed' => ReviewNotAllowedFailure(),
  'prescription required' => PrescriptionRequiredFailure.fromBody(body),
  'this advertisement does not take custom orders' =>
    CustomMadeNotAllowedFailure(),
  final String code when code.startsWith('invalid status transition') =>
    OrderStatusChangedFailure(),
  _ => ConflictFailure(),
};

Failure _unprocessable(Object? body) => switch (_errorCode(body)) {
  'shipping option required' => ShippingRequiredFailure.fromBody(body),
  'cart is empty' => EmptyCartFailure(),
  'tax id required' => TaxIdRequiredFailure(),
  final String code when code.startsWith('unreadable document') =>
    UnreadableDocumentFailure.fromCode(code),
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

final class AdOutdatedFailure extends Failure {
  @override
  String get message =>
      'Este anúncio foi alterado em outro lugar. Confira e tente de novo.';
}

final class TooManyPhotosFailure extends Failure {
  @override
  String get message => 'Um anúncio pode ter no máximo 6 fotos.';
}

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

final class ProductUnavailableFailure extends Failure {
  @override
  String get message => 'Este produto não está mais disponível.';
}

final class OwnAdvertisementFailure extends Failure {
  @override
  String get message => 'Você não pode comprar um anúncio seu.';
}

final class PricesChangedFailure extends Failure {
  @override
  String get message => 'Alguns preços mudaram. Confira o carrinho.';
}

final class CartChangedFailure extends Failure {
  @override
  String get message => 'Seu carrinho mudou. Confira os itens.';
}

final class OrderStatusChangedFailure extends Failure {
  @override
  String get message =>
      'A situação deste pedido mudou. Confira e tente de novo.';
}

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

final class AddressNotFoundFailure extends Failure {
  @override
  String get message => 'Este endereço não está mais disponível.';
}

final class PaymentExpiredFailure extends Failure {
  @override
  String get message => 'O prazo para pagar este pedido terminou.';
}

final class PaymentInProgressFailure extends Failure {
  @override
  String get message => 'Já há um pagamento deste pedido em andamento.';
}

final class TaxIdInUseFailure extends Failure {
  @override
  String get message => 'Este CPF já está cadastrado em outra conta.';
}

final class TaxIdRequiredFailure extends Failure {
  @override
  String get message => 'Informe seu CPF para pagar.';
}

final class InvalidTrackingCodeFailure extends Failure {
  @override
  String get message => 'Código de rastreio inválido para esta transportadora.';
}

final class TrackingCodeInUseFailure extends Failure {
  @override
  String get message => 'Este código de rastreio já foi usado em outro envio.';
}

final class AlreadyReviewedFailure extends Failure {
  @override
  String get message => 'Você já avaliou este item.';
}

final class ReviewNotAllowedFailure extends Failure {
  @override
  String get message =>
      'Só é possível avaliar depois de confirmar o recebimento.';
}

final class GatewayUnavailableFailure extends Failure {
  @override
  String get message =>
      'O serviço de pagamento está indisponível no momento. Tente novamente.';
}

final class PrescriptionConsentRequiredFailure extends Failure {
  @override
  String get message =>
      'Para enviar a receita, aceite os termos de tratamento de dados de saúde.';
}

final class PrescriptionFileTypeFailure extends Failure {
  @override
  String get message => 'Envie a receita em PDF, JPEG ou PNG.';
}

final class PrescriptionRequiredFailure extends Failure {
  const PrescriptionRequiredFailure(this.itemIds);

  factory PrescriptionRequiredFailure.fromBody(Object? body) {
    final ids = body is Map ? body['item_ids'] : null;
    return PrescriptionRequiredFailure([
      if (ids is List)
        for (final id in ids)
          if (id is String) id,
    ]);
  }

  final List<String> itemIds;

  @override
  String get message =>
      'Envie uma receita válida dos itens que exigem prescrição.';
}

final class CustomOrderConsentRequiredFailure extends Failure {
  @override
  String get message =>
      'Para pedir sob medida, aceite os termos de tratamento das suas medidas.';
}

final class FootPhotoFileTypeFailure extends Failure {
  @override
  String get message => 'Envie a foto do pé em JPEG ou PNG.';
}

final class FittingReportFileTypeFailure extends Failure {
  @override
  String get message => 'Envie o laudo em PDF, JPEG ou PNG.';
}

final class CustomMadeNotAllowedFailure extends Failure {
  @override
  String get message => 'Este anúncio não aceita pedidos sob medida.';
}

final class UnreadableDocumentFailure extends Failure {
  const UnreadableDocumentFailure(this.reason);

  factory UnreadableDocumentFailure.fromCode(String code) {
    final reason = code.contains(':') ? code.split(':').last.trim() : '';
    return UnreadableDocumentFailure(switch (reason) {
      'the PDF is incomplete' => 'o PDF está incompleto.',
      'the image could not be opened' => 'a imagem não pôde ser aberta.',
      'the image is damaged' => 'a imagem está danificada.',
      final r when r.startsWith('the image must be at least') =>
        'a imagem deve ter pelo menos 300 × 300 pixels.',
      final r when r.startsWith('the image must have at most') =>
        'a imagem deve ter no máximo 40 megapixels.',
      _ => null,
    });
  }

  final String? reason;

  @override
  String get message => switch (reason) {
    final reason? => 'Não foi possível ler o arquivo: $reason',
    null => 'Não foi possível ler o arquivo. Envie outro.',
  };
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
