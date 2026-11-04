import 'package:solado_certo_app/features/auth/domain/repositories/auth_repository.dart';

class RequestPasswordResetUseCase {
  final AuthRepositoryInterface authRepository;

  RequestPasswordResetUseCase({required this.authRepository});

  Future<void> execute(String email) =>
      authRepository.requestPasswordReset(email);
}
