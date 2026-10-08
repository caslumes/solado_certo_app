import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/new_address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';

abstract class ProfileRepositoryInterface {
  Future<ProfileEntity> getProfile();
  Future<ProfileEntity> updateProfile(ProfileEntity profile);
  Future<List<AddressEntity>> getAddresses();
  Future<AddressEntity> addAddress(NewAddress address);
  Future<PodologicalProfileEntity> getPodologicalProfile();
}
