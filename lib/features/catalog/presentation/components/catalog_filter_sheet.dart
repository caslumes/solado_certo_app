import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filter_options.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filters.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/catalog_options_cubit.dart';

Future<CatalogFilters?> showCatalogFilterSheet(
  BuildContext context, {
  required CatalogFilters filters,
}) {
  final optionsCubit = context.read<CatalogOptionsCubit>();
  if (optionsCubit.state is CatalogOptionsLoadFailure) optionsCubit.load();

  return showModalBottomSheet<CatalogFilters>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(),
    builder: (_) => BlocProvider.value(
      value: optionsCubit,
      child: CatalogFilterSheet(filters: filters),
    ),
  );
}

class CatalogFilterSheet extends StatefulWidget {
  const CatalogFilterSheet({super.key, required this.filters});

  final CatalogFilters filters;

  @override
  State<CatalogFilterSheet> createState() => _CatalogFilterSheetState();
}

class _CatalogFilterSheetState extends State<CatalogFilterSheet> {
  static const _ratings = [1, 2, 3, 4];

  final _formKey = GlobalKey<FormState>();
  late final _priceMinController = TextEditingController(
    text: _formatPrice(widget.filters.priceMin),
  );
  late final _priceMaxController = TextEditingController(
    text: _formatPrice(widget.filters.priceMax),
  );
  late String? _categoryId = widget.filters.categoryId;
  late int? _ratingMin = widget.filters.ratingMin;
  late String? _state = widget.filters.state;
  late final Set<String> _purposes = {...widget.filters.purposes};
  late final Set<String> _conditions = {...widget.filters.conditions};

  int _resets = 0;

  @override
  void dispose() {
    _priceMinController.dispose();
    _priceMaxController.dispose();
    super.dispose();
  }

  static String _formatPrice(double? price) =>
      price == null ? '' : price.toString().replaceAll('.', ',');

  static double? _parsePrice(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  String? _validatePrice(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final price = _parsePrice(text);
    return price == null || price < 0 ? 'Valor inválido' : null;
  }

  String? _validatePriceMax(String? value) {
    final error = _validatePrice(value);
    if (error != null) return error;
    final min = _parsePrice(_priceMinController.text);
    final max = _parsePrice(value ?? '');
    return min != null && max != null && max < min
        ? 'Menor que o mínimo'
        : null;
  }

  void _clear() {
    setState(() {
      _resets++;
      _priceMinController.clear();
      _priceMaxController.clear();
      _categoryId = null;
      _ratingMin = null;
      _state = null;
      _purposes.clear();
      _conditions.clear();
    });
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      CatalogFilters(
        categoryId: _categoryId,
        priceMin: _parsePrice(_priceMinController.text),
        priceMax: _parsePrice(_priceMaxController.text),
        ratingMin: _ratingMin,
        state: _state,
        purposes: _purposes,
        conditions: _conditions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(child: Text('Filtros', style: textTheme.bodyMedium)),
                  TextButton(onPressed: _clear, child: const Text('Limpar')),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16.0,
                  children: [
                    BlocBuilder<CatalogOptionsCubit, CatalogOptionsState>(
                      builder: (context, state) => switch (state) {
                        CatalogOptionsLoaded(:final options) => _OptionFilters(
                          key: ValueKey(_resets),
                          options: options,
                          categoryId: _categoryId,
                          purposes: _purposes,
                          conditions: _conditions,
                          onCategoryChanged: (id) =>
                              setState(() => _categoryId = id),
                          onPurposeToggled: (code, selected) => setState(
                            () => selected
                                ? _purposes.add(code)
                                : _purposes.remove(code),
                          ),
                          onConditionToggled: (id, selected) => setState(
                            () => selected
                                ? _conditions.add(id)
                                : _conditions.remove(id),
                          ),
                        ),
                        CatalogOptionsLoadFailure(:final failure) => Row(
                          children: [
                            Expanded(
                              child: Text(
                                failure.message,
                                style: textTheme.labelLarge,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.read<CatalogOptionsCubit>().load(),
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                        CatalogOptionsLoading() => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      },
                    ),
                    Text('Preço (R\$)', style: textTheme.bodySmall),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16.0,
                      children: [
                        Expanded(
                          child: ShoeTextFormField(
                            controller: _priceMinController,
                            hintText: 'Mínimo',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: _validatePrice,
                          ),
                        ),
                        Expanded(
                          child: ShoeTextFormField(
                            controller: _priceMaxController,
                            hintText: 'Máximo',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.done,
                            validator: _validatePriceMax,
                          ),
                        ),
                      ],
                    ),
                    Text('Avaliação mínima', style: textTheme.bodySmall),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        _choiceChip(
                          label: 'Qualquer',
                          selected: _ratingMin == null,
                          onSelected: () => setState(() => _ratingMin = null),
                        ),
                        for (final rating in _ratings)
                          _choiceChip(
                            label: '★ $rating+',
                            selected: _ratingMin == rating,
                            onSelected: () =>
                                setState(() => _ratingMin = rating),
                          ),
                      ],
                    ),
                    Text('Estado do vendedor', style: textTheme.bodySmall),
                    DropdownButtonFormField<String?>(
                      key: ValueKey(_resets),
                      initialValue: _state,
                      decoration: _dropdownDecoration,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todos'),
                        ),
                        for (final uf
                            in FieldValidators.states.toList()..sort())
                          DropdownMenuItem(value: uf, child: Text(uf)),
                      ],
                      onChanged: (uf) => setState(() => _state = uf),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ShoeTextButton(onPressed: _apply, text: 'Aplicar'),
            ),
          ],
        ),
      ),
    );
  }
}

