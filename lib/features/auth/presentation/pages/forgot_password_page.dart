import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_hypertext.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/password_recovery_cubit.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _requestCode() {
    if (!_formKey.currentState!.validate()) return;
    context.read<PasswordRecoveryCubit>().requestCode(
      _emailController.text.trim().toLowerCase(),
    );
  }

  void _resetPassword() {
    if (!_formKey.currentState!.validate()) return;
    context.read<PasswordRecoveryCubit>().resetPassword(
      _codeController.text.trim(),
      _passwordController.text,
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onStateChanged(BuildContext context, PasswordRecoveryState state) {
    if (state.done) {
      _showMessage(context, 'Senha alterada! Entre com a nova senha.');
      Navigator.of(context).pop();
      return;
    }
    if (state.failure != null) {
      _showMessage(context, state.failure!.message);
      return;
    }
    if (state.resent) {
      _showMessage(
        context,
        'Se o e-mail estiver cadastrado, enviamos um novo código.',
      );
    }
  }

  Widget _submitButton(
    BuildContext context,
    PasswordRecoveryState state, {
    required String text,
    required VoidCallback onPressed,
  }) {
    return ShoeTextButton(
      isLoading: state.sending,
      onPressed: onPressed,
      text: text,
      textStyle: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(color: Colors.white),
    );
  }

  List<Widget> _emailStep(BuildContext context, PasswordRecoveryState state) {
    return [
      Text(
        'Informe o e-mail da sua conta para receber um código de recuperação.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      ShoeTextFormField(
        key: const ValueKey('recovery-email'),
        labelText: 'Email'.toUpperCase(),
        hintText: 'email@exemplo.com',
        controller: _emailController,
        validator: FieldValidators.email,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.email],
        onFieldSubmitted: (_) => _requestCode(),
      ),
      _submitButton(
        context,
        state,
        text: 'Enviar código',
        onPressed: _requestCode,
      ),
    ];
  }

  List<Widget> _codeStep(BuildContext context, PasswordRecoveryState state) {
    return [
      Text(
        'Se ${state.email} estiver cadastrado, enviamos um código de 6 dígitos. '
        'Ele vale por 15 minutos.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      ShoeTextFormField(
        key: const ValueKey('recovery-code'),
        labelText: 'Código'.toUpperCase(),
        hintText: '000000',
        controller: _codeController,
        validator: FieldValidators.resetCode,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
      ),
      ShoeTextFormField(
        key: const ValueKey('recovery-password'),
        labelText: 'Nova senha'.toUpperCase(),
        hintText: '********',
        obscureText: true,
        controller: _passwordController,
        validator: FieldValidators.password,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.newPassword],
        onFieldSubmitted: (_) => _resetPassword(),
      ),
      _submitButton(
        context,
        state,
        text: 'Alterar senha',
        onPressed: _resetPassword,
      ),
      ShoeHypertext(
        text: 'Reenviar código',
        onTap: () {
          context.read<PasswordRecoveryCubit>().requestCode(state.email!);
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: BlocConsumer<PasswordRecoveryCubit, PasswordRecoveryState>(
          listener: _onStateChanged,
          builder: (context, state) => Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: AutofillGroup(
              child: Column(
                spacing: 25,
                children: state.email == null
                    ? _emailStep(context, state)
                    : _codeStep(context, state),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
