import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient sb;
  ProfileRepository(this.sb);

  Future<Map<String, dynamic>?> fetchById(String userId, {required String select}) async {
    return await sb
        .from('profiles')
        .select(select)
        .eq('id', userId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>> insertProfile({
    required String userId,
    required Map<String, dynamic> values,
    required String select,
  }) async {
    final inserted = await sb
        .from('profiles')
        .insert({'id': userId, ...values})
        .select(select)
        .single();

    return (inserted as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> updateById({
    required String userId,
    required Map<String, dynamic> patch,
    required String select,
  }) async {
    final updated = await sb
        .from('profiles')
        .update(patch)
        .eq('id', userId)
        .select(select)
        .single();

    return (updated as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>?> fetchByFriendCode({
    required String friendCode,
    required String select,
  }) async {
    return await sb
        .from('profiles')
        .select(select)
        .eq('friend_code', friendCode)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> fetchByUserIds({
    required List<String> userIds,
    required String select,
  }) async {
    final data = await sb.from('profiles').select(select).inFilter('id', userIds);
    return (data as List).cast<Map<String, dynamic>>();
  }
}
