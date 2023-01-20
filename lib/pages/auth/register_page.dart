import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:silab/extensions/buildcontext/loc.dart';
import 'package:silab/services/auth/auth_exceptions.dart';
import 'package:silab/services/auth/bloc/auth_bloc.dart';
import 'package:silab/utilities/dialogs/error_dialog.dart';

enum Role { lecture, student }

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late TextEditingController _uniqueNumberController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  String? selectedRole;
  final List<String> _roleItems = ['Dosen', 'Mahasiswa'];

  void _onChangeRole(String? value) {
    setState(() {
      selectedRole = value;
    });
  }

  void _onRegisterEvent() {
    final role = selectedRole?.toLowerCase();
    final uniqueNumber = _uniqueNumberController.text;
    final email = _emailController.text;
    final password = _passwordController.text;

    context.read<AuthBloc>().add(AuthEventRegister(
          role: role,
          uniqueNumber: uniqueNumber,
          email: email,
          password: password,
        ));
  }

  @override
  void initState() {
    _uniqueNumberController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _uniqueNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: registerListener,
      child: Scaffold(
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ListView(
            padding: const EdgeInsets.only(top: 60.0),
            children: [
              Image.asset(
                'assets/images/logo-silab-cropped.png',
                height: 150,
              ),
              const Text(
                'Silab UAI',
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 15.0),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: DropdownButton<String>(
                  value: selectedRole,
                  hint: const Text('Pilih Role'),
                  items: _roleItems
                      .map((e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  onChanged: _onChangeRole,
                ),
              ),
              const SizedBox(height: 60.0),
              uniqueNumberField,
              emailField,
              passwordField,
              const SizedBox(
                height: 10.0,
              ),
              registerButton,
              SizedBox(
                height: MediaQuery.of(context).size.height * .03,
              ),
              _buildLoginText(context)
            ],
          ),
        ),
      ),
    );
  }

  void registerListener(context, state) async {
    if (state is AuthStateRegistering) {
      if (state.exception is WeakPasswordAuthException) {
        await showErrorDialog(
          context,
          context.loc.register_error_weak_password,
        );
      } else if (state.exception is EmailAlreadyInUseAuthException) {
        await showErrorDialog(
          context,
          'Email yang anda gunakan sudah terdaftar',
        );
      } else if (state.exception is GenericAuthException) {
        await showErrorDialog(
          context,
          context.loc.register_error_generic,
        );
      } else if (state.exception is InvalidEmailAuthException) {
        await showErrorDialog(
          context,
          context.loc.register_error_invalid_email,
        );
      }
    }
  }

  Widget _buildLoginText(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: ThemeData.light().textTheme.bodyMedium,
        children: [
          const TextSpan(text: 'Sudah daftar? '),
          TextSpan(
            text: 'Silahkan login disini',
            style: const TextStyle(
              color: Colors.blueAccent,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                context.read<AuthBloc>().add(AuthEventLogout());
              },
          ),
        ],
      ),
    );
  }

  Widget get registerButton {
    return ElevatedButton(
      onPressed: selectedRole == null ? null : _onRegisterEvent,
      child: const Text('Daftar'),
    );
  }

  Widget get passwordField {
    return TextField(
      controller: _passwordController,
      obscureText: true,
      decoration: const InputDecoration(
        hintText: 'Masukkan kata sandi',
      ),
    );
  }

  Widget get emailField {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      decoration: const InputDecoration(
        hintText: 'Masukkan email',
      ),
    );
  }

  Widget get uniqueNumberField {
    return TextField(
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      controller: _uniqueNumberController,
      decoration: const InputDecoration(
        hintText: 'Masukkan Nomor Identitas',
      ),
    );
  }
}
