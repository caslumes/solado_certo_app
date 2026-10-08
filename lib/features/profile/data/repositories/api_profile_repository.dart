import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/profile/data/models/address_model.dart';
import 'package:solado_certo_app/features/profile/data/models/podological_profile_model.dart';
import 'package:solado_certo_app/features/profile/data/models/profile_model.dart';
import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/new_address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

class ApiProfileRepository implements ProfileRepositoryInterface {
  final ClientInterface client;

  ApiProfileRepository(this.client);

  @override
  Future<ProfileEntity> getProfile() {
    return client
        .get('/me/profile')
        .then((response) => ProfileModel.fromJson(response).toEntity());
  }

  @override
  Future<ProfileEntity> updateProfile(ProfileEntity profile) {
    return client
        .patch('/me/profile', data: profileToJson(profile))
        .then((response) => ProfileModel.fromJson(response).toEntity());
  }

  @override
  Future<List<AddressEntity>> getAddresses() {
    return client
        .get('/me/addresses')
        .then(
          (response) => (response as List)
              .map((e) => AddressModel.fromJson(e).toEntity())
              .toList(),
        );
  }

  @override
  Future<AddressEntity> addAddress(NewAddress address) {
    return client
        .post('/me/addresses', data: newAddressToJson(address))
        .then((response) => AddressModel.fromJson(response).toEntity());
  }

  @override
  Future<PodologicalProfileEntity> getPodologicalProfile() {
    return client
        .get('/me/podological-profile')
        .then(
          (response) => PodologicalProfileModel.fromJson(response).toEntity(),
        );
  }
}
