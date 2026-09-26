import 'package:solado_certo_app/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepositoryInterface authRepository;

  SignUpUseCase({required this.authRepository});

  Future<void> execute(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    await authRepository.signUp(name, email, phone, password);
  }
}
