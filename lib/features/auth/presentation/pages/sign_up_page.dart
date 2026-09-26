import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/common/components/form/shoe_text_form_field.dart';
import 'package:solado_certo_app/common/components/shoe_button.dart';
import 'package:solado_certo_app/common/components/shoe_hypertext.dart';
import 'package:solado_certo_app/config/theme/app_colors.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';

class SignUpPage extends StatelessWidget {
  SignUpPage({super.key});

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authBloc = BlocProvider.of<AuthBloc>(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (BuildContext context, state) {
        if (state is AuthSignUpSuccess) {
          Navigator.of(context).pop();
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
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Column(
                          spacing: 16.0,
                          children: [
                            ShoeTextFormField(
                              labelText: 'Nome'.toUpperCase(),
                              hintText: 'João Guilherme',
                              controller: _nameController,
                            ),
                            ShoeTextFormField(
                              labelText: 'Sobrenome'.toUpperCase(),
                              hintText: 'da Silva',
                              controller: _surnameController,
                            ),
                            ShoeTextFormField(
                              labelText: 'Email'.toUpperCase(),
                              hintText: 'joao.silva@example.com',
                              controller: _emailController,
                            ),
                            ShoeTextFormField(
                              labelText: 'Telefone'.toUpperCase(),
                              hintText: '(19) 99999-9999',
                              controller: _phoneController,
                            ),
                            ShoeTextFormField(
                              labelText: 'Senha'.toUpperCase(),
                              hintText: '********',
                              obscureText: true,
                              controller: _passwordController,
                            ),
                            ShoeButton(
                              text: 'Criar Conta'.toUpperCase(),
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: Colors.white),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  authBloc.add(
                                    SignUpEvent(
                                      name:
                                          '${_nameController.text} ${_surnameController.text}',
                                      email: _emailController.text,
                                      phone: _phoneController.text,
                                      password: _passwordController.text,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
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
            ),
          ],
        ),
      ),
    );
  }
}
