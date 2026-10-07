import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';

abstract class ProfileRepositoryInterface {
  Future<ProfileEntity> getProfile();
  Future<List<AddressEntity>> getAddresses();
  Future<PodologicalProfileEntity> getPodologicalProfile();
}
