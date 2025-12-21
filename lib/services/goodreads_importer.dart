import '../models/row_error.dart';

class ImportResult<T> {
  ImportResult({required this.items, required this.errors});
  final List<T> items;
  final List<RowError> errors;
}

class GoodreadsImporter {
  static const requiredColumns = [
    'book id',
    'title',
    'author',
    'isbn',
    'isbn13',
    'my rating',
    'average rating',
    'publisher',
    'binding',
    'number of pages',
    'year published',
    'original publication year',
    'date read',
    'date added',
    'bookshelves',
    'exclusive shelf',
    'my review',
    'spoiler',
    'private notes',
    'read count',
    'owned copies',
    'additional authors',
  ];

  ImportResult<Map<String, dynamic>> toPayload({
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) {
    final headerIndex = _buildHeaderIndex(headers);

    // Validación de columnas mínimas (al menos las críticas)
    for (final col in ['book id', 'title', 'author']) {
      if (!headerIndex.containsKey(col)) {
        return ImportResult(
          items: [],
          errors: [RowError(rowNumber: 0, message: "Falta la columna obligatoria: '$col'")],
        );
      }
    }

    final items = <Map<String, dynamic>>[];
    final errors = <RowError>[];

    final seenBookIds = <String>{};

    for (int i = 0; i < rows.length; i++) {
      final rowNumber = i + 2;
      final row = rows[i];

      try {
        final bookId = _getCell(row, headerIndex, 'book id');
        if (bookId.isEmpty) throw Exception('Book Id vacío');

        // Dedupe en el cliente: 1 por book_id
        if (seenBookIds.contains(bookId)) continue;
        seenBookIds.add(bookId);

        final title = _getCell(row, headerIndex, 'title');
        final authorMain = _getCell(row, headerIndex, 'author');
        if (title.isEmpty) throw Exception('Title vacío');
        if (authorMain.isEmpty) throw Exception('Author vacío');

        final isbn10 = _cleanExcelWrapped(_getCell(row, headerIndex, 'isbn'));
        final isbn13 = _cleanExcelWrapped(_getCell(row, headerIndex, 'isbn13'));

        final myRatingRaw = _getCell(row, headerIndex, 'my rating');
        final myRatingInt = int.tryParse(myRatingRaw);
        final myRating = (myRatingInt == null || myRatingInt == 0) ? '' : myRatingInt.toString();

        final avgRating = _getCell(row, headerIndex, 'average rating');

        final publisher = _getCell(row, headerIndex, 'publisher');
        final binding = _getCell(row, headerIndex, 'binding');
        final pages = _getCell(row, headerIndex, 'number of pages');
        final yearPublished = _getCell(row, headerIndex, 'year published');
        final originalYear = _getCell(row, headerIndex, 'original publication year');

        final dateRead = _toPgDate(_getCell(row, headerIndex, 'date read'));
        final dateAdded = _toPgDate(_getCell(row, headerIndex, 'date added'));

        final exclusiveShelf = _getCell(row, headerIndex, 'exclusive shelf');

        final bookshelvesRaw = _getCell(row, headerIndex, 'bookshelves');
        final shelves = _splitCommaList(bookshelvesRaw);

        // incluimos exclusiveShelf como shelf si no está
        final shelvesFinal = <String>[
          ...shelves,
          if (exclusiveShelf.isNotEmpty && !shelves.contains(exclusiveShelf)) exclusiveShelf,
        ];

        final additionalAuthorsRaw = _getCell(row, headerIndex, 'additional authors');
        final additionalAuthors = _splitCommaList(additionalAuthorsRaw);

        final authors = <String>[
          authorMain,
          ...additionalAuthors.where((a) => a.toLowerCase() != authorMain.toLowerCase()),
        ];

        final myReview = _getCell(row, headerIndex, 'my review');
        final spoiler = _getCell(row, headerIndex, 'spoiler');
        final privateNotes = _getCell(row, headerIndex, 'private notes');
        final readCount = _getCell(row, headerIndex, 'read count');
        final ownedCopies = _getCell(row, headerIndex, 'owned copies');

        items.add({
          // 👇 Estas keys son las que tu RPC import_goodreads(payload jsonb) espera
          'book_id': bookId,
          'title': title,
          'isbn10': isbn10,
          'isbn13': isbn13,
          'publisher': publisher,
          'binding': binding,
          'pages': pages,
          'year_published': yearPublished,
          'original_year': originalYear,
          'avg_rating': avgRating,

          'my_rating': myRating,
          'date_read': dateRead,
          'date_added': dateAdded,
          'exclusive_shelf': exclusiveShelf,
          'my_review': myReview,
          'spoiler': spoiler,
          'private_notes': privateNotes,
          'read_count': readCount,
          'owned_copies': ownedCopies,

          'authors': authors,
          'shelves': shelvesFinal,
        });
      } catch (e) {
        errors.add(RowError(rowNumber: rowNumber, message: e.toString()));
      }
    }

    return ImportResult(items: items, errors: errors);
  }

  Map<String, int> _buildHeaderIndex(List<String> headers) {
    final map = <String, int>{};
    for (int i = 0; i < headers.length; i++) {
      map[headers[i].trim().toLowerCase()] = i;
    }
    return map;
  }

  String _getCell(List<dynamic> row, Map<String, int> headerIndex, String colLower) {
    final idx = headerIndex[colLower];
    if (idx == null || idx >= row.length) return '';
    return row[idx]?.toString().trim() ?? '';
  }

  String _cleanExcelWrapped(String v) {
    var s = v.trim();
    if (s.startsWith('="') && s.endsWith('"')) {
      s = s.substring(2, s.length - 1);
    }
    if (s.startsWith('"') && s.endsWith('"') && s.length >= 2) {
      s = s.substring(1, s.length - 1);
    }
    return s.trim();
  }

  String _toPgDate(String goodreadsDate) {
    final t = goodreadsDate.trim();
    if (t.isEmpty) return '';
    final parts = t.split('/');
    if (parts.length == 3) {
      final y = parts[0].padLeft(4, '0');
      final m = parts[1].padLeft(2, '0');
      final d = parts[2].padLeft(2, '0');
      return '$y-$m-$d';
    }
    return '';
  }

  List<String> _splitCommaList(String s) =>
      s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}
