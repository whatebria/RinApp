import 'package:flutter/foundation.dart';
import '../models/my_library_item.dart';
import '../services/library_service.dart';

class MyLibraryController extends ChangeNotifier {
  MyLibraryController({required LibraryService service}) : _service = service;
  final LibraryService _service;

  bool _loading = false;
  bool get loading => _loading;

  bool _hasLoaded = false;
  bool get hasLoaded => _hasLoaded;

  String? _error;
  String? get error => _error;

  List<MyLibraryItem> _items = const [];
  List<MyLibraryItem> get items => _items;

  Map<String, List<MyLibraryItem>> _itemsByShelf = const {};
  Map<String, List<MyLibraryItem>> get itemsByShelf => _itemsByShelf;

  static const String kNoShelfLabel = 'Sin estantería';

  Future<void> load() async {
    _loading = true;
    _error = null;

    // Opcional: evita “pantalla vacía” mostrando spinner en vez de vacío
    _items = const [];
    _itemsByShelf = const {};

    notifyListeners();

    try {
      final items = await _service.fetchMine(limit: 100);
      _items = items;
      _itemsByShelf = _buildItemsByShelf(items);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  int countForShelf(String shelf) => _itemsByShelf[shelf]?.length ?? 0;

  static Map<String, List<MyLibraryItem>> _buildItemsByShelf(
    List<MyLibraryItem> items,
  ) {
    final map = <String, List<MyLibraryItem>>{};
    for (final x in items) {
      final shelf = (x.exclusiveShelf?.trim().isNotEmpty ?? false)
          ? x.exclusiveShelf!.trim()
          : kNoShelfLabel;
      (map[shelf] ??= <MyLibraryItem>[]).add(x);
    }

    const preferred = ['to-read', 'reading', 'read'];
    final keys = map.keys.toList();

    int rank(String k) {
      if (k == kNoShelfLabel) return 9999;
      final idx = preferred.indexOf(k);
      return idx == -1 ? 100 : idx;
    }

    keys.sort((a, b) {
      final ra = rank(a), rb = rank(b);
      if (ra != rb) return ra.compareTo(rb);
      return a.toLowerCase().compareTo(b.toLowerCase());
    });

    return {for (final k in keys) k: map[k]!};
  }
}
