import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/product_detail.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/usecases/custom_order_use_cases.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/custom_order_form_cubit.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/components/custom_order_consent_dialog.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/components/foot_photo_source_sheet.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/components/measurements_fields.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/pages/custom_order_detail_page.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/grant_custom_order_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_custom_order_consent_use_case.dart';

class CustomOrderRequestPage extends StatefulWidget {
  const CustomOrderRequestPage({
    super.key,
    required this.product,
    this.askConsent = askCustomOrderConsent,
    this.pickPhoto = pickFootPhoto,
    this.openDetail = _openDetail,
  });

  final ProductDetailEntity product;
  final Future<bool> Function(BuildContext context) askConsent;
  final Future<UploadFile?> Function(BuildContext context) pickPhoto;
  final void Function(BuildContext context, CustomOrderDetailEntity detail)
  openDetail;

  static void _openDetail(
    BuildContext context,
    CustomOrderDetailEntity detail,
  ) => Navigator.of(
    context,
  ).pushReplacement(CustomOrderDetailPage.route(detail.request.id));

  static Route<void> route(ProductDetailEntity product) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => CustomOrderFormCubit(
          createCustomOrderUseCase: getIt<CreateCustomOrderUseCase>(),
          sendFootPhotoUseCase: getIt<SendFootPhotoUseCase>(),
          hasConsentUseCase: getIt<HasCustomOrderConsentUseCase>(),
          grantConsentUseCase: getIt<GrantCustomOrderConsentUseCase>(),
        ),
        child: CustomOrderRequestPage(product: product),
      ),
    );
  }

  @override
  State<CustomOrderRequestPage> createState() => _CustomOrderRequestPageState();
}

class _CustomOrderRequestPageState extends State<CustomOrderRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _measurements = MeasurementsController();
  final _notes = TextEditingController();
  UploadFile? _photo;

  @override
  void dispose() {
    _measurements.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    final photo = await widget.pickPhoto(context);
    if (photo != null && mounted) setState(() => _photo = photo);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<CustomOrderFormCubit>();
    final consented = await cubit.hasConsent();
    if (consented == null || !mounted) return;
    if (!consented) {
      if (!await widget.askConsent(context)) return;
      if (!await cubit.grantConsent()) return;
    }
    final notes = _notes.text.trim();
    await cubit.submit(
      NewCustomOrder(
        advertisementId: widget.product.id,
        measurements: _measurements.read(),
        technicalNotes: notes.isEmpty ? null : notes,
      ),
      photo: _photo,
    );
  }

  void _onStateChanged(BuildContext context, CustomOrderFormState state) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (state.failure is UnauthorizedFailure ||
        state.photoFailure is UnauthorizedFailure) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      context.read<AuthBloc>().add(SignOutEvent());
      return;
    }
    if (state.created case final created?) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (state.photoFailure) {
            final failure? =>
              'Solicitação enviada, mas a foto não: ${failure.message}',
            null => 'Solicitação enviada ao vendedor.',
          }),
        ),
      );
      widget.openDetail(context, created);
      return;
    }
    if (state.failure case final failure?) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<CustomOrderFormCubit, CustomOrderFormState>(
      listenWhen: (_, current) =>
          current.failure != null || current.created != null,
      listener: _onStateChanged,
      builder: (context, state) {
        final busy = state.submitting || state.created != null;

        return Scaffold(
          appBar: AppBar(
            iconTheme: Theme.of(context).iconTheme,
            title: Text(
              'Sob medida'.toUpperCase(),
              style: textTheme.bodyMedium,
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(widget.product.title, style: textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  'Informe as medidas dos seus pés. O vendedor analisa, pode '
                  'pedir mais informações e, se aceitar, informa o preço. '
                  'Você só paga depois de confirmar.',
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                const MeasuringGuide(),
                const SizedBox(height: 16),
                MeasurementsFields(controller: _measurements, enabled: !busy),
                const SizedBox(height: 16),
                ShoeTextFormField(
                  labelText: 'Observações técnicas (opcional)',
                  hintText: 'Ex.: dor no calcanhar, uso diário em tênis',
                  controller: _notes,
                  readOnly: busy,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  validator: FieldValidators.maxLength(
                    NewCustomOrder.maxNotesLength,
                  ),
                ),
                const SizedBox(height: 16),
                _PhotoPicker(
                  photo: _photo,
                  onPick: busy ? null : _choosePhoto,
                  onRemove: busy ? null : () => setState(() => _photo = null),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: ShoeTextButton(
                onPressed: busy ? null : _submit,
                isLoading: state.submitting,
                text: 'Enviar solicitação',
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photo,
    required this.onPick,
    required this.onRemove,
  });

  final UploadFile? photo;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final photo = this.photo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8.0,
      children: [
        Text('Foto do pé (opcional)', style: textTheme.bodyMedium),
        Text(
          'Ajuda o vendedor a ver o formato do pé. Só ele e você têm acesso.',
          style: textTheme.bodySmall,
        ),
        if (photo != null)
          Row(
            spacing: 12.0,
            children: [
              SizedBox.square(
                dimension: 72,
                child: Image.memory(
                  Uint8List.fromList(photo.bytes),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.image_outlined),
                ),
              ),
              Expanded(
                child: Text(
                  photo.filename,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
              ),
              IconButton(
                tooltip: 'Remover foto',
                onPressed: onRemove,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: onPick,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(photo == null ? 'Adicionar foto' : 'Trocar foto'),
          ),
        ),
      ],
    );
  }
}
