import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/profile/domain/entities/new_address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/add_address_use_case.dart';
import 'package:solado_certo_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:solado_certo_app/features/profile/presentation/components/address_entry.dart';
import 'package:solado_certo_app/features/profile/presentation/components/podological_profile_form.dart';
import 'package:solado_certo_app/features/profile/presentation/pages/address_form_page.dart';

class MyProfilePage extends StatelessWidget {
  const MyProfilePage({super.key, this.addAddress});

  final Future<void> Function(NewAddress address)? addAddress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) =>
          current is ProfileLoaded &&
          (current.failure != null || current.notice != null),
      listener: (context, state) {
        state as ProfileLoaded;
        final failure = state.failure;
        if (failure is UnauthorizedFailure) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          context.read<AuthBloc>().add(SignOutEvent());
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(failure?.message ?? state.notice!.message)),
          );
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            iconTheme: Theme.of(context).iconTheme,
            title: Text(
              'Meu perfil'.toUpperCase(),
              style: textTheme.bodyMedium,
            ),
          ),
          body: switch (state) {
            ProfileLoaded() => _ProfileContent(
              state: state,
              addAddress: addAddress ?? getIt<AddAddressUseCase>().execute,
            ),
            ProfileLoadFailure(:final failure) => _LoadError(failure: failure),
            _ => const Center(child: CircularProgressIndicator()),
          },
        );
      },
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
                  context.read<ProfileBloc>().add(LoadProfileEvent()),
              text: 'Tentar novamente',
              textStyle: _buttonTextStyle(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.state, required this.addAddress});

  final ProfileLoaded state;
  final Future<void> Function(NewAddress address) addAddress;

  Future<void> _openAddressForm(BuildContext context) async {
    final profileBloc = context.read<ProfileBloc>();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddressFormPage(
          initialReceiver: state.data.profile.name,
          initialIsDefault: state.data.addresses.isEmpty,
          onSubmit: addAddress,
        ),
      ),
    );
    if (saved == true) profileBloc.add(AddressesChangedEvent());
  }

  Future<void> _confirmRevoke(BuildContext context) async {
    final profileBloc = context.read<ProfileBloc>();
    final textTheme = Theme.of(context).textTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Retirar consentimento?', style: textTheme.bodyMedium),
        content: Text(
          'Seu perfil podológico e seus pontos de dor serão excluídos. '
          'Você poderá preenchê-lo de novo depois, dando um novo '
          'consentimento.',
          style: textTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: textTheme.bodySmall),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Retirar e excluir',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) profileBloc.add(RevokePodologicalConsentEvent());
  }

  @override
  Widget build(BuildContext context) {
    final data = state.data;

    return SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16.0,
            children: [
              const SizedBox.shrink(),
              _SectionTitle('Dados pessoais'),
              _PersonalDataForm(
                key: ObjectKey(data.profile),
                profile: data.profile,
                isSaving: state.isSaving,
              ),
              _SectionTitle('Endereços'),
              for (final address in data.addresses)
                AddressEntry(address: address),
              ShoeTextButton(
                onPressed: state.isSaving
                    ? null
                    : () => _openAddressForm(context),
                text: 'Adicionar endereço',
                textStyle: _buttonTextStyle(context),
              ),
              _SectionTitle('Perfil podológico'),
              PodologicalProfileForm(
                key: ValueKey((
                  data.podologicalProfile,
                  data.hasPodologicalConsent,
                )),
                profile: data.podologicalProfile,
                painPoints: data.painPoints,
                hasConsent: data.hasPodologicalConsent,
                isSaving: state.isSaving,
                submitText: 'Salvar perfil podológico',
                onSubmit: (update) => context.read<ProfileBloc>().add(
                  SavePodologicalProfileEvent(update: update),
                ),
                trailingActions: [
                  if (data.hasPodologicalConsent)
                    ShoeTextButton(
                      onPressed: state.isSaving
                          ? null
                          : () => _confirmRevoke(context),
                      text: 'Retirar consentimento',
                      textStyle: _buttonTextStyle(context),
                    ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalDataForm extends StatefulWidget {
  const _PersonalDataForm({
    super.key,
    required this.profile,
    required this.isSaving,
  });

  final ProfileEntity profile;
  final bool isSaving;

  @override
  State<_PersonalDataForm> createState() => _PersonalDataFormState();
}

class _PersonalDataFormState extends State<_PersonalDataForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.profile.name);
  late final _emailController = TextEditingController(
    text: widget.profile.email,
  );
  late final _phoneController = TextEditingController(
    text: widget.profile.phone,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<ProfileBloc>().add(
      SavePersonalDataEvent(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        spacing: 16.0,
        children: [
          ShoeTextFormField(
            labelText: 'Nome',
            controller: _nameController,
            validator: FieldValidators.combine([
              FieldValidators.required,
              FieldValidators.maxLength(120),
            ]),
            textCapitalization: TextCapitalization.words,
          ),
          ShoeTextFormField(
            labelText: 'Email',
            controller: _emailController,
            readOnly: true,
          ),
          ShoeTextFormField(
            labelText: 'Telefone',
            controller: _phoneController,
            validator: FieldValidators.phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),
          ShoeTextButton(
            isLoading: widget.isSaving,
            onPressed: _submit,
            text: 'Salvar dados pessoais',
            textStyle: _buttonTextStyle(context),
          ),
        ],
      ),
    );
  }
}

TextStyle? _buttonTextStyle(BuildContext context) =>
    Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white);

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}
