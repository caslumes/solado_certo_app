import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/auth/data/repositories/api_auth_repository.dart';

class MockClient extends Mock implements ClientInterface {}

void main() {
  late MockClient client;
  late ApiAuthRepository repository;

  setUp(() {
    client = MockClient();
    repository = ApiAuthRepository(client);
    when(
      () => client.post(any(), data: any(named: 'data')),
    ).thenAnswer((_) async => <String, dynamic>{});
  });

  test('requests a reset code with the e-mail', () async {
    await repository.requestPasswordReset('maria@example.com');

    verify(
      () => client.post(
        '/auth/password/forgot',
        data: {'email': 'maria@example.com'},
      ),
    ).called(1);
  });

  test('resets the password with the backend field names', () async {
    await repository.resetPassword('maria@example.com', '123456', 'new-secret');

    verify(
      () => client.post(
        '/auth/password/reset',
        data: {
          'email': 'maria@example.com',
          'code': '123456',
          'new_password': 'new-secret',
        },
      ),
    ).called(1);
  });
}
