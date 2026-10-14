import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/image_picking.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/catalog/domain/usecases/get_catalog_filter_options_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/entities/ad_draft.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_field.dart';
import 'package:solado_certo_app/features/seller/domain/enum/ad_form_step.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/ad_images_use_cases.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/change_ad_status_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/get_ad_use_case.dart';
import 'package:solado_certo_app/features/seller/domain/usecases/save_ad_use_case.dart';
import 'package:solado_certo_app/features/seller/presentation/bloc/ad_form_bloc.dart';
import 'package:solado_certo_app/features/seller/presentation/components/ad_form_fields.dart';
import 'package:solado_certo_app/features/seller/presentation/components/ad_form_sections.dart';

/// Creates an ad (without [adId]) or edits one, in steps (UC-003).
class AdFormPage extends StatefulWidget {
  const AdFormPage({super.key, this.pickPhoto});

  final Future<UploadFile?> Function()? pickPhoto;

  static Route<void> route({String? adId}) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => AdFormBloc(
          adId: adId,
          getOptionsUseCase: getIt<GetCatalogFilterOptionsUseCase>(),
          getAdUseCase: getIt<GetAdUseCase>(),
          saveAdUseCase: getIt<SaveAdUseCase>(),
          changeAdStatusUseCase: getIt<ChangeAdStatusUseCase>(),
          addImageUseCase: getIt<AddAdImageUseCase>(),
          removeImageUseCase: getIt<RemoveAdImageUseCase>(),
          reorderImagesUseCase: getIt<ReorderAdImagesUseCase>(),
        )..add(LoadAdFormEvent()),
        child: const AdFormPage(),
      ),
    );
  }

  @override
  State<AdFormPage> createState() => _AdFormPageState();
}

class _AdFormPageState extends State<AdFormPage> {
  AdFormFields? _fields;
  final _formKeys = {
    for (final step in AdFormStep.values) step: GlobalKey<FormState>(),
  };

  @override
  void dispose() {
    _fields?.dispose();
    super.dispose();
  }

  AdFormBloc get _bloc => context.read<AdFormBloc>();

  bool _validate(AdFormStep step) =>
      _formKeys[step]!.currentState?.validate() ?? true;

  /// Validates every step and opens the first invalid one.
  bool _validateAll() {
    for (final step in AdFormStep.values) {
      if (!_validate(step)) {
        _goTo(step, validateCurrent: false);
        return false;
      }
    }
    return true;
  }

  /// Leaving a step checks its formats; reaching the photos of a new ad
  /// saves it first, which needs the general data.
  void _goTo(AdFormStep step, {bool validateCurrent = true}) {
    final state = _bloc.state;
    if (step == state.step) return;
    if (validateCurrent && step.index > state.step.index) {
      if (!_validate(state.step)) return;
    }
    if (step.needsSavedAd && state.isNew && !_validate(AdFormStep.general)) {
      _bloc.add(GoToStepEvent(step: AdFormStep.general, draft: _draft));
      return;
    }
    _bloc.add(GoToStepEvent(step: step, draft: _draft));
  }

  AdDraft get _draft => _fields!.toDraft();

  void _save() {
    if (_validateAll()) _bloc.add(SaveAdEvent(draft: _draft));
  }

  void _publish() {
    if (_validateAll()) _bloc.add(PublishAdEvent(draft: _draft));
  }

