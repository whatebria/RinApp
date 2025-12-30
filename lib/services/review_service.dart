import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rin/models/book_review.dart';
import 'package:rin/models/book_review_stats.dart';
import 'package:rin/data/repositories/review_repository.dart';

class ReviewService {
  final ReviewRepository repo;
  ReviewService({required this.repo});

  SupabaseClient get _sb => repo.sb;

  String get _meId {
    final me = _sb.auth.currentUser;
    if (me == null) throw Exception("No estás logueado");
    return me.id;
  }

  Future<List<BookReview>> listBookReviews(String bookId) async {
    final rows = await repo.fetchByBook(bookId);
    return rows.map(BookReview.fromMap).toList();
  }

  Future<BookReview?> getMyReview(String bookId) async {
    final m = await repo.fetchMine(bookId, _meId);
    if (m == null) return null;
    return BookReview.fromMap(m);
  }

  Future<BookReviewStats> getStats(String bookId) async {
    final data = await repo.fetchStatsRpc(bookId);
    return BookReviewStats.fromRpc(data);
  }

  Future<void> saveMyReview({
    required String bookId,
    int? rating,
    required String? body,
    required bool containsSpoilers,
  }) async {
    if (rating != null && (rating < 1 || rating > 5)) throw Exception("Rating inválido (1–5)");
    final trimmed = body?.trim();
    await repo.upsert(
      bookId: bookId,
      userId: _meId,
      rating: rating??0,
      body: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      containsSpoilers: containsSpoilers,
    );
  }

  Future<void> deleteMyReview(String bookId) async {
    await repo.deleteMine(bookId, _meId);
  }
}
