import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewRepository {
  final SupabaseClient sb;
  ReviewRepository(this.sb);

  Future<List<Map<String, dynamic>>> fetchByBook(String bookId, {int limit = 30}) async {
    final res = await sb
        .from('book_reviews')
        .select('id,catalog_book_id,user_id,rating,body,contains_spoilers,created_at,profiles(display_name,username,avatar_url)')
        .eq('catalog_book_id', bookId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> fetchMine(String bookId, String userId) async {
    final res = await sb
        .from('book_reviews')
        .select('id,catalog_book_id,user_id,rating,body,contains_spoilers,created_at,updated_at')
        .eq('catalog_book_id', bookId)
        .eq('user_id', userId)
        .maybeSingle();

    return (res as Map?)?.cast<String, dynamic>();
  }

  Future<void> upsert({
    required String bookId,
    required String userId,
    required int rating,
    required String? body,
    required bool containsSpoilers,
  }) async {
    await sb.from('book_reviews').upsert({
      'catalog_book_id': bookId,
      'user_id': userId,
      'rating': rating,
      'body': body,
      'contains_spoilers': containsSpoilers,
    });
  }

  Future<void> deleteMine(String bookId, String userId) async {
    await sb.from('book_reviews').delete()
      .eq('catalog_book_id', bookId)
      .eq('user_id', userId);
  }

  Future<dynamic> fetchStatsRpc(String bookId) async {
    return sb.rpc('get_book_review_stats', params: {'p_book_id': bookId});
  }
}
