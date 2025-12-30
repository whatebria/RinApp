import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rin/models/book_search_item.dart';
import 'package:rin/services/book_service.dart';

class BookSearchController extends ChangeNotifier {
  BookSearchController({
    required BookService service,
    this.debounceMs = 450,
  }) : _service = service;

  final BookService _service;
  final int debounceMs;

  final List<BookSearchItem> _items = [];
  List<BookSearchItem> get items => List.unmodifiable(_items);

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Timer? _debounce;
  String _query = '';
  String get query => _query;

  void setQuery(String v) {
    _query = v;
    // Debounce solo para UX: puede vivir acá sin problema.
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: debounceMs), () {
      final q = _query.trim();
      if (q.isEmpty) {
        clearResults();
      } else {
        search(q);
      }
    });
  }

  void clearResults() {
    _debounce?.cancel();
    _items.clear();
    _loading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> search(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      clearResults();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _service.search(query: query, limit: 20);
      _items
        ..clear()
        ..addAll(results);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Caso de uso: asegurar catalogId antes de ir a detalle
  Future<String> ensureCatalogId(BookSearchItem book) {
    return _service.ensureCatalogId(book: book);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
