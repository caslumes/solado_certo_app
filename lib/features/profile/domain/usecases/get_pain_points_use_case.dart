import 'package:solado_certo_app/features/profile/domain/entities/pain_point.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

class GetPainPointsUseCase {
  final ProfileRepositoryInterface profileRepository;

  GetPainPointsUseCase(this.profileRepository);

  Future<List<PainPointEntity>> execute() async {
    return await profileRepository.getPainPoints();
  }
}
