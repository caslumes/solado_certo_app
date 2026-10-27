import 'package:solado_certo_app/features/profile/domain/entities/consent.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

class GrantPrescriptionConsentUseCase {
  final ProfileRepositoryInterface profileRepository;

  GrantPrescriptionConsentUseCase(this.profileRepository);

  Future<ConsentEntity> execute() => profileRepository.grantConsent(
    ConsentPurposes.prescription,
    ConsentTermsVersions.prescription,
  );
}
