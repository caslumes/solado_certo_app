import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filter_options.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_catalog_filter_options_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/entities/ad_draft.dart';
import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_form_step.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/ad_images_use_cases.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/change_ad_status_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/get_ad_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/save_ad_use_case.dart';

class AdFormBloc extends Bloc<AdFormEvent, AdFormState> {
  final String? _adId;
  final GetCatalogFilterOptionsUseCase _getOptionsUseCase;
  final GetAdUseCase _getAdUseCase;
  final SaveAdUseCase _saveAdUseCase;
  final ChangeAdStatusUseCase _changeAdStatusUseCase;
  final AddAdImageUseCase _addImageUseCase;
  final RemoveAdImageUseCase _removeImageUseCase;
  final ReorderAdImagesUseCase _reorderImagesUseCase;

  AdFormBloc({
    String? adId,
    required GetCatalogFilterOptionsUseCase getOptionsUseCase,
    required GetAdUseCase getAdUseCase,
    required SaveAdUseCase saveAdUseCase,
    required ChangeAdStatusUseCase changeAdStatusUseCase,
    required AddAdImageUseCase addImageUseCase,
    required RemoveAdImageUseCase removeImageUseCase,
    required ReorderAdImagesUseCase reorderImagesUseCase,
  }) : _adId = adId,
       _getOptionsUseCase = getOptionsUseCase,
       _getAdUseCase = getAdUseCase,
       _saveAdUseCase = saveAdUseCase,
       _changeAdStatusUseCase = changeAdStatusUseCase,
       _addImageUseCase = addImageUseCase,
       _removeImageUseCase = removeImageUseCase,
       _reorderImagesUseCase = reorderImagesUseCase,
       super(const AdFormState()) {
    on<LoadAdFormEvent>(_onLoad);
    on<GoToStepEvent>(_onGoToStep);
    on<SaveAdEvent>(_onSave);
    on<PublishAdEvent>(_onPublish);
    on<AddImageEvent>(_onAddImage);
    on<RemoveImageEvent>(_onRemoveImage);
    on<MoveImageEvent>(_onMoveImage);
    on<SetCoverImageEvent>(_onSetCover);
  }

  Future<void> _onLoad(LoadAdFormEvent event, Emitter<AdFormState> emit) async {
    emit(const AdFormState());
    try {
      final options = await _getOptionsUseCase.execute();
      final adId = _adId;
      final ad = adId == null ? null : await _getAdUseCase.execute(adId);
      emit(AdFormState(status: AdFormStatus.ready, options: options, ad: ad));
    } catch (e) {
      emit(
        AdFormState(status: AdFormStatus.loadFailure, failure: Failure.from(e)),
      );
    }
  }

  Future<void> _onGoToStep(
    GoToStepEvent event,
    Emitter<AdFormState> emit,
  ) async {
    if (state.isBusy) return;
    if (!event.step.needsSavedAd || state.ad != null) {
      emit(state.copyWith(step: event.step));
      return;
    }

    emit(state.copyWith(activity: AdFormActivity.saving));
    final saved = await _save(emit, event.draft);
    if (saved != null) {
      emit(state.copyWith(step: event.step, notice: 'Rascunho salvo.'));
    }
  }

  Future<void> _onSave(SaveAdEvent event, Emitter<AdFormState> emit) async {
    if (state.isBusy) return;
    emit(state.copyWith(activity: AdFormActivity.saving));
    final saved = await _save(emit, event.draft);
    if (saved != null) {
      emit(
        state.copyWith(
          notice: saved.status == AdStatus.draft
              ? 'Rascunho salvo.'
              : 'Alterações salvas.',
        ),
      );
    }
  }

  Future<void> _onPublish(
    PublishAdEvent event,
    Emitter<AdFormState> emit,
  ) async {
    if (state.isBusy) return;
    emit(state.copyWith(activity: AdFormActivity.publishing));
    final saved = await _save(emit, event.draft, keepBusy: true);
    if (saved == null) return;

    if (!saved.isComplete) {
      _emitMissing(emit, saved.missingFields);
      return;
    }
    try {
      final published = await _changeAdStatusUseCase.execute(
        saved.id,
        AdStatusAction.publish,
      );
      emit(
        state.copyWith(
          ad: published,
          activity: AdFormActivity.idle,
          isFinished: true,
          notice: 'Anúncio publicado.',
        ),
      );
    } catch (e) {
      _emitFailure(emit, Failure.from(e));
    }
  }

  Future<SellerAdEntity?> _save(
    Emitter<AdFormState> emit,
    AdDraft draft, {
    bool keepBusy = false,
  }) async {
    try {
      final saved = await _saveAdUseCase.execute(state.ad?.id, draft);
      emit(
        state.copyWith(
          ad: saved,
          activity: keepBusy ? state.activity : AdFormActivity.idle,
          highlightedFields: state.highlightedFields.intersection(
            saved.missingFields.toSet(),
          ),
        ),
      );
      return saved;
    } catch (e) {
      _emitFailure(emit, Failure.from(e));
      return null;
    }
  }

  Future<void> _onAddImage(AddImageEvent event, Emitter<AdFormState> emit) =>
      _changeImages(
        emit,
        AdFormActivity.uploading,
        (adId) => _addImageUseCase.execute(adId, event.photo),
        mapFailure: (failure) =>
            failure is ConflictFailure ? TooManyPhotosFailure() : failure,
      );

