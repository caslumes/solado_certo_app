import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/home_section.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_home_sections_use_case.dart';

class HomeSectionsCubit extends Cubit<List<HomeSectionEntity>> {
  final GetHomeSectionsUseCase _getHomeSectionsUseCase;

  int _generation = 0;

  HomeSectionsCubit({required GetHomeSectionsUseCase getHomeSectionsUseCase})
    : _getHomeSectionsUseCase = getHomeSectionsUseCase,
      super(const []);

  Future<void> load() async {
    final generation = ++_generation;
    List<HomeSectionEntity> next;
    try {
      next = await _getHomeSectionsUseCase.execute();
    } catch (_) {
      next = const [];
    }
    if (!isClosed && generation == _generation) emit(next);
  }

  void hide() {
    _generation++;
    emit(const []);
  }
}
