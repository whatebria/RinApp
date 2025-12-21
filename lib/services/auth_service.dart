import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _sb => Supabase.instance.client;

  String? get currentUserId => _sb.auth.currentUser?.id;
  bool get isSignedIn => _sb.auth.currentSession != null;

  Future<void> signOut() async {
    await _sb.auth.signOut();
  }

  // (Opcional) Para que quede completo:
  Future<void> signIn(String email, String password) async {
    await _sb.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _sb.auth.signUp(email: email, password: password);
  }
}
