import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_status.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/change_ad_status_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/get_my_ads_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/remove_ad_use_case.dart';

class MyAdsBloc extends Bloc<MyAdsEvent, MyAdsState> {
  final GetMyAdsUseCase _getMyAdsUseCase;
  final ChangeAdStatusUseCase _changeAdStatusUseCase;
  final RemoveAdUseCase _removeAdUseCase;

  MyAdsBloc({
    required GetMyAdsUseCase getMyAdsUseCase,
    required ChangeAdStatusUseCase changeAdStatusUseCase,
    required RemoveAdUseCase removeAdUseCase,
  }) : _getMyAdsUseCase = getMyAdsUseCase,
       _changeAdStatusUseCase = changeAdStatusUseCase,
       _removeAdUseCase = removeAdUseCase,
       super(MyAdsLoading()) {
    on<LoadMyAdsEvent>(_onLoad);
    on<ChangeAdStatusEvent>(_onChangeStatus);
    on<RemoveAdEvent>(_onRemove);
  }

  Future<void> _onLoad(LoadMyAdsEvent event, Emitter<MyAdsState> emit) async {
    final currentState = state;
    if (currentState is! MyAdsLoaded) emit(MyAdsLoading());
    try {
      emit(MyAdsLoaded(ads: await _getMyAdsUseCase.execute()));
    } catch (e) {
      final failure = Failure.from(e);
      emit(
        currentState is MyAdsLoaded
            ? MyAdsLoaded(ads: currentState.ads, failure: failure)
            : MyAdsLoadFailure(failure: failure),
      );
    }
  }

  Future<void> _onChangeStatus(
    ChangeAdStatusEvent event,
    Emitter<MyAdsState> emit,
  ) => _act(emit, event.adId, event.action.notice, (ads) async {
    final updated = await _changeAdStatusUseCase.execute(
      event.adId,
      event.action,
    );
    return [for (final ad in ads) ad.id == updated.id ? updated : ad];
  });

  Future<void> _onRemove(RemoveAdEvent event, Emitter<MyAdsState> emit) =>
      _act(emit, event.adId, 'Anúncio removido.', (ads) async {
        await _removeAdUseCase.execute(event.adId);
        return [
          for (final ad in ads)
            if (ad.id != event.adId) ad,
        ];
      });

  Future<void> _act(
    Emitter<MyAdsState> emit,
    String adId,
    String notice,
    Future<List<SellerAdEntity>> Function(List<SellerAdEntity> ads) action,
  ) async {
    final currentState = state;
    if (currentState is! MyAdsLoaded || currentState.busyAdId != null) return;

    final ads = currentState.ads;
    emit(MyAdsLoaded(ads: ads, busyAdId: adId));
    try {
      emit(MyAdsLoaded(ads: await action(ads), notice: notice));
    } catch (e) {
      final failure = Failure.from(e);
      if (failure is ConflictFailure || failure is NotFoundFailure) {
        emit(
          MyAdsLoaded(ads: await _reloadOr(ads), failure: AdOutdatedFailure()),
        );
        return;
      }
      emit(MyAdsLoaded(ads: ads, failure: failure));
    }
  }

  Future<List<SellerAdEntity>> _reloadOr(List<SellerAdEntity> ads) async {
    try {
      return await _getMyAdsUseCase.execute();
    } catch (_) {
      return ads;
    }
  }
}

class MyAdsEvent {}

class LoadMyAdsEvent extends MyAdsEvent {}

class ChangeAdStatusEvent extends MyAdsEvent {
  final String adId;
  final AdStatusAction action;

  ChangeAdStatusEvent({required this.adId, required this.action});
}

class RemoveAdEvent extends MyAdsEvent {
  final String adId;

  RemoveAdEvent({required this.adId});
}

sealed class MyAdsState {}

class MyAdsLoading extends MyAdsState {}

class MyAdsLoadFailure extends MyAdsState {
  final Failure failure;

  MyAdsLoadFailure({required this.failure});
}

class MyAdsLoaded extends MyAdsState {
  final List<SellerAdEntity> ads;

  final String? busyAdId;
  final Failure? failure;
  final String? notice;

  MyAdsLoaded({required this.ads, this.busyAdId, this.failure, this.notice});

  List<SellerAdEntity> withStatus(AdStatus status) => [
    for (final ad in ads)
      if (ad.status == status) ad,
  ];
}
