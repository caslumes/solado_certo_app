import 'package:solado_certo_app/features/auth/domain/dtos/auth_tokens.dart';

abstract class AuthRepositoryInterface {
  Future<AuthTokens?> signIn(String email, String password);
  Future<void> signOut(String refreshToken);
}
