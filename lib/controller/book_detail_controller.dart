import 'package:flutter/foundation.dart';
import 'package:rin/models/book_detail.dart';
import 'package:rin/services/library_service.dart';

class BookDetailController extends ChangeNotifier {
  BookDetailController({
    required LibraryService service,
    required String catalogBookId,
  })  : _service = service,
        _catalogBookId = catalogBookId;

  final LibraryService _service;
  final String _catalogBookId;

  bool _loading = false;
  String? _error;
  BookDetail? _detail;

  bool get loading => _loading;
  String? get error => _error;
  BookDetail? get detail => _detail;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final d = await _service.fetchBookDetail(catalogBookId: _catalogBookId);
      _detail = d;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
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
