import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/new_address.dart';
import 'package:solado_certo_app/features/profile/domain/repositories/profile_repository.dart';

class AddAddressUseCase {
  final ProfileRepositoryInterface profileRepository;

  AddAddressUseCase(this.profileRepository);

  Future<AddressEntity> execute(NewAddress address) async {
    return await profileRepository.addAddress(address);
  }
}
