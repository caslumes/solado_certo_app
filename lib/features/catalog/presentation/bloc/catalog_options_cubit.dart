import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filter_options.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_catalog_filter_options_use_case.dart';

class CatalogOptionsCubit extends Cubit<CatalogOptionsState> {
  final GetCatalogFilterOptionsUseCase _getCatalogFilterOptionsUseCase;

  CatalogOptionsCubit({
    required GetCatalogFilterOptionsUseCase getCatalogFilterOptionsUseCase,
  }) : _getCatalogFilterOptionsUseCase = getCatalogFilterOptionsUseCase,
       super(CatalogOptionsLoading());

  Future<void> load() async {
    emit(CatalogOptionsLoading());
    try {
      emit(
        CatalogOptionsLoaded(
          options: await _getCatalogFilterOptionsUseCase.execute(),
        ),
      );
    } catch (e) {
      emit(CatalogOptionsLoadFailure(failure: Failure.from(e)));
    }
  }
}

sealed class CatalogOptionsState {}

class CatalogOptionsLoading extends CatalogOptionsState {}

class CatalogOptionsLoaded extends CatalogOptionsState {
  CatalogOptionsLoaded({required this.options});

  final CatalogFilterOptions options;
}

class CatalogOptionsLoadFailure extends CatalogOptionsState {
  CatalogOptionsLoadFailure({required this.failure});

  final Failure failure;
}
