import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

class GetPodologicalProfileUseCase {
    final ProfileRepositoryInterface _profileRepository;
  
    GetPodologicalProfileUseCase(this._profileRepository);
  
    Future<PodologicalProfileEntity> execute() {
      return _profileRepository.getPodologicalProfile();
    }
}