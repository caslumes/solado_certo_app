import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filter_options.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/category.dart';
import 'package:solado_certo_app/features/catalog/domain/enum/product_attributes.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_image.dart';
import 'package:solado_certo_app/features/seller/domain/entities/seller_ad.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_field.dart';
import 'package:solado_certo_app/features/seller/presentation/bloc/ad_form_bloc.dart';
import 'package:solado_certo_app/features/seller/presentation/components/ad_form_fields.dart';

const maxAdPhotos = 6;
const maxShippingOptions = 5;
const _missingText = 'Obrigatório para publicar';

class AdFormSectionContext {
  const AdFormSectionContext({
    required this.fields,
    required this.state,
    required this.onChanged,
  });

  final AdFormFields fields;
  final AdFormState state;
  final VoidCallback onChanged;

  CatalogFilterOptions get options => state.options!;

  String? missing(String field) =>
      state.highlightedFields.contains(field) && fields.isEmpty(field)
      ? _missingText
      : null;

  CategoryEntity? get category {
    for (final root in options.categories) {
      if (root.id == fields.categoryId) return root;
      for (final child in root.children) {
        if (child.id == fields.categoryId) return child;
      }
    }
    return null;
  }

  bool isRequiredAttribute(String field) =>
      (category?.requiredAttributes.contains(field) ?? false) &&
      !(field == 'size' && fields.customMadeAllowed);

  bool get isClinical =>
      fields.prescriptionRequired || fields.conditionIds.isNotEmpty;
}

String _label(String text, {bool required = false}) =>
    required ? '$text *' : text;

class AdGeneralSection extends StatelessWidget {
  const AdGeneralSection({super.key, required this.section});

  final AdFormSectionContext section;

  @override
  Widget build(BuildContext context) {
    final fields = section.fields;

    return _SectionColumn(
      children: [
        ShoeTextFormField(
          labelText: _label('Título', required: true),
          controller: fields.title,
          validator: FieldValidators.combine([
            FieldValidators.required,
            FieldValidators.maxLength(150),
          ]),
          textCapitalization: TextCapitalization.sentences,
        ),
        _Dropdown<String>(
          label: _label('Categoria', required: true),
          value: fields.categoryId,
          items: {
            for (final root in section.options.categories) ...{
              root.id: root.name,
              for (final child in root.children)
                child.id: '${root.name} › ${child.name}',
            },
          },
          validator: (value) => value == null ? 'Escolha a categoria' : null,
          onChanged: (value) {
            fields.categoryId = value;
            section.onChanged();
          },
        ),
        ShoeTextFormField(
          labelText: _label('Descrição', required: true),
          controller: fields.description,
          forceErrorText: section.missing('description'),
          validator: FieldValidators.maxLength(2000),
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => section.onChanged(),
        ),
        ShoeTextFormField(
          labelText: _label('Preço (R\$)', required: true),
          hintText: '89,90',
          controller: fields.price,
          forceErrorText: section.missing('price'),
          validator: FieldValidators.decimal,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => section.onChanged(),
        ),
        ShoeTextFormField(
          labelText: 'Estoque',
          controller: fields.stock,
          validator: FieldValidators.intRange(0, 999999),
          keyboardType: TextInputType.number,
        ),
        _Switch(
          label: 'Exige prescrição profissional',
          value: fields.prescriptionRequired,
          onChanged: (value) {
            fields.prescriptionRequired = value;
            section.onChanged();
          },
        ),
        _Switch(
          label: 'Feito sob medida',
          value: fields.customMadeAllowed,
          onChanged: (value) {
            fields.customMadeAllowed = value;
            section.onChanged();
          },
        ),
      ],
    );
  }
}

class AdAttributesSection extends StatelessWidget {
  const AdAttributesSection({super.key, required this.section});

  final AdFormSectionContext section;

