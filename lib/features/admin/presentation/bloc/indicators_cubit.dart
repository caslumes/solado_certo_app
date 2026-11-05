import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/admin/domain/entities/admin_entities.dart';
import 'package:solado_certo_app/features/admin/domain/usecases/admin_use_cases.dart';

enum IndicatorPeriod {
  week(7, '7 dias'),
  month(30, '30 dias'),
  quarter(90, '90 dias'),
  year(365, '12 meses');

  const IndicatorPeriod(this.days, this.label);

  final int days;
  final String label;
}

class IndicatorsCubit extends Cubit<IndicatorsState> {
  final GetIndicatorsUseCase _getIndicatorsUseCase;
  final DateTime Function() _now;

  int _generation = 0;

  IndicatorsCubit({
    required GetIndicatorsUseCase getIndicatorsUseCase,
    DateTime Function() now = DateTime.now,
  }) : _getIndicatorsUseCase = getIndicatorsUseCase,
       _now = now,
       super(const IndicatorsState());

  Future<void> load([IndicatorPeriod? period]) async {
    final generation = ++_generation;
    final selected = period ?? state.period;
    final refreshing = period == null && state.indicators != null;
    if (!refreshing) emit(IndicatorsState(period: selected));

    final today = _now();
    final to = DateTime(today.year, today.month, today.day);
    final from = to.subtract(Duration(days: selected.days - 1));
    try {
      final indicators = await _getIndicatorsUseCase.execute(from, to);
      if (isClosed || generation != _generation) return;
      emit(IndicatorsState(period: selected, indicators: indicators));
    } catch (e) {
      if (isClosed || generation != _generation) return;
      emit(
        IndicatorsState(
          period: selected,
          indicators: refreshing ? state.indicators : null,
          failure: Failure.from(e),
        ),
      );
    }
  }
}

class IndicatorsState {
  final IndicatorPeriod period;
  final IndicatorsEntity? indicators;
  final Failure? failure;

  const IndicatorsState({
    this.period = IndicatorPeriod.month,
    this.indicators,
    this.failure,
  });

  bool get loading => indicators == null && failure == null;
}
