import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/measurements.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/arch_type.dart';

String formatCentimeters(double value) =>
    '${value.toStringAsFixed(1).replaceAll('.', ',')} cm';

double? parseCentimeters(String? value) {
  final decimal = FieldValidators.parseDecimal(value ?? '');
  return decimal == null ? null : double.parse(decimal);
}

FieldValidator centimetersBetween(double min, double max) => (value) {
  if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
  final number = parseCentimeters(value);
  if (number == null) return 'Valor inválido (ex.: 26,5)';
  final rounded = (number * 10).round() / 10;
  return rounded < min || rounded > max
      ? 'Informe entre ${min.toInt()} e ${max.toInt()} cm'
      : null;
};

class MeasurementsController {
  MeasurementsController([Measurements? initial])
    : leftLength = _text(initial?.left.lengthCm),
      leftWidth = _text(initial?.left.widthCm),
      rightLength = _text(initial?.right.lengthCm),
      rightWidth = _text(initial?.right.widthCm),
      shoeSize = TextEditingController(
        text: initial == null ? '' : '${initial.shoeSize}',
      ),
      archType = ValueNotifier(initial?.archType);

  static TextEditingController _text(double? value) => TextEditingController(
    text: value == null ? '' : value.toStringAsFixed(1).replaceAll('.', ','),
  );

  final TextEditingController leftLength;
  final TextEditingController leftWidth;
  final TextEditingController rightLength;
  final TextEditingController rightWidth;
  final TextEditingController shoeSize;
  final ValueNotifier<ArchType?> archType;

  static double _round(double value) => (value * 10).round() / 10;

  Measurements read() => Measurements(
    left: FootMeasurement(
      lengthCm: _round(parseCentimeters(leftLength.text)!),
      widthCm: _round(parseCentimeters(leftWidth.text)!),
    ),
    right: FootMeasurement(
      lengthCm: _round(parseCentimeters(rightLength.text)!),
      widthCm: _round(parseCentimeters(rightWidth.text)!),
    ),
    archType: archType.value!,
    shoeSize: int.parse(shoeSize.text.trim()),
  );

  void dispose() {
    leftLength.dispose();
    leftWidth.dispose();
    rightLength.dispose();
    rightWidth.dispose();
    shoeSize.dispose();
    archType.dispose();
  }
}

class MeasurementsFields extends StatelessWidget {
  const MeasurementsFields({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  final MeasurementsController controller;
  final bool enabled;

  static final _lengthValidator = centimetersBetween(
    FootMeasurement.minLength,
    FootMeasurement.maxLength,
  );
  static final _widthValidator = centimetersBetween(
    FootMeasurement.minWidth,
    FootMeasurement.maxWidth,
  );

  Widget _foot(
    BuildContext context, {
    required String title,
    required TextEditingController length,
    required TextEditingController width,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8.0,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyMedium),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12.0,
          children: [
            Expanded(
              child: ShoeTextFormField(
                labelText: 'Comprimento (cm)',
                hintText: 'Ex.: 26,5',
                controller: length,
                readOnly: !enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _lengthValidator,
              ),
            ),
            Expanded(
              child: ShoeTextFormField(
                labelText: 'Largura (cm)',
                hintText: 'Ex.: 9,8',
                controller: width,
                readOnly: !enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _widthValidator,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16.0,
      children: [
        _foot(
          context,
          title: 'Pé esquerdo',
          length: controller.leftLength,
          width: controller.leftWidth,
        ),
        _foot(
          context,
          title: 'Pé direito',
          length: controller.rightLength,
          width: controller.rightWidth,
        ),
        ShoeTextFormField(
          labelText: 'Numeração do calçado',
          hintText: 'Ex.: 38',
          controller: controller.shoeSize,
          readOnly: !enabled,
          keyboardType: TextInputType.number,
          validator: FieldValidators.intRange(
            Measurements.minShoeSize,
            Measurements.maxShoeSize,
          ),
        ),
        ValueListenableBuilder<ArchType?>(
          valueListenable: controller.archType,
          builder: (context, archType, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4.0,
            children: [
              Text('Tipo de arco do pé', style: textTheme.bodyMedium),
              DropdownButtonFormField<ArchType>(
                initialValue: archType,
                hint: const Text('Escolha'),
                items: [
                  for (final type in ArchType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: enabled
                    ? (value) => controller.archType.value = value
                    : null,
                validator: (value) =>
                    value == null ? 'Campo obrigatório' : null,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: AppColors.secondaryColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MeasuringGuide extends StatelessWidget {
  const MeasuringGuide({super.key});

  static const _steps = [
    'Apoie o pé descalço sobre uma folha, com o calcanhar encostado na '
        'parede, e marque a ponta do dedo mais longo.',
    'O comprimento é a distância da parede até a marca.',
    'A largura é a parte mais larga do pé, na altura dos dedos.',
    'Meça os dois pés: é comum que tenham tamanhos diferentes.',
    'Pelo tipo de arco: pé plano deixa a sola inteira marcada no chão; '
        'arco alto (pé cavo) quase não marca o meio do pé.',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.warningBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6.0,
        children: [
          Row(
            spacing: 8.0,
            children: [
              const Icon(Icons.straighten, color: AppColors.warningColor),
              Text('Como medir', style: textTheme.bodyMedium),
            ],
          ),
          for (final (index, step) in _steps.indexed)
            Text('${index + 1}. $step', style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
