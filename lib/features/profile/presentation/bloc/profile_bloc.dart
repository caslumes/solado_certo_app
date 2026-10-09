import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/profile/domain/entities/address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/pain_point.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile_update.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_addresses_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_pain_points_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/revoke_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/save_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/update_profile_use_case.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final GetAddressesUseCase _getAddressesUseCase;
  final GetPodologicalProfileUseCase _getPodologicalProfileUseCase;
  final SavePodologicalProfileUseCase _savePodologicalProfileUseCase;
  final GetPainPointsUseCase _getPainPointsUseCase;
  final HasPodologicalConsentUseCase _hasPodologicalConsentUseCase;
  final RevokePodologicalConsentUseCase _revokePodologicalConsentUseCase;

  ProfileBloc({
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required GetAddressesUseCase getAddressesUseCase,
    required GetPodologicalProfileUseCase getPodologicalProfileUseCase,
    required SavePodologicalProfileUseCase savePodologicalProfileUseCase,
    required GetPainPointsUseCase getPainPointsUseCase,
    required HasPodologicalConsentUseCase hasPodologicalConsentUseCase,
    required RevokePodologicalConsentUseCase revokePodologicalConsentUseCase,
  }) : _getProfileUseCase = getProfileUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       _getAddressesUseCase = getAddressesUseCase,
       _getPodologicalProfileUseCase = getPodologicalProfileUseCase,
       _savePodologicalProfileUseCase = savePodologicalProfileUseCase,
       _getPainPointsUseCase = getPainPointsUseCase,
       _hasPodologicalConsentUseCase = hasPodologicalConsentUseCase,
       _revokePodologicalConsentUseCase = revokePodologicalConsentUseCase,
       super(ProfileLoading()) {
    on<LoadProfileEvent>(_onLoad);
    on<SavePersonalDataEvent>(_onSavePersonalData);
    on<AddressesChangedEvent>(_onAddressesChanged);
    on<SavePodologicalProfileEvent>(_onSavePodologicalProfile);
    on<RevokePodologicalConsentEvent>(_onRevokePodologicalConsent);
  }

  Future<void> _onLoad(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      emit(
        ProfileLoaded(
          data: ProfileData(
            profile: await _getProfileUseCase.execute(),
            addresses: await _getAddressesUseCase.execute(),
            podologicalProfile: await _getPodologicalProfileUseCase.execute(),
            painPoints: await _getPainPointsUseCase.execute(),
            hasPodologicalConsent: await _hasPodologicalConsentUseCase
                .execute(),
          ),
        ),
      );
    } catch (e) {
      emit(ProfileLoadFailure(failure: Failure.from(e)));
    }
  }

  Future<void> _onSavePersonalData(
    SavePersonalDataEvent event,
    Emitter<ProfileState> emit,
  ) => _save(
    emit,
    ProfileNotice.personalDataSaved,
    (data) async {
      final profile = await _updateProfileUseCase.execute(
        data.profile.copyWith(name: event.name, phone: event.phone),
      );
      return data.copyWith(profile: profile);
    },
    mapFailure: (failure) =>
        failure is ConflictFailure ? PhoneAlreadyInUseFailure() : failure,
  );

  Future<void> _onAddressesChanged(
    AddressesChangedEvent event,
    Emitter<ProfileState> emit,
  ) => _save(emit, ProfileNotice.addressSaved, (data) async {
    return data.copyWith(addresses: await _getAddressesUseCase.execute());
  });

  Future<void> _onSavePodologicalProfile(
    SavePodologicalProfileEvent event,
    Emitter<ProfileState> emit,
  ) => _save(emit, ProfileNotice.podologicalProfileSaved, (data) async {
    return data.copyWith(
      podologicalProfile: await _savePodologicalProfileUseCase.execute(
        event.update,
      ),
      hasPodologicalConsent: true,
    );
  });

  Future<void> _onRevokePodologicalConsent(
    RevokePodologicalConsentEvent event,
    Emitter<ProfileState> emit,
  ) => _save(emit, ProfileNotice.podologicalConsentRevoked, (data) async {
    await _revokePodologicalConsentUseCase.execute();
    return data.copyWith(
      podologicalProfile: PodologicalProfileEntity(),
      hasPodologicalConsent: false,
    );
  });

  Future<void> _save(
    Emitter<ProfileState> emit,
    ProfileNotice notice,
    Future<ProfileData> Function(ProfileData data) action, {
    Failure Function(Failure failure)? mapFailure,
  }) async {
    final currentState = state;
    if (currentState is! ProfileLoaded || currentState.isSaving) return;

    final data = currentState.data;
    emit(ProfileLoaded(data: data, isSaving: true));
    try {
      emit(ProfileLoaded(data: await action(data), notice: notice));
    } catch (e) {
      final failure = Failure.from(e);
      emit(
        ProfileLoaded(
          data: data,
          failure: mapFailure?.call(failure) ?? failure,
        ),
      );
    }
  }
}

class ProfileEvent {}

class LoadProfileEvent extends ProfileEvent {}

class SavePersonalDataEvent extends ProfileEvent {
  final String name;
  final String phone;

  SavePersonalDataEvent({required this.name, required this.phone});
}

class AddressesChangedEvent extends ProfileEvent {}

class SavePodologicalProfileEvent extends ProfileEvent {
  final PodologicalProfileUpdate update;

  SavePodologicalProfileEvent({required this.update});
}

class RevokePodologicalConsentEvent extends ProfileEvent {}

enum ProfileNotice {
  personalDataSaved('Dados pessoais salvos.'),
  addressSaved('Endereço salvo.'),
  podologicalProfileSaved('Perfil podológico salvo.'),
  podologicalConsentRevoked(
    'Consentimento retirado. Seu perfil podológico foi excluído.',
  );

  const ProfileNotice(this.message);

  final String message;
}

class ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoadFailure extends ProfileState {
  final Failure failure;

  ProfileLoadFailure({required this.failure});
}

class ProfileLoaded extends ProfileState {
  final ProfileData data;
  final bool isSaving;
  final Failure? failure;
  final ProfileNotice? notice;

  ProfileLoaded({
    required this.data,
    this.isSaving = false,
    this.failure,
    this.notice,
  });
}

class ProfileData {
  final ProfileEntity profile;
  final List<AddressEntity> addresses;
  final PodologicalProfileEntity podologicalProfile;
  final List<PainPointEntity> painPoints;
  final bool hasPodologicalConsent;

  const ProfileData({
    required this.profile,
    required this.addresses,
    required this.podologicalProfile,
    required this.painPoints,
    required this.hasPodologicalConsent,
  });

  ProfileData copyWith({
    ProfileEntity? profile,
    List<AddressEntity>? addresses,
    PodologicalProfileEntity? podologicalProfile,
    bool? hasPodologicalConsent,
  }) => ProfileData(
    profile: profile ?? this.profile,
    addresses: addresses ?? this.addresses,
    podologicalProfile: podologicalProfile ?? this.podologicalProfile,
    painPoints: painPoints,
    hasPodologicalConsent: hasPodologicalConsent ?? this.hasPodologicalConsent,
  );
}