  Future<void> _addPhoto() async {
    final bloc = _bloc;
    final photo = await (widget.pickPhoto ?? pickImageFromGallery)();
    if (photo != null) bloc.add(AddImageEvent(photo: photo));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<AdFormBloc, AdFormState>(
      listener: _onStateChanged,
      builder: (context, state) {
        if (state.status == AdFormStatus.ready) {
          _fields ??= AdFormFields.from(state.ad);
        }

        return Scaffold(
          appBar: AppBar(
            iconTheme: Theme.of(context).iconTheme,
            title: Text(
              (state.ad == null ? 'Novo anúncio' : 'Editar anúncio')
                  .toUpperCase(),
              style: textTheme.bodyMedium,
            ),
            actions: [
              if (state.status == AdFormStatus.ready)
                TextButton(
                  onPressed: state.isBusy ? null : _save,
                  child: Text(
                    state.canPublish ? 'Salvar rascunho' : 'Salvar',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          body: switch (state.status) {
            AdFormStatus.ready => _buildForm(state),
            AdFormStatus.loadFailure => _LoadError(failure: state.failure!),
            AdFormStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
          },
          bottomNavigationBar: state.status == AdFormStatus.ready
              ? _buildBottomBar(state)
              : null,
        );
      },
    );
  }

  void _onStateChanged(BuildContext context, AdFormState state) {
    final failure = state.failure;
    if (failure is UnauthorizedFailure) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      context.read<AuthBloc>().add(SignOutEvent());
      return;
    }
    if (state.isFinished) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.notice ?? 'Anúncio publicado.')),
      );
      Navigator.of(context).pop();
      return;
    }
    // After a save the shipping options have ids; keep them for the next one.
    final saved = state.ad;
    if (saved != null && state.failure == null && _fields != null) {
      if (state.notice != null) {
        setState(() => _fields!.syncShippingOptions(saved.shippingOptions));
      }
    }
    final message = switch (failure) {
      null => state.notice,
      MissingFieldsFailure(:final fields) when fields.isNotEmpty =>
        '${failure.message} Falta: ${fields.map(adFieldLabel).join(', ')}.',
      _ => failure.message,
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _buildForm(AdFormState state) {
    final section = AdFormSectionContext(
      fields: _fields!,
      state: state,
      onChanged: () => setState(() {}),
    );

    return Column(
      children: [
        _StepHeader(
          current: state.step,
          withMissing: {
            for (final step in AdFormStep.values)
              if (state.highlightedFields.any(step.fields.contains)) step,
          },
          enabled: !state.isBusy,
          onSelected: _goTo,
        ),
        if (state.isBusy) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: IndexedStack(
            index: state.step.index,
            children: [
              for (final step in AdFormStep.values)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKeys[step],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: switch (step) {
                      AdFormStep.general => AdGeneralSection(section: section),
                      AdFormStep.attributes => AdAttributesSection(
                        section: section,
                      ),
                      AdFormStep.purposes => AdPurposesSection(
                        section: section,
                      ),
                      AdFormStep.photos => AdPhotosSection(
                        section: section,
                        onAdd: _addPhoto,
                        onRemove: (image) =>
                            _bloc.add(RemoveImageEvent(imageId: image.id)),
                        onMove: (image, offset) => _bloc.add(
                          MoveImageEvent(imageId: image.id, offset: offset),
                        ),
                        onSetCover: (image) =>
                            _bloc.add(SetCoverImageEvent(imageId: image.id)),
                      ),
                      AdFormStep.shipping => AdShippingSection(
                        section: section,
                      ),
                      AdFormStep.review => AdReviewSection(section: section),
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(AdFormState state) {
    final step = state.step;
    final isLast = step == AdFormStep.review;
    final buttonStyle = Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(color: Colors.white);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          spacing: 12.0,
          children: [
            if (step.index > 0)
              TextButton(
                onPressed: state.isBusy
                    ? null
                    : () => _goTo(AdFormStep.values[step.index - 1]),
                child: const Text('Voltar'),
              ),
            Expanded(
              child: isLast
                  ? ShoeTextButton(
                      isLoading: state.isBusy,
                      onPressed: state.canPublish ? _publish : _save,
                      text: state.canPublish ? 'Publicar' : 'Salvar alterações',
                      textStyle: buttonStyle,
                    )
                  : ShoeTextButton(
                      isLoading: state.activity == AdFormActivity.saving,
                      onPressed: state.isBusy
                          ? null
                          : () => _goTo(AdFormStep.values[step.index + 1]),
                      text: 'Próximo',
                      textStyle: buttonStyle,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.current,
    required this.withMissing,
    required this.enabled,
    required this.onSelected,
  });

  final AdFormStep current;
  final Set<AdFormStep> withMissing;
  final bool enabled;
  final ValueChanged<AdFormStep> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        spacing: 8.0,
        children: [
          for (final step in AdFormStep.values)
            ChoiceChip(
              avatar: withMissing.contains(step)
                  ? const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.warningColor,
                    )
                  : null,
              label: Text(
                '${step.index + 1}. ${step.label}',
                style: step == current
                    ? textTheme.bodySmall?.copyWith(color: Colors.white)
                    : textTheme.bodySmall,
              ),
              showCheckmark: false,
              selectedColor: AppColors.primaryColor,
              selected: step == current,
              onSelected: enabled ? (_) => onSelected(step) : null,
            ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16.0,
          children: [
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            ShoeTextButton(
              onPressed: () =>
                  context.read<AdFormBloc>().add(LoadAdFormEvent()),
              text: 'Tentar novamente',
              textStyle: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
