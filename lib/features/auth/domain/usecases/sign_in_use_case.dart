import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solado_certo_app/features/auth/domain/repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepositoryInterface authRepository;
  final FlutterSecureStorage localStorage;

  SignInUseCase(this.authRepository, this.localStorage);

  Future<void> execute(String email, String password) async {
    final response = await authRepository.signIn(email, password);

    if (response == null) {
      throw Exception('Falha na autenticação');
    }

    final accessToken = response.accessToken;
    final refreshToken = response.refreshToken;
    if (accessToken == null) {
      throw Exception('Falha na autenticação');
    }

    if (refreshToken != null) {
      await localStorage.write(key: 'refresh_token', value: refreshToken);
    }
    await localStorage.write(key: 'access_token', value: accessToken);
  }
}
