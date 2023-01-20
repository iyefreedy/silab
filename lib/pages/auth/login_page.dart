import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:silab/extensions/buildcontext/loc.dart';
import 'package:silab/services/auth/auth_exceptions.dart';
import 'package:silab/services/auth/bloc/auth_bloc.dart';
import 'package:silab/utilities/dialogs/error_dialog.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();

    _emailController.dispose();
    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthStateLoggedOut) {
          if (state.exception is UserNotFoundAuthException) {
            await showErrorDialog(
              context,
              context.loc.login_error_cannot_find_user,
            );
          } else if (state.exception is WrongPasswordAuthException) {
            await showErrorDialog(
              context,
              context.loc.login_error_wrong_credentials,
            );
          } else if (state.exception is GenericAuthException) {
            await showErrorDialog(
              context,
              context.loc.login_error_auth_error,
            );
          }
        }
      },
      child: Scaffold(
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ListView(
            padding: const EdgeInsets.only(top: 60.0),
            children: [
              Image.asset(
                'assets/images/logo-silab-cropped.png',
                height: 200,
              ),
              const Text(
                'SILab UAI',
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: null,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email),
                  hintText: 'Masukkan email',
                ),
              ),
              PasswordField(
                controller: _passwordController,
              ),
              const SizedBox(
                height: 10.0,
              ),
              ElevatedButton(
                onPressed: () {
                  final email = _emailController.text;
                  final password = _passwordController.text;
                  context.read<AuthBloc>().add(AuthEventLogin(
                        email: email,
                        password: password,
                      ));
                },
                child: const Text('Login'),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * .03,
              ),
              RichText(
                text: TextSpan(
                  style: ThemeData.light().textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'Belum daftar? '),
                    TextSpan(
                      text: 'Silahkan daftar disini',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          context
                              .read<AuthBloc>()
                              .add(AuthEventShouldRegister());
                        },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final TextEditingController controller;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  late final TextEditingController _controller = widget.controller;

  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      obscureText: !_isVisible,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.password),
        hintText: 'Masukkan kata sandi',
        suffixIcon: InkWell(
          onTap: () {
            setState(() {
              _isVisible = !_isVisible;
            });
          },
          child: _isVisible
              ? const Icon(Icons.visibility_off)
              : const Icon(Icons.visibility),
        ),
      ),
    );
  }
}
