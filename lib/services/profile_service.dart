import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  UserProfile({
    required this.id,
    required this.displayName,
    required this.friendCode,
  });

  final String id;
  final String displayName;
  final String friendCode;

  factory UserProfile.fromMap(Map<String, dynamic> m) {
    return UserProfile(
      id: m['id'] as String,
      displayName: (m['display_name'] as String?) ?? '',
      friendCode: (m['friend_code'] as String?) ?? '',
    );
  }
}

class ProfileService {
  SupabaseClient get _sb => Supabase.instance.client;

  // 1) Genera un código corto tipo ABC-7K2Q
  String _generateFriendCode() {
    const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final r = Random.secure();

    final prefix = List.generate(
      3,
      (_) => letters[r.nextInt(letters.length)],
    ).join();
    final suffix = List.generate(
      4,
      (_) => chars[r.nextInt(chars.length)],
    ).join();
    return "$prefix-$suffix";
  }

  // 2) Crea perfil si no existe, y lo devuelve
  Future<UserProfile> ensureMyProfile({String displayName = ''}) async {
    final user = _sb.auth.currentUser;
    if (user == null) throw Exception("No estás logueado");

    // A) Intento leer mi perfil
    final existing = await _sb
        .from('profiles')
        .select('id,display_name,friend_code')
        .eq('id', user.id)
        .maybeSingle();

    // A1) Si existe, lo devolvemos (pero asegurando friend_code)
    if (existing != null) {
      final p = UserProfile.fromMap(existing);

      // Si falta friend_code, lo asignamos (update)
      if (p.friendCode.trim().isEmpty) {
        final updated = await _ensureFriendCodeForExisting(
          userId: user.id,
          currentDisplayName: p.displayName,
          newDisplayName: displayName,
        );
        return updated;
      }

      // Si ya tiene friend_code, listo
      // (Opcional: si te pasaron displayName y quieres actualizarlo, podrías hacerlo acá)
      return p;
    }

    // B) Si NO existe, lo creamos (insert) + friend_code único
    for (int attempt = 0; attempt < 5; attempt++) {
      final code = _generateFriendCode();
      try {
        final inserted = await _sb
            .from('profiles')
            .insert({
              'id': user.id,
              'display_name': displayName,
              'friend_code': code,
            })
            .select('id,display_name,friend_code')
            .single();

        return UserProfile.fromMap(inserted);
      } catch (e) {
        // Si chocó el unique de friend_code, reintenta
        if (attempt == 4) rethrow;
      }
    }

    throw Exception("No se pudo crear el perfil");
  }

  Future<UserProfile> _ensureFriendCodeForExisting({
    required String userId,
    required String currentDisplayName,
    required String newDisplayName,
  }) async {
    for (int attempt = 0; attempt < 5; attempt++) {
      final code = _generateFriendCode();
      try {
        final updated = await _sb
            .from('profiles')
            .update({
              'friend_code': code,
              'display_name': newDisplayName.isEmpty
                  ? currentDisplayName
                  : newDisplayName,
            })
            .eq('id', userId)
            .select('id,display_name,friend_code')
            .single();

        return UserProfile.fromMap(updated);
      } catch (e) {
        if (attempt == 4) rethrow;
      }
    }

    throw Exception("No se pudo asignar friend_code");
  }

  Future<UserProfile?> findByFriendCode(String code) async {
    final user = _sb.auth.currentUser;
    if (user == null) throw Exception("No estás logueado");

    final normalized = code.trim().toUpperCase();

    final data = await _sb
        .from('profiles')
        .select('id,display_name,friend_code')
        .eq('friend_code', normalized)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromMap(data);
  }

  Future<UserProfile?> getByUserId(String userId) async {
    final data = await _sb
        .from('profiles')
        .select('id,display_name,friend_code')
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromMap(data);
  }

  Future<Map<String, UserProfile>> getByUserIds(List<String> userIds) async {
    if (userIds.isEmpty) return {};

    final data = await _sb
        .from('profiles')
        .select('id,display_name,friend_code')
        .inFilter('id', userIds);

    final rows = (data as List).cast<Map<String, dynamic>>();

    final map = <String, UserProfile>{};
    for (final r in rows) {
      final p = UserProfile.fromMap(r);
      map[p.id] = p;
    }

    return map;
  }
}
