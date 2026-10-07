import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

class ApiProfileRepository implements ProfileRepositoryInterface {
  final ClientInterface client;

  ApiProfileRepository(this.client);

  @override
  Future<ProfileEntity> getProfile() {
    return client.get('/me/profile').then((response) => ProfileEntity.fromJson(response));
  }

  @override
  Future<List<AddressEntity>> getAddresses() {
    return client.get('/me/addresses').then((response) => (response as List).map((e) => AddressEntity.fromJson(e)).toList());
  }

  @override
  Future<PodologicalProfileEntity> getPodologicalProfile() {
    return client.get('/me/podological-profile').then((response) => PodologicalProfileEntity.fromJson(response));
  }
}
