import 'package:flutter/foundation.dart';
import 'package:rin/models/book_detail.dart';
import 'package:rin/services/library_service.dart';

class BookDetailController extends ChangeNotifier {
  BookDetailController({
    required LibraryService service,
    required String catalogBookId,
  }) : _service = service,
       _catalogBookId = catalogBookId;

  final LibraryService _service;
  final String _catalogBookId;

  bool loading = false;
  String? error;
  BookDetail? detail;
  BookDetail? get _detail => detail;
  String get catalogBookId => _catalogBookId;
  
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

    await load(); // el controller decide recargar
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
}
