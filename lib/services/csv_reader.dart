import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

class CsvReadResult {
  CsvReadResult({
    required this.file,
    required this.delimiter,
    required this.headers,
    required this.rows,
    required this.validationError,
  });

  final File file;
  final String delimiter;
  final List<String> headers;
  final List<List<dynamic>> rows;

  /// null = “CSV correcto”
  /// texto = “qué está mal”
  final String? validationError;

  bool get isValid => validationError == null;
}

class CsvReaderService {
  /// Columnas mínimas que tu app necesita para convertir a objetos
  static const List<String> requiredColumns = ["title", "start_time", "end_time"];

  Future<File?> pickCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (result == null || result.files.single.path == null) return null;
    return File(result.files.single.path!);
  }

  /// Lee y además valida.
  /// - Detecta separador
  /// - Si el separador falla, prueba otros
  /// - Devuelve headers+rows y un validationError si no cumple lo requerido
  Future<CsvReadResult> readAndValidateCsv(
    File file, {
    List<String> required = requiredColumns,
    bool allowEmptyRows = false,
  }) async {
    // 1) Elegimos candidatos de delimitador:
    //    - primero el detectado
    //    - luego fallback
    final detected = await detectDelimiter(file);
    final candidates = <String>{detected, ",", ";", "\t"}.toList();

    String? lastError;

    for (final d in candidates) {
      try {
        final parsed = await _readCsvRaw(file, delimiter: d);

        final validationError = validateCsv(
          headers: parsed.headers,
          rows: parsed.rows,
          required: required,
          allowEmptyRows: allowEmptyRows,
        );

        // Heurística: si la validación falla por "parece separador incorrecto",
        // seguimos probando otros delimitadores.
        if (validationError != null && _looksLikeWrongDelimiter(parsed.headers)) {
          lastError = validationError;
          continue;
        }

        // Si no parece separador incorrecto, devolvemos igual (válido o no),
        // porque quizá el separador era correcto y el problema es "faltan columnas", etc.
        return CsvReadResult(
          file: file,
          delimiter: d,
          headers: parsed.headers,
          rows: parsed.rows,
          validationError: validationError,
        );
      } catch (e) {
        lastError = e.toString();
      }
    }

    // Si ninguno funcionó, devolvemos con error.
    return CsvReadResult(
      file: file,
      delimiter: detected,
      headers: const [],
      rows: const [],
      validationError: lastError ?? "No se pudo leer el CSV.",
    );
  }

  /// Mantengo tu readCsv original por si en algún lugar lo usas aún,
  /// pero ahora lo hago depender del helper interno.
  Future<CsvReadResult> readCsv(File file, {String? delimiter}) async {
    final usedDelimiter = delimiter ?? await detectDelimiter(file);
    final parsed = await _readCsvRaw(file, delimiter: usedDelimiter);

    final validationError = validateCsv(
      headers: parsed.headers,
      rows: parsed.rows,
      required: requiredColumns,
      allowEmptyRows: false,
    );

    return CsvReadResult(
      file: file,
      delimiter: usedDelimiter,
      headers: parsed.headers,
      rows: parsed.rows,
      validationError: validationError,
    );
  }

  /// Lee CSV y retorna headers+rows SIN validación.
  Future<({List<String> headers, List<List<dynamic>> rows})> _readCsvRaw(
    File file, {
    required String delimiter,
  }) async {
    final text = await file.readAsString(encoding: utf8);

    final converter = CsvToListConverter(
      fieldDelimiter: delimiter,
      eol: '\n',
      shouldParseNumbers: false,
    );

    final parsed = converter.convert(text);

    if (parsed.isEmpty) {
      throw Exception('El archivo CSV está vacío o no se pudo parsear.');
    }

    final headers = parsed.first
    .map((e) => e.toString().replaceAll('\r', '').trim())
    .toList();

    final rows = parsed.skip(1).toList();

    return (headers: headers, rows: rows);
  }

  Future<String> detectDelimiter(File file) async {
    final sample = await file.openRead(0, 4096).transform(utf8.decoder).join();
    final commas = ",".allMatches(sample).length;
    final semis = ";".allMatches(sample).length;
    final tabs = "\t".allMatches(sample).length;

    if (tabs > commas && tabs > semis) return "\t";
    if (semis > commas) return ";";
    return ",";
  }

  /// Valida que el CSV sea utilizable para tu app.
  /// Devuelve null si OK.
  String? validateCsv({
    required List<String> headers,
    required List<List<dynamic>> rows,
    required List<String> required,
    required bool allowEmptyRows,
  }) {
    if (headers.isEmpty) return "No hay encabezados.";

    if (!allowEmptyRows && rows.isEmpty) {
      return "El CSV no tiene filas de datos.";
    }

    // Normalizamos headers: trim + lower para ser tolerantes a mayúsculas
    final normalized = headers.map((h) => h.trim().toLowerCase()).toList();

    for (final col in required) {
      if (!normalized.contains(col)) {
        return "Falta la columna obligatoria: '$col'. Columnas encontradas: ${headers.join(', ')}";
      }
    }

    return null; // ✅ correcto
  }

  /// Heurística: si los headers quedan en 1 sola columna con todo pegado,
  /// es muy típico de separador incorrecto.
  bool _looksLikeWrongDelimiter(List<String> headers) {
    if (headers.length != 1) return false;
    final h = headers.first;
    return h.contains(";") || h.contains(",") || h.contains("\t");
  }
}
