import 'package:flutter/foundation.dart';
import '../models/my_library_item.dart';
import '../services/library_service.dart';

class MyLibraryController extends ChangeNotifier {
  MyLibraryController({required LibraryService service}) : _service = service;

  final LibraryService _service;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  List<MyLibraryItem> _items = const [];
  List<MyLibraryItem> get items => _items;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final items = await _service.fetchMine(limit: 1000);
      _items = items;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();
}
