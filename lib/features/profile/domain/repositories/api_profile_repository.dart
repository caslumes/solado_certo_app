import 'package:solado_certo_app/common/network/client.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

class ApiProfileRepository implements ProfileRepositoryInterface {
  final ClientInterface client;

  ApiProfileRepository(this.client);

  @override
  Future<ProfileEntity> getProfile() {
    return client.get('/me/profile').then((response) => ProfileEntity.fromJson(response));
  }
}
