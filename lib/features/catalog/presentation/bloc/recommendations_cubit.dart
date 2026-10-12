import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_item.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_recommended_items_use_case.dart';

/// Feeds the "Para você" home section.
///
/// The section is optional, so every failure hides it: signed out (401),
/// no podological profile consent (403), no matches or no connection.
/// While reloading, the current items stay on screen.
class RecommendationsCubit extends Cubit<RecommendationsState> {
  final GetRecommendedItemsUseCase _getRecommendedItemsUseCase;

  /// Drops responses from a load that a newer [load] or [hide] replaced.
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
