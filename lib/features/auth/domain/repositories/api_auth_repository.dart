import 'package:solado_certo_app/common/network/client.dart';
import 'package:solado_certo_app/features/auth/domain/dtos/auth_tokens.dart';
import 'package:solado_certo_app/features/auth/domain/repositories/auth_repository.dart';

class ApiAuthRepository implements AuthRepositoryInterface {
  ApiAuthRepository(this.client);

  final ClientInterface client;

  @override
  Future<void> signUp(
    String name,
    String email,
    String phone,
    String password,
  ) {
    return client
        .post(
          '/auth/register',
          data: {
            'name': name,
            'email': email,
            'phone': phone,
            'password': password,
          },
        )
        .then((response) => response);
  }

  @override
  Future<AuthTokens?> signIn(String email, String password) {
    return client
        .post('/auth/login', data: {'email': email, 'password': password})
        .then((response) => AuthTokens.fromJson(response));
  }

  @override
  Future<void> signOut(String refreshToken) {
    return client
        .post('/auth/logout', data: {'refreshToken': refreshToken})
        .then((response) => response);
  }
}
