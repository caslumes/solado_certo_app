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
        if (statusCode == 404) return NotFoundFailure();
        if (statusCode == 409) return ConflictFailure();
        if (statusCode == 413) return FileTooLargeFailure();
        if (statusCode == 415) return UnsupportedFileTypeFailure();
        if (statusCode == 422) {
          return MissingFieldsFailure.fromBody(error.response?.data);
        }
        return ServerFailure(statusCode);
      default:
        return UnexpectedFailure(error);
    }
  }

  String get message;
}

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
      'Este anúncio foi alterado em outro lugar. A lista foi atualizada.';
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
