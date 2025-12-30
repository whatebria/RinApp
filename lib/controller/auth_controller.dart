import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends ChangeNotifier {
  AuthController({required SupabaseClient sb}) : _sb = sb;

  final SupabaseClient _sb;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  User? get user => _sb.auth.currentUser;

  Future<void> signUp({required String email, required String password}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _sb.auth.signUp(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _sb.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    // Sign out es rápido, pero igual manejamos loading por consistencia.
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _sb.auth.signOut();
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Para refrescar UI cuando cambia la sesión por fuera (deep links, refresh token, etc.)
  void notifySessionChanged() => notifyListeners();
}
