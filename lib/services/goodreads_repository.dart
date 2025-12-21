import 'dart:async'; // 👈 importante para unawaited
import 'package:supabase_flutter/supabase_flutter.dart';

class GoodreadsRepository {
  SupabaseClient get _sb => Supabase.instance.client;

  Future<void> importGoodreadsPayload(
    List<Map<String, dynamic>> payload,
  ) async {
    final user = _sb.auth.currentUser;
    if (user == null) throw Exception("No estás logueado");
    if (payload.isEmpty) return;

    const chunkSize = 300;

    for (var i = 0; i < payload.length; i += chunkSize) {
      final chunk = payload.sublist(
        i,
        (i + chunkSize).clamp(0, payload.length),
      );

      await _sb.rpc('import_goodreads', params: {'payload': chunk});
    }

    // ✅ AUTO-HIDRATACIÓN (no bloquea la UI)
    unawaited(
      _sb.functions.invoke('hydrate_openlibrary', body: {'limit': 100}),
    );
  }
}
