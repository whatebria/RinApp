import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rin/data/repositories/profile_repository.dart';
import 'package:rin/models/profile_draft.dart';
import 'package:rin/models/user_profile.dart';

const _profileSelect = '''
id,display_name,friend_code,
avatar_url,pronouns,birthday,bio,
tiktok_username,instagram_username,goodreads_username,
youtube_url,twitter_username,linkedin_url
''';

class ProfileService {
  final ProfileRepository repo;
  ProfileService({required this.repo});

  SupabaseClient get _sb => repo.sb;

  String get _meId {
    final me = _sb.auth.currentUser;
    if (me == null) throw Exception("No estás logueado");
    return me.id;
  }

  String _generateFriendCode() {
    const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final r = Random.secure();

    final prefix = List.generate(3, (_) => letters[r.nextInt(letters.length)]).join();
    final suffix = List.generate(4, (_) => chars[r.nextInt(chars.length)]).join();
    return "$prefix-$suffix";
  }

  Future<UserProfile> ensureMyProfile({String displayName = ''}) async {
    final meId = _meId;

    final existing = await repo.fetchById(meId, select: _profileSelect);

    if (existing != null) {
      final p = UserProfile.fromMap(existing);

      // asegura friend_code
      if (p.friendCode.trim().isEmpty) {
        return _ensureFriendCodeForExisting(
          userId: meId,
          currentDisplayName: p.displayName,
          newDisplayName: displayName,
        );
      }

      return p;
    }

    // no existe -> crea con friend_code único
    for (int attempt = 0; attempt < 5; attempt++) {
      final code = _generateFriendCode();
      try {
        final inserted = await repo.insertProfile(
          userId: meId,
          values: {
            'display_name': displayName,
            'friend_code': code,
          },
          select: _profileSelect,
        );
        return UserProfile.fromMap(inserted);
      } catch (e) {
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
        final updated = await repo.updateById(
          userId: userId,
          patch: {
            'friend_code': code,
            'display_name': newDisplayName.isEmpty ? currentDisplayName : newDisplayName,
          },
          select: _profileSelect,
        );
        return UserProfile.fromMap(updated);
      } catch (e) {
        if (attempt == 4) rethrow;
      }
    }
    throw Exception("No se pudo asignar friend_code");
  }

  Future<UserProfile> getMyProfile() async {
    final meId = _meId;
    final row = await repo.fetchById(meId, select: _profileSelect);
    if (row == null) throw Exception("Perfil no existe");
    return UserProfile.fromMap(row);
  }

  Future<UserProfile> saveMyProfile(ProfileDraft draft) async {
    final meId = _meId;
    final updated = await repo.updateById(
      userId: meId,
      patch: draft.toUpdateMap(),
      select: _profileSelect,
    );
    return UserProfile.fromMap(updated);
  }

  Future<UserProfile?> findByFriendCode(String code) async {
    final normalized = code.trim().toUpperCase();
    final row = await repo.fetchByFriendCode(friendCode: normalized, select: _profileSelect);
    if (row == null) return null;
    return UserProfile.fromMap(row);
  }

  Future<UserProfile?> getByUserId(String userId) async {
    final row = await repo.fetchById(userId, select: _profileSelect);
    if (row == null) return null;
    return UserProfile.fromMap(row);
  }

  Future<Map<String, UserProfile>> getByUserIds(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    final rows = await repo.fetchByUserIds(userIds: userIds, select: _profileSelect);

    final map = <String, UserProfile>{};
    for (final r in rows) {
      final p = UserProfile.fromMap(r);
      map[p.id] = p;
    }
    return map;
  }
}