  Future<void> _onRemoveImage(
    RemoveImageEvent event,
    Emitter<AdFormState> emit,
  ) => _changeImages(
    emit,
    AdFormActivity.updatingImages,
    (adId) => _removeImageUseCase.execute(adId, event.imageId),
  );

  Future<void> _onMoveImage(MoveImageEvent event, Emitter<AdFormState> emit) {
    final ids = [
      for (final image in state.ad?.images ?? const <SellerAdImage>[]) image.id,
    ];
    final from = ids.indexOf(event.imageId);
    final to = from + event.offset;
    if (from < 0 || to < 0 || to >= ids.length) return Future.value();

    ids.insert(to, ids.removeAt(from));
    return _changeImages(
      emit,
      AdFormActivity.updatingImages,
      (adId) => _reorderImagesUseCase.execute(adId, ids),
    );
  }

  Future<void> _onSetCover(
    SetCoverImageEvent event,
    Emitter<AdFormState> emit,
  ) {
    final ids = [
      for (final image in state.ad?.images ?? const <SellerAdImage>[]) image.id,
    ];
    return _changeImages(
      emit,
      AdFormActivity.updatingImages,
      (adId) =>
          _reorderImagesUseCase.execute(adId, ids, coverImageId: event.imageId),
    );
  }

  Future<void> _changeImages(
    Emitter<AdFormState> emit,
    AdFormActivity activity,
    Future<SellerAdEntity> Function(String adId) action, {
    Failure Function(Failure failure)? mapFailure,
  }) async {
    final ad = state.ad;
    if (ad == null || state.isBusy) return;

    emit(state.copyWith(activity: activity));
    try {
      final updated = await action(ad.id);
      emit(
        state.copyWith(
          ad: updated,
          activity: AdFormActivity.idle,
          highlightedFields: updated.images.isEmpty
              ? state.highlightedFields
              : (state.highlightedFields.toSet()..remove('images')),
        ),
      );
    } catch (e) {
      final failure = Failure.from(e);
      _emitFailure(emit, mapFailure?.call(failure) ?? failure);
    }
  }

  void _emitFailure(Emitter<AdFormState> emit, Failure failure) {
    if (failure is MissingFieldsFailure) {
      _emitMissing(emit, failure.fields);
      return;
    }
    emit(
      state.copyWith(
        activity: AdFormActivity.idle,
        failure: failure is ConflictFailure || failure is NotFoundFailure
            ? AdOutdatedFailure()
            : failure,
      ),
    );
  }

  void _emitMissing(Emitter<AdFormState> emit, List<String> fields) {
    emit(
      state.copyWith(
        activity: AdFormActivity.idle,
        step: AdFormStep.firstWith(fields),
        highlightedFields: fields.toSet(),
        failure: MissingFieldsFailure(fields),
      ),
    );
  }
}

class AdFormEvent {}

class LoadAdFormEvent extends AdFormEvent {}

class GoToStepEvent extends AdFormEvent {
  final AdFormStep step;
  final AdDraft draft;

  GoToStepEvent({required this.step, required this.draft});
}

class SaveAdEvent extends AdFormEvent {
  final AdDraft draft;

  SaveAdEvent({required this.draft});
}

class PublishAdEvent extends AdFormEvent {
  final AdDraft draft;

  PublishAdEvent({required this.draft});
}

class AddImageEvent extends AdFormEvent {
  final UploadFile photo;

  AddImageEvent({required this.photo});
}

class RemoveImageEvent extends AdFormEvent {
  final String imageId;

  RemoveImageEvent({required this.imageId});
}

class MoveImageEvent extends AdFormEvent {
  final String imageId;
  final int offset;

  MoveImageEvent({required this.imageId, required this.offset});
}

class SetCoverImageEvent extends AdFormEvent {
  final String imageId;

  SetCoverImageEvent({required this.imageId});
}

enum AdFormStatus { loading, ready, loadFailure }

enum AdFormActivity { idle, saving, publishing, uploading, updatingImages }

class AdFormState {
  final AdFormStatus status;
  final CatalogFilterOptions? options;

  final SellerAdEntity? ad;
  final AdFormStep step;
  final AdFormActivity activity;

  final Set<String> highlightedFields;

  final bool isFinished;
  final Failure? failure;
  final String? notice;

  const AdFormState({
    this.status = AdFormStatus.loading,
    this.options,
    this.ad,
    this.step = AdFormStep.general,
    this.activity = AdFormActivity.idle,
    this.highlightedFields = const {},
    this.isFinished = false,
    this.failure,
    this.notice,
  });

  bool get isBusy => activity != AdFormActivity.idle;

  bool get isNew => ad == null;

  bool get canPublish => ad == null || ad!.status == AdStatus.draft;

  AdFormState copyWith({
    SellerAdEntity? ad,
    AdFormStep? step,
    AdFormActivity? activity,
    Set<String>? highlightedFields,
    bool? isFinished,
    Failure? failure,
    String? notice,
  }) => AdFormState(
    status: status,
    options: options,
    ad: ad ?? this.ad,
    step: step ?? this.step,
    activity: activity ?? this.activity,
    highlightedFields: highlightedFields ?? this.highlightedFields,
    isFinished: isFinished ?? this.isFinished,
    failure: failure,
    notice: notice,
  );
}