  @override
  Widget build(BuildContext context) {
    final fields = section.fields;
    final hasCategory = section.category != null;
    bool required(String field) => section.isRequiredAttribute(field);

    return _SectionColumn(
      children: [
        _Hint(
          hasCategory
              ? 'Campos com * são obrigatórios para esta categoria.'
              : 'Escolha a categoria em "Dados gerais" para ver quais '
                    'atributos são obrigatórios.',
        ),
        _Dropdown<String>(
          label: _label('Lado', required: required('side')),
          value: fields.side,
          items: sideLabels,
          allowEmpty: true,
          forceErrorText: section.missing('side'),
          onChanged: (value) {
            fields.side = value;
            section.onChanged();
          },
        ),
        ShoeTextFormField(
          labelText: _label('Tamanho', required: required('size')),
          hintText: 'Ex.: 38, P, 35-36',
          controller: fields.size,
          forceErrorText: section.missing('size'),
          validator: FieldValidators.maxLength(20),
          onChanged: (_) => section.onChanged(),
        ),
        ShoeTextFormField(
          labelText: _label('Material', required: required('material')),
          hintText: 'Ex.: EVA, silicone',
          controller: fields.material,
          forceErrorText: section.missing('material'),
          validator: FieldValidators.maxLength(80),
          onChanged: (_) => section.onChanged(),
        ),
        _Dropdown<String>(
          label: _label('Rigidez', required: required('rigidity')),
          value: fields.rigidity,
          items: rigidityLabels,
          allowEmpty: true,
          forceErrorText: section.missing('rigidity'),
          onChanged: (value) {
            fields.rigidity = value;
            section.onChanged();
          },
        ),
        ShoeTextFormField(
          labelText: _label(
            'Indicação de uso',
            required: required('usage_indication'),
          ),
          hintText: 'Ex.: uso diário, corrida',
          controller: fields.usageIndication,
          forceErrorText: section.missing('usage_indication'),
          validator: FieldValidators.maxLength(120),
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => section.onChanged(),
        ),
      ],
    );
  }
}

class AdPurposesSection extends StatelessWidget {
  const AdPurposesSection({super.key, required this.section});

  final AdFormSectionContext section;

  @override
  Widget build(BuildContext context) {
    final fields = section.fields;
    final textTheme = Theme.of(context).textTheme;

    return _SectionColumn(
      children: [
        Text('Finalidades', style: textTheme.bodyMedium),
        _Chips(
          items: {
            for (final purpose in section.options.purposes)
              purpose.code: purpose.name,
          },
          selected: fields.purposes,
          onChanged: section.onChanged,
        ),
        Text('Condições indicadas', style: textTheme.bodyMedium),
        _Chips(
          items: {
            for (final condition in section.options.conditions)
              condition.id: condition.name,
          },
          selected: fields.conditionIds,
          onChanged: section.onChanged,
        ),
        _Hint(
          section.isClinical
              ? 'Itens com prescrição ou condição indicada precisam de alertas '
                    'de segurança e contraindicações.'
              : 'Alertas e contraindicações são obrigatórios se o item exigir '
                    'prescrição ou indicar uma condição.',
        ),
        ShoeTextFormField(
          labelText: _label(
            'Alertas de segurança',
            required: section.isClinical,
          ),
          controller: fields.safetyAlerts,
          forceErrorText: section.missing('safety_alerts'),
          validator: FieldValidators.maxLength(2000),
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => section.onChanged(),
        ),
        ShoeTextFormField(
          labelText: _label('Contraindicações', required: section.isClinical),
          controller: fields.contraindications,
          forceErrorText: section.missing('contraindications'),
          validator: FieldValidators.maxLength(2000),
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => section.onChanged(),
        ),
      ],
    );
  }
}

class AdPhotosSection extends StatelessWidget {
  const AdPhotosSection({
    super.key,
    required this.section,
    required this.onAdd,
    required this.onRemove,
    required this.onMove,
    required this.onSetCover,
  });

  final AdFormSectionContext section;
  final VoidCallback onAdd;
  final void Function(SellerAdImage image) onRemove;
  final void Function(SellerAdImage image, int offset) onMove;
  final void Function(SellerAdImage image) onSetCover;

