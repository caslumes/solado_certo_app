import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

class ChangeAvatarUseCase {
  final ProfileRepositoryInterface profileRepository;

  ChangeAvatarUseCase(this.profileRepository);

  Future<ProfileEntity> execute(UploadFile photo) async {
    return await profileRepository.changeAvatar(photo);
  }
}
