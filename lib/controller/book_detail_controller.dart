import 'package:flutter/foundation.dart';
import 'package:rin/models/book_detail.dart';
import 'package:rin/services/library_service.dart';

// NUEVO
import 'package:rin/services/review_service.dart';
import 'package:rin/models/book_review.dart';
import 'package:rin/models/book_review_stats.dart';

class BookDetailController extends ChangeNotifier {
  BookDetailController({
    required LibraryService service,
    required ReviewService reviewService,
    required String catalogBookId,
  })  : _service = service,
        _reviewService = reviewService,
        _catalogBookId = catalogBookId;

  final LibraryService _service;
  final ReviewService _reviewService;
  final String _catalogBookId;

  bool loading = false;
  String? error;

  BookDetail? detail;
  BookDetail? get _detail => detail;
  String get catalogBookId => _catalogBookId;

  // ---- REVIEWS (estado) ----
  bool loadingReviews = false;
  String? reviewsError;
  List<BookReview> reviews = const [];
  BookReview? myPublicReview;
  BookReviewStats? reviewStats;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      var d = await _service.fetchBookDetail(catalogBookId: catalogBookId);
      detail = d;
      notifyListeners();

      // intentar arreglar cover (solo si hace falta)
      final fixed = await _service.ensureBookCover(detail: d);

      if (fixed) {
        // recargar detalle para ver cover actualizado
        d = await _service.fetchBookDetail(catalogBookId: catalogBookId);
        detail = d;
        notifyListeners();
      }

      // NUEVO: cargar reviews (en paralelo o después; aquí lo hacemos después para mantenerlo simple)
      await loadReviewsBlock();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Future<void> setShelf(String shelf) async {
    final d = _detail;
    if (d == null) return;

    await _service.upsertMyBook(
      catalogBookId: _catalogBookId,
      exclusiveShelf: shelf,
      myRating: d.myRating,
      dateRead: d.dateRead,
    );

    await load(); // recarga todo (incluye reviews)
  }

  Future<void> setRating(int rating) async {
    final d = _detail;
    if (d == null) return;

    await _service.upsertMyBook(
      catalogBookId: _catalogBookId,
      exclusiveShelf: d.exclusiveShelf,
      myRating: rating,
      dateRead: d.dateRead,
    );

    await load();
  }

  // ---------- REVIEWS API ----------
  Future<void> loadReviewsBlock() async {
    loadingReviews = true;
    reviewsError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _reviewService.listBookReviews(_catalogBookId),
        _reviewService.getMyReview(_catalogBookId),
        _reviewService.getStats(_catalogBookId),
      ]);

      reviews = results[0] as List<BookReview>;
      myPublicReview = results[1] as BookReview?;
      reviewStats = results[2] as BookReviewStats;

      loadingReviews = false;
      notifyListeners();
    } catch (e) {
      loadingReviews = false;
      reviewsError = e.toString();
      notifyListeners();
    }
  }

  Future<void> savePublicReview({
    required int rating,
    required String? body,
    required bool spoilers,
  }) async {
    await _reviewService.saveMyReview(
      bookId: _catalogBookId,
      rating: rating,
      body: body,
      containsSpoilers: spoilers,
    );
    await loadReviewsBlock();
  }

  Future<void> deletePublicReview() async {
    await _reviewService.deleteMyReview(_catalogBookId);
    await loadReviewsBlock();
  }

  Future<void> addToLibrary({String shelf = 'to-read'}) async {
  final d = detail;
  if (d == null) return;

  await _service.addToLibrary(
    catalogBookId: _catalogBookId,
    exclusiveShelf: shelf,
  );

  await load();
}

}