  @override
  Widget build(BuildContext context) {
    final state = section.state;
    final images = state.ad?.images ?? const <SellerAdImage>[];
    final isUploading = state.activity == AdFormActivity.uploading;
    final textTheme = Theme.of(context).textTheme;

    return _SectionColumn(
      children: [
        _Hint(
          'Até $maxAdPhotos fotos JPEG, PNG ou WebP de até 5 MB. A capa '
          'aparece no catálogo.',
        ),
        if (state.highlightedFields.contains('images') && images.isEmpty)
          Text(
            'Adicione ao menos uma foto para publicar.',
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: [
            for (final (index, image) in images.indexed)
              _PhotoTile(
                image: image,
                isFirst: index == 0,
                isLast: index == images.length - 1,
                enabled: !state.isBusy,
                onRemove: () => onRemove(image),
                onMove: (offset) => onMove(image, offset),
                onSetCover: () => onSetCover(image),
              ),
            if (isUploading)
              const SizedBox.square(
                dimension: _PhotoTile.size,
                child: ColoredBox(
                  color: AppColors.secondaryColor,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
        Text(
          '${images.length} de $maxAdPhotos fotos',
          style: textTheme.labelMedium,
        ),
        OutlinedButton.icon(
          onPressed: state.isBusy || images.length >= maxAdPhotos
              ? null
              : onAdd,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Adicionar foto'),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.image,
    required this.isFirst,
    required this.isLast,
    required this.enabled,
    required this.onRemove,
    required this.onMove,
    required this.onSetCover,
  });

  static const size = 120.0;

  final SellerAdImage image;
  final bool isFirst;
  final bool isLast;
  final bool enabled;
  final VoidCallback onRemove;
  final void Function(int offset) onMove;
  final VoidCallback onSetCover;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    IconButton action(IconData icon, String tooltip, VoidCallback? onPressed) =>
        IconButton(
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          tooltip: tooltip,
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon),
        );

    return SizedBox(
      width: size,
      child: Column(
        children: [
          SizedBox.square(
            dimension: size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductImage(url: image.url, semanticLabel: image.altText),
                if (image.isCover)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      color: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        'Capa',
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              action(
                Icons.chevron_left,
                'Mover para a esquerda',
                isFirst ? null : () => onMove(-1),
              ),
              action(
                image.isCover ? Icons.star : Icons.star_border,
                'Usar como capa',
                image.isCover ? null : onSetCover,
              ),
              action(
                Icons.chevron_right,
                'Mover para a direita',
                isLast ? null : () => onMove(1),
              ),
            ],
          ),
          action(Icons.delete_outline, 'Remover foto', onRemove),
        ],
      ),
    );
  }
}

class AdShippingSection extends StatelessWidget {
  const AdShippingSection({super.key, required this.section});

  final AdFormSectionContext section;

  @override
  Widget build(BuildContext context) {
    final fields = section.fields;
    final textTheme = Theme.of(context).textTheme;
    final missing = section.missing('shipping_options');

    return _SectionColumn(
      children: [
        _Hint(
          'Informe ao menos uma forma de envio, com preço e prazo em dias '
          'úteis.',
        ),
        if (missing != null)
          Text(
            'Adicione ao menos uma opção de envio para publicar.',
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        for (final (index, option) in fields.shippingOptions.indexed)
          _ShippingOptionCard(
            key: ObjectKey(option),
            number: index + 1,
            option: option,
            onRemove: () {
              fields.shippingOptions.remove(option);
              disposeShippingOptionLater(option);
              section.onChanged();
            },
          ),
        OutlinedButton.icon(
          onPressed: fields.shippingOptions.length >= maxShippingOptions
              ? null
              : () {
                  fields.shippingOptions.add(ShippingOptionFields());
                  section.onChanged();
                },
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Adicionar opção de envio'),
        ),
        ShoeTextFormField(
          labelText: 'Observações de envio (opcional)',
          controller: fields.shippingNotes,
          validator: FieldValidators.maxLength(2000),
          maxLines: 3,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}

class _ShippingOptionCard extends StatelessWidget {
  const _ShippingOptionCard({
    super.key,
    required this.number,
    required this.option,
    required this.onRemove,
  });

  final int number;
  final ShippingOptionFields option;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.secondaryColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 12.0,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Opção $number',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Remover opção $number',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            ShoeTextFormField(
              labelText: _label('Nome', required: true),
              hintText: 'Ex.: PAC, SEDEX, retirada',
              controller: option.name,
              validator: FieldValidators.combine([
                FieldValidators.required,
                FieldValidators.maxLength(80),
              ]),
            ),
            ShoeTextFormField(
              labelText: 'Transportadora (opcional)',
              controller: option.carrier,
              validator: FieldValidators.maxLength(80),
            ),
            ShoeTextFormField(
              labelText: _label('Preço (R\$)', required: true),
              hintText: '19,90',
              controller: option.price,
              validator: FieldValidators.combine([
                FieldValidators.required,
                FieldValidators.decimal,
              ]),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            ShoeTextFormField(
              labelText: _label('Prazo (dias úteis)', required: true),
              controller: option.deliveryDays,
              validator: FieldValidators.intRange(0, 90),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}

class AdReviewSection extends StatelessWidget {
  const AdReviewSection({super.key, required this.section});

  final AdFormSectionContext section;

  @override
  Widget build(BuildContext context) {
    final fields = section.fields;
    final ad = section.state.ad;
    final textTheme = Theme.of(context).textTheme;
    final price = FieldValidators.parseDecimal(fields.price.text);
    final missing = ad?.missingFields ?? const [];

    final rows = [
      ('Título', fields.title.text.trim()),
      ('Categoria', section.category?.name ?? '—'),
      ('Preço', price == null ? '—' : formatCurrency(double.parse(price))),
      ('Estoque', fields.stock.text.trim()),
      ('Fotos', '${ad?.images.length ?? 0}'),
      ('Opções de envio', '${fields.shippingOptions.length}'),
    ];

    return _SectionColumn(
      children: [
        for (final (label, value) in rows)
          Row(
            children: [
              Expanded(child: Text(label, style: textTheme.bodySmall)),
              Flexible(
                child: Text(
                  value.isEmpty ? '—' : value,
                  textAlign: TextAlign.end,
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        const Divider(),
        if (ad == null)
          const _Hint('Salve o rascunho para conferir o que falta.')
        else if (missing.isEmpty)
          const _Hint(
            'Tudo pronto. As alterações ainda não salvas serão '
            'enviadas junto.',
          )
        else
          Container(
            color: AppColors.warningBackgroundColor,
            padding: const EdgeInsets.all(12),
            child: Text(
              'Falta preencher: ${missing.map(adFieldLabel).join(', ')}. '
              '(conferido no último salvamento)',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.warningColor,
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionColumn extends StatelessWidget {
  const _SectionColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16.0,
      children: children,
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.tertiaryColor),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      value: value,
      activeThumbColor: AppColors.primaryColor,
      onChanged: onChanged,
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final Map<String, String> items;
  final Set<String> selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        for (final MapEntry(key: id, value: name) in items.entries)
          FilterChip(
            label: Text(
              name,
              style: selected.contains(id)
                  ? textTheme.bodySmall?.copyWith(color: Colors.white)
                  : textTheme.bodySmall,
            ),
            selectedColor: AppColors.primaryColor,
            checkmarkColor: Colors.white,
            selected: selected.contains(id),
            onSelected: (value) {
              value ? selected.add(id) : selected.remove(id);
              onChanged();
            },
          ),
      ],
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.forceErrorText,
    this.allowEmpty = false,
  });

  final String label;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;
  final String? forceErrorText;

  final bool allowEmpty;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Text(label, style: textTheme.bodyMedium)),
        DropdownButtonFormField<T>(
          initialValue: items.containsKey(value) ? value : null,
          isExpanded: true,
          validator: validator,
          forceErrorText: forceErrorText,
          style: textTheme.bodyMedium,
          decoration: const InputDecoration(
            filled: true,
            fillColor: AppColors.secondaryColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide.none,
            ),
          ),
          hint: Text(label, style: textTheme.bodyMedium),
          items: [
            if (allowEmpty)
              DropdownMenuItem<T>(
                value: null,
                child: Text('Não informado', style: textTheme.bodyMedium),
              ),
            for (final MapEntry(:key, :value) in items.entries)
              DropdownMenuItem<T>(
                value: key,
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
