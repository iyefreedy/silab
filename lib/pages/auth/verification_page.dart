import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:silab/extensions/buildcontext/loc.dart';
import 'package:silab/services/auth/bloc/auth_bloc.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({Key? key}) : super(key: key);

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              context.loc.verify_email_view_prompt,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(AuthEventSendEmailVerification());
              },
              child: const Text('Kirim Ulang'),
            ),
            TextButton(
              onPressed: () {
                context.read<AuthBloc>().add(AuthEventLogout());
              },
              child: const Text('Kembali'),
            )
          ],
        ),
      ),
    );
  }
}
