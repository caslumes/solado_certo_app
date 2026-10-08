import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_hypertext.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      SignUpEvent(
        name: '${_nameController.text.trim()} ${_surnameController.text.trim()}'
            .trim(),
        email: _emailController.text.trim().toLowerCase(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (BuildContext context, state) {
        if (state is AuthSignUpSuccess) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Conta criada! Entre com seu e-mail e senha.'),
              ),
            );
          Navigator.of(context).pop();
        }
        if (state is AuthUnauthenticated &&
            state.failure != null &&
            state.failure is! AccountAlreadyExistsFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.failure!.message)));
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 15.0),
                      child: Image(
                        image: AssetImage('assets/images/logo.png'),
                        width: MediaQuery.of(context).size.width * 0.2,
                      ),
                    ),
                    Container(color: AppColors.primaryColor, height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          'Cadastro'.toUpperCase(),
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: AutofillGroup(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: Column(
                            spacing: 16.0,
                            children: [
                              ShoeTextFormField(
                                labelText: 'Nome'.toUpperCase(),
                                hintText: 'João Guilherme',
                                controller: _nameController,
                                validator: FieldValidators.combine([
                                  FieldValidators.required,
                                  FieldValidators.maxLength(120),
                                ]),
                                textCapitalization: TextCapitalization.words,
                                autofillHints: const [AutofillHints.givenName],
                              ),
                              ShoeTextFormField(
                                labelText: 'Sobrenome'.toUpperCase(),
                                hintText: 'da Silva',
                                controller: _surnameController,
                                validator: FieldValidators.maxLength(120),
                                textCapitalization: TextCapitalization.words,
                                autofillHints: const [AutofillHints.familyName],
                              ),
                              ShoeTextFormField(
                                labelText: 'Email'.toUpperCase(),
                                hintText: 'joao.silva@example.com',
                                controller: _emailController,
                                validator: FieldValidators.email,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                              ),
                              ShoeTextFormField(
                                labelText: 'Telefone'.toUpperCase(),
                                hintText: '(19) 99999-9999',
                                controller: _phoneController,
                                validator: FieldValidators.phone,
                                keyboardType: TextInputType.phone,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                              ),
                              ShoeTextFormField(
                                labelText: 'Senha'.toUpperCase(),
                                hintText: '********',
                                obscureText: true,
                                controller: _passwordController,
                                validator: FieldValidators.password,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  final failure = state is AuthUnauthenticated
                                      ? state.failure
                                      : null;
                                  if (failure is! AccountAlreadyExistsFailure) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    failure.message,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) => SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ShoeTextButton(
                  isLoading: state is AuthLoading,
                  text: 'Criar Conta'.toUpperCase(),
                  textStyle: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  onPressed: _submit,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 16.0, 0, 16.0),
              child: Column(
                children: [
                  Text('Já tem uma conta?'),
                  ShoeHypertext(
                    text: 'Entrar'.toUpperCase(),
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
