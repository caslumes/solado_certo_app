import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

class GrantCustomOrderConsentUseCase {
  final ProfileRepositoryInterface profileRepository;

  GrantCustomOrderConsentUseCase(this.profileRepository);

  Future<ConsentEntity> execute() => profileRepository.grantConsent(
    ConsentPurposes.customOrder,
    ConsentTermsVersions.customOrder,
  );
}