const _dropdownDecoration = InputDecoration(
  filled: true,
  fillColor: AppColors.secondaryColor,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide.none,
  ),
);

Widget _choiceChip({
  required String label,
  required bool selected,
  required VoidCallback onSelected,
}) => Builder(
  builder: (context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return ChoiceChip(
      label: Text(
        label,
        style: selected ? style?.copyWith(color: Colors.white) : style,
      ),
      selectedColor: AppColors.primaryColor,
      checkmarkColor: Colors.white,
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  },
);

Widget _filterChip({
  required String label,
  required bool selected,
  required ValueChanged<bool> onSelected,
}) => Builder(
  builder: (context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return FilterChip(
      label: Text(
        label,
        style: selected ? style?.copyWith(color: Colors.white) : style,
      ),
      selectedColor: AppColors.primaryColor,
      checkmarkColor: Colors.white,
      selected: selected,
      onSelected: onSelected,
    );
  },
);

class _OptionFilters extends StatelessWidget {
  const _OptionFilters({
    super.key,
    required this.options,
    required this.categoryId,
    required this.purposes,
    required this.conditions,
    required this.onCategoryChanged,
    required this.onPurposeToggled,
    required this.onConditionToggled,
  });

  final CatalogFilterOptions options;
  final String? categoryId;
  final Set<String> purposes;
  final Set<String> conditions;
  final ValueChanged<String?> onCategoryChanged;
  final void Function(String code, bool selected) onPurposeToggled;
  final void Function(String id, bool selected) onConditionToggled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16.0,
      children: [
        Text('Categoria', style: textTheme.bodySmall),
        DropdownButtonFormField<String?>(
          initialValue: categoryId,
          decoration: _dropdownDecoration,
          isExpanded: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('Todas')),
            for (final category in options.categories) ...[
              DropdownMenuItem(value: category.id, child: Text(category.name)),
              for (final child in category.children)
                DropdownMenuItem(
                  value: child.id,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(child.name),
                  ),
                ),
            ],
          ],
          onChanged: onCategoryChanged,
        ),
        if (options.purposes.isNotEmpty) ...[
          Text('Finalidade', style: textTheme.bodySmall),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              for (final purpose in options.purposes)
                _filterChip(
                  label: purpose.name,
                  selected: purposes.contains(purpose.code),
                  onSelected: (selected) =>
                      onPurposeToggled(purpose.code, selected),
                ),
            ],
          ),
        ],
        if (options.conditions.isNotEmpty) ...[
          Text('Condição podológica', style: textTheme.bodySmall),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              for (final condition in options.conditions)
                _filterChip(
                  label: condition.name,
                  selected: conditions.contains(condition.id),
                  onSelected: (selected) =>
                      onConditionToggled(condition.id, selected),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
