import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solado_certo_app/features/auth/domain/repositories/auth_repository.dart';

class SignOutUseCase {
  final AuthRepositoryInterface repository;
  final FlutterSecureStorage secureStorage;

  SignOutUseCase({required this.repository, required this.secureStorage});

  Future<void> execute() async {
    try {
      final refreshToken = await secureStorage.read(key: 'refreshToken');
      if (refreshToken != null) {
        await repository.signOut(refreshToken);
      }
    } finally {
      await secureStorage.deleteAll();
    }
  }
}
