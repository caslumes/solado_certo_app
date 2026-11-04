import 'package:solado_certo_app/features/auth/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepositoryInterface authRepository;

  ResetPasswordUseCase({required this.authRepository});

  Future<void> execute(String email, String code, String newPassword) =>
      authRepository.resetPassword(email, code, newPassword);
}
