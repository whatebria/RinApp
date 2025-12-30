import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rin/controller/auth_controller.dart';
import 'package:rin/providers/auth_provider.dart';


class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthProvider(
      child: _AuthView(),
    );
  }
}

class _AuthView extends StatefulWidget {
  const _AuthView();

  @override
  State<_AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<_AuthView> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AuthController>();
    final user = c.user;

    return Scaffold(
      appBar: AppBar(title: const Text("Auth (Supabase)")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: user == null ? _loggedOutUi(context, c) : _loggedInUi(context, c, user.id),
      ),
    );
  }

  Widget _loggedOutUi(BuildContext context, AuthController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: "Email"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Password"),
        ),
        const SizedBox(height: 16),

        if (c.error != null) ...[
          Text(
            c.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],

        FilledButton(
          onPressed: c.loading
              ? null
              : () => context.read<AuthController>().signUp(
                    email: _emailCtrl.text,
                    password: _passCtrl.text,
                  ),
          child: Text(c.loading ? "..." : "Registrarse"),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: c.loading
              ? null
              : () => context.read<AuthController>().signIn(
                    email: _emailCtrl.text,
                    password: _passCtrl.text,
                  ),
          child: const Text("Iniciar sesión"),
        ),
      ],
    );
  }

  Widget _loggedInUi(BuildContext context, AuthController c, String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("✅ Logueado"),
        const SizedBox(height: 8),
        Text("User ID:\n$uid"),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: c.loading ? null : () => context.read<AuthController>().signOut(),
          child: const Text("Cerrar sesión"),
        ),
      ],
    );
  }
}
