import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  SupabaseClient get _sb => Supabase.instance.client;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _sb.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _sb.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await _sb.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = _sb.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Auth (Supabase)")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: user == null ? _loggedOutUi() : _loggedInUi(user.id),
      ),
    );
  }

  Widget _loggedOutUi() {
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

        if (_error != null) ...[
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 12),
        ],

        FilledButton(
          onPressed: _loading ? null : _signUp,
          child: _loading ? const Text("...") : const Text("Registrarse"),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _loading ? null : _signIn,
          child: const Text("Iniciar sesión"),
        ),
      ],
    );
  }

  Widget _loggedInUi(String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("✅ Logueado"),
        const SizedBox(height: 8),
        Text("User ID:\n$uid"),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _signOut,
          child: const Text("Cerrar sesión"),
        ),
      ],
    );
  }
}
