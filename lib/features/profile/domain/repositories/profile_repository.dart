import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';
import 'package:solado_certo_app/features/profile/domain/entities/new_address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/pain_point.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile_update.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';
import 'package:solado_certo_app/features/profile/domain/enum/user_role.dart';

abstract class ProfileRepositoryInterface {
  Future<ProfileEntity> getProfile();
  Future<ProfileEntity> updateProfile(ProfileEntity profile);
  Future<ProfileEntity> changeAvatar(UploadFile photo);
  Future<ProfileEntity> removeAvatar();
  Future<List<UserRole>> getRoles();
  Future<List<UserRole>> becomeSeller();
  Future<List<AddressEntity>> getAddresses();
  Future<AddressEntity> addAddress(NewAddress address);
  Future<PodologicalProfileEntity> getPodologicalProfile();
  Future<PodologicalProfileEntity> savePodologicalProfile(
    PodologicalProfileUpdate update,
  );
  Future<List<PainPointEntity>> getPainPoints();
  Future<List<ConsentEntity>> getConsents();
  Future<ConsentEntity> grantConsent(String purpose, String termsVersion);
  Future<void> revokeConsent(String purpose);
}
