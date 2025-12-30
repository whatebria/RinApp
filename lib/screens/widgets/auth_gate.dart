import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rin/controller/profile_controller.dart';
import 'package:rin/screens/auth/auth_screen.dart';
import 'package:rin/screens/home_screen.dart';
import 'package:rin/screens/profile/profile_setup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _sub;

  bool _deciding = true;
  Widget? _target;
  String? _error;

  @override
  void initState() {
    super.initState();

    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _decide();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<void> _decide() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (!mounted) return;
    setState(() {
      _deciding = true;
      _target = null;
      _error = null;
    });

    if (session == null) {
      setState(() {
        _deciding = false;
        _target = const AuthScreen();
      });
      return;
    }

    try {
      final c = context.read<ProfileController>();
      await c.ensureAndLoad();
      final p = c.profile;
      if (!mounted) return;

      if (p == null) {
        setState(() {
          _deciding = false;
          _error = c.error ?? 'No se pudo cargar profile';
        });
        return;
      }

      setState(() {
        _deciding = false;
        _target = p.isComplete ? const HomeScreen() : const ProfileSetupScreen();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deciding = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_deciding) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(body: Center(child: Text('Error: $_error')));
    }

    return _target ?? const AuthScreen();
  }
}
