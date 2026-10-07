import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/storage/storage_keys.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_out_use_case.dart';

import '../../../../support/fake_secure_storage.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockAuthRepository repository;
  late FakeSecureStorage storage;
  late SignOutUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    storage = FakeSecureStorage({
      StorageKeys.accessToken: 'access',
      StorageKeys.refreshToken: 'refresh',
    });
    useCase = SignOutUseCase(repository: repository, secureStorage: storage);
  });

  test('revokes the stored refresh token and clears local tokens', () async {
    when(() => repository.signOut(any())).thenAnswer((_) async {});

    await useCase.execute();

    verify(() => repository.signOut('refresh')).called(1);
    expect(storage.values, isEmpty);
  });

  test('clears local tokens even when revocation fails', () async {
    when(() => repository.signOut(any())).thenThrow(Exception('offline'));

    await expectLater(useCase.execute(), throwsException);
    expect(storage.values, isEmpty);
  });

  test('skips the server call when there is no refresh token', () async {
    storage.values.remove(StorageKeys.refreshToken);

    await useCase.execute();

    verifyNever(() => repository.signOut(any()));
    expect(storage.values, isEmpty);
  });
}
