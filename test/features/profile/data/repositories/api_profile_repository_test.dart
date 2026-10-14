import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/profile/data/repositories/api_profile_repository.dart';
import 'package:solado_certo_app/features/profile/domain/enum/user_role.dart';

class MockClient extends Mock implements ClientInterface {}

void main() {
  late MockClient client;
  late ApiProfileRepository repository;

  const photo = UploadFile(bytes: [1, 2, 3], filename: 'foto.jpg');
  const profileJson = {
    'name': 'Maria',
    'email': 'maria@example.com',
    'phone': '19999999999',
    'avatar_url': '/files/public/avatars/a.jpg',
  };
  const rolesJson = {
    'roles': ['buyer', 'seller'],
  };

  setUpAll(() => registerFallbackValue(photo));

  setUp(() {
    client = MockClient();
    repository = ApiProfileRepository(client);
  });

  test('changeAvatar sends the photo as the avatar field with PUT', () async {
    when(
      () => client.upload(
        any(),
        method: any(named: 'method'),
        field: any(named: 'field'),
        file: any(named: 'file'),
      ),
    ).thenAnswer((_) async => profileJson);

    final profile = await repository.changeAvatar(photo);

    expect(profile.avatarUrl, '/files/public/avatars/a.jpg');
    verify(
      () => client.upload(
        '/me/avatar',
        method: 'PUT',
        field: 'avatar',
        file: photo,
      ),
    ).called(1);
  });

  test('removeAvatar returns the updated profile', () async {
    when(
      () => client.delete('/me/avatar'),
    ).thenAnswer((_) async => {...profileJson, 'avatar_url': ''});

    expect((await repository.removeAvatar()).avatarUrl, '');
  });

  test('getRoles reads the role list', () async {
    when(() => client.get('/me/roles')).thenAnswer((_) async => rolesJson);

    expect(await repository.getRoles(), [UserRole.buyer, UserRole.seller]);
  });

  test('becomeSeller posts and returns the new roles', () async {
    when(
      () => client.post('/me/roles/seller'),
    ).thenAnswer((_) async => rolesJson);

    expect(await repository.becomeSeller(), contains(UserRole.seller));
  });
}
