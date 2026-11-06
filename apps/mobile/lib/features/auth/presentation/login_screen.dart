import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/customer.dart';
import '../state/session_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    _formKey.currentState!.validate(); // Menampilkan pesan di form.
    // login memvalidasi ulang dan mencatat penolakan ke log keamanan.
    ref
        .read(sessionProvider.notifier)
        .login(name: _name.text, email: _email.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'DONBURI X',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masuk untuk meracik bowl dan menyimpan riwayat pesanan.',
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const Key('login-name'),
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Nama'),
                      validator: Customer.validateName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('login-email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: Customer.validateEmail,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('login-submit'),
                      onPressed: _submit,
                      child: const Text('Masuk'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Akun lokal tanpa kata sandi (simulasi autentikasi). '
                      'Data tersimpan di perangkat ini.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
