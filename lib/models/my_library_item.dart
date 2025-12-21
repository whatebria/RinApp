import 'package:rin/models/coverMeta.dart';

class MyLibraryItem {
  MyLibraryItem({
    required this.catalogBookId,
    required this.title,
    this.coverUrl,
    this.isbn10,
    this.isbn13,
    this.openLibraryCoverId,
    this.cover,
    this.pages,
    this.yearPublished,
    this.myRating,
    this.exclusiveShelf,
    this.dateAdded,
    this.dateRead,
  });

  final String catalogBookId;
  final String title;

  /// URL final (validada/persistida en catalog_books.cover_url)
  final String? coverUrl;

  /// Para buscar cover_id en OpenLibrary si falta
  final String? isbn10;
  final String? isbn13;

  /// Input para resolver L/M/S (catalog_books.openlibrary_cover_id)
  final String? openLibraryCoverId;

  /// Metadata validada (catalog_books.cover_*)
  final CoverMeta? cover;

  final int? pages;
  final int? yearPublished;

  final int? myRating;
  final String? exclusiveShelf;
  final DateTime? dateAdded;
  final DateTime? dateRead;

  /// Para UI: usa cover.url si existe, si no coverUrl (legacy)
  String? get bestCoverUrl => cover?.url ?? coverUrl;

  /// ISBN preferido (13 si está)
  String? get bestIsbn => (isbn13 != null && isbn13!.trim().isNotEmpty)
      ? isbn13!.trim()
      : (isbn10 != null && isbn10!.trim().isNotEmpty ? isbn10!.trim() : null);

  MyLibraryItem copyWith({
    String? coverUrl,
    String? openLibraryCoverId,
    CoverMeta? cover,
  }) {
    return MyLibraryItem(
      catalogBookId: catalogBookId,
      title: title,
      coverUrl: coverUrl ?? this.coverUrl,
      isbn10: isbn10,
      isbn13: isbn13,
      openLibraryCoverId: openLibraryCoverId ?? this.openLibraryCoverId,
      cover: cover ?? this.cover,
      pages: pages,
      yearPublished: yearPublished,
      myRating: myRating,
      exclusiveShelf: exclusiveShelf,
      dateAdded: dateAdded,
      dateRead: dateRead,
    );
  }

  factory MyLibraryItem.fromRow(Map<String, dynamic> row) {
    final book = (row['catalog_books'] as Map?) ?? {};

    String? s(dynamic v) {
      final t = v?.toString().trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    int? i(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    DateTime? dt(dynamic v) {
      final t = s(v);
      if (t == null) return null;
      return DateTime.tryParse(t);
    }

    final b = (book is Map<String, dynamic>) ? book : book.cast<String, dynamic>();

    final title = s(b['title']) ?? 'Sin título';

    // Construye CoverMeta desde las columnas cover_* si existen.
    final parsedCover = CoverMeta.fromDb(b);
    final coverMeta = parsedCover.isUsable ? parsedCover : null;

    return MyLibraryItem(
      catalogBookId: s(row['catalog_book_id']) ?? '',
      title: title,

      coverUrl: s(b['cover_url']),
      isbn10: s(b['isbn10']),
      isbn13: s(b['isbn13']),
      openLibraryCoverId: s(b['openlibrary_cover_id']),
      cover: coverMeta,

      pages: i(b['pages']),
      yearPublished: i(b['year_published']),
      myRating: i(row['my_rating']),
      exclusiveShelf: s(row['exclusive_shelf']),
      dateAdded: dt(row['date_added']),
      dateRead: dt(row['date_read']),
    );
  }
}
