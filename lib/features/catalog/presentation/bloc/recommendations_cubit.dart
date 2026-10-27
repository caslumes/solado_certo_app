import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_item.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_recommended_items_use_case.dart';

class RecommendationsCubit extends Cubit<RecommendationsState> {
  final GetRecommendedItemsUseCase _getRecommendedItemsUseCase;

  int _generation = 0;

  RecommendationsCubit({
    required GetRecommendedItemsUseCase getRecommendedItemsUseCase,
  }) : _getRecommendedItemsUseCase = getRecommendedItemsUseCase,
       super(RecommendationsHidden());

  Future<void> load() async {
    final generation = ++_generation;
    RecommendationsState next;
    try {
      final items = await _getRecommendedItemsUseCase.execute();
      next = items.isEmpty
          ? RecommendationsHidden()
          : RecommendationsLoaded(items: items);
    } catch (_) {
      next = RecommendationsHidden();
    }
    if (!isClosed && generation == _generation) emit(next);
  }

  void hide() {
    _generation++;
    emit(RecommendationsHidden());
  }
}

sealed class RecommendationsState {}

class RecommendationsHidden extends RecommendationsState {}

class RecommendationsLoaded extends RecommendationsState {
  RecommendationsLoaded({required this.items});

  final List<CatalogItemEntity> items;
}
