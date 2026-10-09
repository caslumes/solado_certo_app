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
        if (statusCode == 409) return ConflictFailure();
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
