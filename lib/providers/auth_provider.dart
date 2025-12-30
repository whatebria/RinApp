import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controller/auth_controller.dart';

class AuthProvider extends StatefulWidget {
  const AuthProvider({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AuthProvider> createState() => _AuthProviderState();
}

class _AuthProviderState extends State<AuthProvider> {
  late final SupabaseClient _sb;
  late final AuthController _controller;
  late final StreamSubscription<AuthState> _sub;

  @override
  void initState() {
    super.initState();
    _sb = Supabase.instance.client;
    _controller = AuthController(sb: _sb);

    // Escuchar cambios de sesión para que la UI se actualice sin tener que “rebuild” por otros motivos.
    _sub = _sb.auth.onAuthStateChange.listen((_) {
      _controller.notifySessionChanged();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthController>.value(
      value: _controller,
      child: widget.child,
    );
  }
}
