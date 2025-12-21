import 'package:supabase_flutter/supabase_flutter.dart';

class BookRemoteDatasource {
  BookRemoteDatasource(this._sb);
  final SupabaseClient _sb;

  Future<List<Map<String, dynamic>>> searchBooksRaw({
    required String query,
    int limit = 20,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final res = await _sb.functions.invoke(
      'book_search',
      body: {'q': q, 'limit': limit},
    );

    final data = res.data;
    if (data is! Map || data['items'] is! List) return [];

    return (data['items'] as List).cast<Map<String, dynamic>>();
  }
}
