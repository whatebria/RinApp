import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rin/screens/widgets/update_catalog_button.dart';

import '../services/auth_service.dart';
import '../services/csv_reader.dart';
import '../models/row_error.dart';
import '../services/goodreads_repository.dart';
import '../services/goodreads_importer.dart';

class GoodreadsImportScreen extends StatefulWidget {
  const GoodreadsImportScreen({super.key});

  @override
  State<GoodreadsImportScreen> createState() => _GoodreadsImportScreenState();
}

class _GoodreadsImportScreenState extends State<GoodreadsImportScreen> {
  final CsvReaderService _csvReader = CsvReaderService();
  final _auth = AuthService();

  final _repo = GoodreadsRepository();
  final _importer = GoodreadsImporter();

  bool _saving = false;

  File? _file;
  String _delimiter = ",";
  List<String> _headers = [];
  List<List<dynamic>> _rows = [];
  String? _error;

  List<Map<String, dynamic>> _payload = [];
  List<RowError> _importedErrors = [];

  bool _loading = false;
  bool _showManualDelimiter = false;

  @override
  Widget build(BuildContext context) {
    final hasPreview = _headers.isNotEmpty;
    final hasImported = _payload.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Importar Goodreads CSV"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar sesión",
            onPressed: _signOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            FilledButton.icon(
              onPressed: _loading ? null : _pickAndAutoLoad,
              icon: const Icon(Icons.upload_file),
              label: Text(_loading ? "Cargando..." : "Elegir CSV"),
            ),

            const SizedBox(height: 12),
            const UpdateCatalogButton(),

            const SizedBox(height: 12),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => setState(() => _showManualDelimiter = true),
                child: const Text("Elegir separador manualmente"),
              ),
            ],

            if (_showManualDelimiter && _file != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text("Separador manual: "),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _delimiter,
                    items: const [
                      DropdownMenuItem(value: ",", child: Text(",")),
                      DropdownMenuItem(value: ";", child: Text(";")),
                      DropdownMenuItem(value: "\t", child: Text("TAB")),
                    ],
                    onChanged: _loading
                        ? null
                        : (v) => _reparseWithManualDelimiter(v),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 6),

            if (hasPreview) ...[
              Text("Libros OK: ${_payload.length}"),
              Text("Errores: ${_importedErrors.length}"),
              if (_importedErrors.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text("Primeros errores:"),
                ..._importedErrors
                    .take(5)
                    .map((e) => Text("Fila ${e.rowNumber}: ${e.message}")),
              ],
            ],

            const SizedBox(height: 16),

            if (hasImported) ...[
              const Text(
                "Preview (primeros libros)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _previewList(),
            ],

            const SizedBox(height: 16),

            FilledButton(
              onPressed: (_saving || _payload.isEmpty) ? null : _saveImported,
              child: Text(_saving ? "Importando..." : "Importar libros"),
            ),

            const SizedBox(height: 24),

            if (_file != null) ...[
              OutlinedButton(
                onPressed: _loading ? null : _resetAll,
                child: const Text("Limpiar"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _previewList() {
    final first = _payload.take(20).toList();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: first.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = first[i];
        final title = (item['title'] ?? '').toString();
        final authors = (item['authors'] as List?)?.join(', ') ?? '';
        final shelf = (item['exclusive_shelf'] ?? '').toString();

        return ListTile(
          leading: const Icon(Icons.book_outlined),
          title: Text(title),
          subtitle: Text(authors.isEmpty ? shelf : "$authors • $shelf"),
        );
      },
    );
  }

  Future<void> _saveImported() async {
    if (_payload.isEmpty) return;

    setState(() => _saving = true);
    try {
      await _repo.importGoodreadsPayload(_payload);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Importado en Supabase")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error al importar: $e")));
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  Future<void> _pickAndAutoLoad() async {
    setState(() {
      _loading = true;
      _error = null;
      _showManualDelimiter = false;

      _file = null;
      _delimiter = ',';
      _headers = [];
      _rows = [];

      _payload = [];
      _importedErrors = [];
    });

    try {
      final file = await _csvReader.pickCsvFile();
      if (file == null) return;

      // ✅ IMPORTANT: required Goodreads
      final result = await _csvReader.readAndValidateCsv(
        file,
        required: GoodreadsImporter.requiredColumns,
        allowEmptyRows: false,
      );

      if (!mounted) return;

      setState(() {
        _file = result.file;
        _delimiter = result.delimiter;
        _headers = result.headers;
        _rows = result.rows;
        _error = result.validationError;
      });

      if (result.isValid) {
        _convertRowsToPayload();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _reparseWithManualDelimiter(String? v) async {
    if (v == null || _file == null) return;

    setState(() {
      _loading = true;
      _error = null;
      _delimiter = v;

      _headers = [];
      _rows = [];
      _payload = [];
      _importedErrors = [];
    });

    try {
      final res = await _csvReader.readCsv(_file!, delimiter: v);

      if (!mounted) return;

      setState(() {
        _headers = res.headers;
        _rows = res.rows;
        _error = res.validationError;
      });

      if (res.isValid) {
        _convertRowsToPayload();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _convertRowsToPayload() {
    final res = _importer.toPayload(headers: _headers, rows: _rows);
    setState(() {
      _payload = res.items;
      _importedErrors = res.errors;
    });
  }

  void _resetAll() {
    setState(() {
      _file = null;
      _delimiter = ',';
      _headers = [];
      _rows = [];
      _error = null;
      _showManualDelimiter = false;

      _payload = [];
      _importedErrors = [];
    });
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error al cerrar sesión: $e")));
    }
  }
}
