import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/storage/storage_keys.dart';
import 'package:solado_certo_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_in_use_case.dart';

import '../../../../support/fake_secure_storage.dart';
import '../../../../support/mocks.dart';

void main() {
  late MockAuthRepository repository;
  late FakeSecureStorage storage;
  late SignInUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    storage = FakeSecureStorage();
    useCase = SignInUseCase(repository, storage);
  });

  test('stores both tokens under the shared storage keys', () async {
    when(() => repository.signIn('maria@example.com', 'secret123')).thenAnswer(
      (_) async => AuthTokens(accessToken: 'access', refreshToken: 'refresh'),
    );

    await useCase.execute('maria@example.com', 'secret123');

    expect(storage.values, {
      StorageKeys.accessToken: 'access',
      StorageKeys.refreshToken: 'refresh',
    });
  });

  test('throws and stores nothing when the access token is missing', () async {
    when(() => repository.signIn(any(), any())).thenAnswer(
      (_) async => AuthTokens(accessToken: null, refreshToken: 'refresh'),
    );

    await expectLater(
      useCase.execute('maria@example.com', 'secret123'),
      throwsException,
    );
    expect(storage.values, isEmpty);
  });

  test('propagates repository errors without storing tokens', () async {
    when(() => repository.signIn(any(), any())).thenThrow(Exception('boom'));

    await expectLater(
      useCase.execute('maria@example.com', 'secret123'),
      throwsException,
    );
    expect(storage.values, isEmpty);
  });
}
