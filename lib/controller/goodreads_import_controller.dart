import 'dart:io';
import 'package:flutter/foundation.dart';

import '../models/row_error.dart';
import '../services/auth_service.dart';
import '../services/csv_reader.dart';
import '../services/goodreads_repository.dart';
import '../services/goodreads_importer.dart';

class GoodreadsImportController extends ChangeNotifier {
  GoodreadsImportController({
    required CsvReaderService csvReader,
    required AuthService auth,
    required GoodreadsRepository repo,
    required GoodreadsImporter importer,
  })  : _csvReader = csvReader,
        _auth = auth,
        _repo = repo,
        _importer = importer;

  final CsvReaderService _csvReader;
  final AuthService _auth;
  final GoodreadsRepository _repo;
  final GoodreadsImporter _importer;

  bool _loading = false;
  bool get loading => _loading;

  bool _saving = false;
  bool get saving => _saving;

  bool _showManualDelimiter = false;
  bool get showManualDelimiter => _showManualDelimiter;

  File? _file;
  File? get file => _file;

  String _delimiter = ',';
  String get delimiter => _delimiter;

  List<String> _headers = const [];
  List<String> get headers => _headers;

  List<List<dynamic>> _rows = const [];
  List<List<dynamic>> get rows => _rows;

  String? _error;
  String? get error => _error;

  List<Map<String, dynamic>> _payload = const [];
  List<Map<String, dynamic>> get payload => _payload;

  List<RowError> _importedErrors = const [];
  List<RowError> get importedErrors => _importedErrors;

  bool get hasPreview => _headers.isNotEmpty;
  bool get hasImported => _payload.isNotEmpty;

  void requestManualDelimiter() {
    _showManualDelimiter = true;
    notifyListeners();
  }

  void resetAll() {
    _file = null;
    _delimiter = ',';
    _headers = const [];
    _rows = const [];
    _error = null;
    _showManualDelimiter = false;

    _payload = const [];
    _importedErrors = const [];
    notifyListeners();
  }

  Future<void> pickAndAutoLoad() async {
    _loading = true;
    _error = null;
    _showManualDelimiter = false;

    _file = null;
    _delimiter = ',';
    _headers = const [];
    _rows = const [];

    _payload = const [];
    _importedErrors = const [];
    notifyListeners();

    try {
      final file = await _csvReader.pickCsvFile();
      if (file == null) return;

      final result = await _csvReader.readAndValidateCsv(
        file,
        required: GoodreadsImporter.requiredColumns,
        allowEmptyRows: false,
      );

      _file = result.file;
      _delimiter = result.delimiter;
      _headers = result.headers;
      _rows = result.rows;
      _error = result.validationError;

      if (result.isValid) {
        _convertRowsToPayload();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> reparseWithManualDelimiter(String? v) async {
    if (v == null || _file == null) return;

    _loading = true;
    _error = null;
    _delimiter = v;

    _headers = const [];
    _rows = const [];
    _payload = const [];
    _importedErrors = const [];
    notifyListeners();

    try {
      final res = await _csvReader.readCsv(_file!, delimiter: v);

      _headers = res.headers;
      _rows = res.rows;
      _error = res.validationError;

      if (res.isValid) {
        _convertRowsToPayload();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _convertRowsToPayload() {
    final res = _importer.toPayload(headers: _headers, rows: _rows);
    _payload = res.items;
    _importedErrors = res.errors;
  }

  /// Importa payload a Supabase. Devuelve true si ok (para que UI muestre snack).
  Future<bool> saveImported() async {
    if (_payload.isEmpty || _saving) return false;

    _saving = true;
    notifyListeners();

    try {
      await _repo.importGoodreadsPayload(_payload);
      return true;
    } catch (_) {
      rethrow;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
