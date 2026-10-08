import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/features/profile/data/models/address_model.dart';
import 'package:solado_certo_app/features/profile/data/models/consent_model.dart';
import 'package:solado_certo_app/features/profile/data/models/pain_point_model.dart';
import 'package:solado_certo_app/features/profile/data/models/podological_profile_model.dart';
import 'package:solado_certo_app/features/profile/data/models/profile_model.dart';
import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';
import 'package:solado_certo_app/features/profile/domain/entities/pain_point.dart';
import 'package:solado_certo_app/features/profile/domain/entities/new_address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile_update.dart';
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

  @override
  Future<PodologicalProfileEntity> savePodologicalProfile(
    PodologicalProfileUpdate update,
  ) {
    return client
        .put(
          '/me/podological-profile',
          data: podologicalProfileUpdateToJson(update),
        )
        .then(
          (response) => PodologicalProfileModel.fromJson(response).toEntity(),
        );
  }

  @override
  Future<List<PainPointEntity>> getPainPoints() {
    return client
        .get('/me/pain-points')
        .then(
          (response) => (response as List)
              .map((e) => PainPointModel.fromJson(e).toEntity())
              .toList(),
        );
  }

  @override
  Future<List<ConsentEntity>> getConsents() {
    return client
        .get('/me/consents')
        .then(
          (response) => (response as List)
              .map((e) => ConsentModel.fromJson(e).toEntity())
              .toList(),
        );
  }

  @override
  Future<ConsentEntity> grantConsent(String purpose, String termsVersion) {
    return client
        .post(
          '/me/consents',
          data: {'purpose': purpose, 'terms_version': termsVersion},
        )
        .then((response) => ConsentModel.fromJson(response).toEntity());
  }
}
